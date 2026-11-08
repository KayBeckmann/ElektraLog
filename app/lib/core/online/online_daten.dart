import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../providers/app_mode_provider.dart';

/// Verbindung der Online-Datenschicht zum Server; in Tests ersetzbar.
abstract class OnlineTransport {
  /// JSON-Antwort; wirft [ApiException] (z. B. 404) bei Fehlern.
  Future<dynamic> get(String pfad, [Map<String, String>? query]);
  Future<Map<String, dynamic>> sync(List<Map<String, dynamic>> batches);
  Future<void> delete(String pfad);
}

class ApiOnlineTransport implements OnlineTransport {
  const ApiOnlineTransport();

  @override
  Future<dynamic> get(String pfad, [Map<String, String>? query]) => ApiService.onlineGet(pfad, query);

  @override
  Future<Map<String, dynamic>> sync(List<Map<String, dynamic>> batches) => ApiService.syncAll(batches);

  @override
  Future<void> delete(String pfad) => ApiService.onlineDelete(pfad);
}

/// Der Server hat den Datensatz nicht übernommen (gleichzeitige Änderung
/// durch jemand anderen oder Regelverstoß). Text ist für den Nutzer.
class OnlineSpeicherFehler implements Exception {
  OnlineSpeicherFehler(this.meldung);
  final String meldung;
  @override
  String toString() => meldung;
}

/// Online-Datenschicht der Web-App (Kay, 2026-11-08): keine lokale Kopie,
/// jede Ansicht fragt genau ihre Daten beim Server ab. Schreiben läuft
/// versioniert über `POST /api/sync` — dieselben Konfliktregeln wie beim
/// Sync der Endgeräte, nichts wird still überschrieben.
///
/// Ansichten werden neu geladen, sobald sich ihr Datentyp in dieser Sitzung
/// ändert, und regelmäßig ([abfrageIntervall]) für Änderungen anderer.
class OnlineDaten {
  OnlineDaten(this.transport, {this.abfrageIntervall = const Duration(seconds: 60)}) {
    _takt = Timer.periodic(abfrageIntervall, (_) => _geaendert.add(null));
  }

  final OnlineTransport transport;
  final Duration abfrageIntervall;

  /// Zuletzt gelesene Serverversion je `typ:uuid` — Basis beim Speichern.
  final _versionen = <String, int>{};

  /// Geänderter Datentyp; `null` = alles neu laden (Takt, Löschen).
  final _geaendert = StreamController<String?>.broadcast();
  late final Timer _takt;

  /// Meldungen für den Nutzer (z. B. abgelehntes Speichern); AppScaffold
  /// zeigt sie an, auch wenn der Aufrufer den Fehler nicht selbst behandelt.
  final _meldungen = StreamController<String>.broadcast();
  Stream<String> get meldungen => _meldungen.stream;

  void dispose() {
    _takt.cancel();
    _geaendert.close();
    _meldungen.close();
  }

  Map<String, dynamic> _merken(String typ, Map raw) {
    final json = raw.cast<String, dynamic>();
    final version = json.remove('version');
    if (version is num) _versionen['$typ:${json['uuid']}'] = version.toInt();
    return json;
  }

  /// Datensätze eines Typs, optional gefiltert (z. B. `{'raumUuid': id}`).
  Future<List<Map<String, dynamic>>> liste(String typ, [Map<String, String> filter = const {}]) async {
    final daten = await transport.get('/daten/$typ', filter) as List;
    return [for (final d in daten) _merken(typ, d as Map)];
  }

  /// Ein Datensatz oder `null`, wenn es ihn nicht (mehr) gibt.
  Future<Map<String, dynamic>?> einzeln(String typ, String uuid) async {
    try {
      return _merken(typ, await transport.get('/daten/$typ/$uuid') as Map);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Lädt sofort und erneut bei Änderungen an [typen] oder im Takt.
  Stream<T> beobachte<T>(Set<String> typen, Future<T> Function() laden) {
    late StreamController<T> c;
    StreamSubscription<String?>? sub;
    var laeuft = false;
    var nochmal = false;
    Future<void> neu() async {
      if (laeuft) {
        nochmal = true;
        return;
      }
      laeuft = true;
      try {
        do {
          nochmal = false;
          final wert = await laden();
          if (!c.isClosed) c.add(wert);
        } while (nochmal);
      } catch (e, st) {
        if (!c.isClosed) c.addError(e, st);
      } finally {
        laeuft = false;
      }
    }

    c = StreamController<T>(
      onListen: () {
        neu();
        sub = _geaendert.stream.where((t) => t == null || typen.contains(t)).listen((_) => neu());
      },
      onCancel: () {
        sub?.cancel();
        c.close();
      },
    );
    return c.stream;
  }

  /// Wartende Aufgabe je Schlüssel (`typ:uuid`) — schnelle Folgeänderungen
  /// (Tippen in der Prüfmaske) laufen nacheinander, und nur die jeweils
  /// neueste wartende wird ausgeführt; so überholen sich Fassungen nicht
  /// und melden sich nicht gegenseitig als Konflikt.
  final _wartend = <String, ({Future<void> Function() aufgabe, Completer<void> fertig})>{};
  final _laeuftGerade = <String>{};

  /// Führt [aufgabe] für [key] nach allen vorherigen aus; ältere, noch
  /// wartende Aufgaben desselben Schlüssels entfallen (ihre Aufrufer
  /// erhalten das Ergebnis der neueren).
  Future<void> nacheinander(String key, Future<void> Function() aufgabe) {
    final vorher = _wartend[key];
    final fertig = Completer<void>();
    _wartend[key] = (aufgabe: aufgabe, fertig: fertig);
    if (vorher != null) fertig.future.then(vorher.fertig.complete, onError: vorher.fertig.completeError);
    if (_laeuftGerade.add(key)) _abarbeiten(key);
    return fertig.future;
  }

  Future<void> _abarbeiten(String key) async {
    try {
      for (var w = _wartend.remove(key); w != null; w = _wartend.remove(key)) {
        try {
          await w.aufgabe();
          w.fertig.complete();
        } catch (e, st) {
          if (e is OnlineSpeicherFehler && !_meldungen.isClosed) _meldungen.add(e.meldung);
          w.fertig.completeError(e, st);
        }
      }
    } finally {
      _laeuftGerade.remove(key);
    }
  }

  /// Speichert einen Datensatz (anlegen oder ändern) auf dem Server.
  /// Wirft [OnlineSpeicherFehler], wenn der Server ihn nicht übernimmt.
  Future<void> speichern(String typ, Map<String, dynamic> json, {bool zuordnungBestaetigt = false}) =>
      nacheinander('$typ:${json['uuid']}', () => senden(typ, json, zuordnungBestaetigt: zuordnungBestaetigt));

  /// Sendet sofort — nur innerhalb von [nacheinander] verwenden.
  Future<void> senden(String typ, Map<String, dynamic> json, {bool zuordnungBestaetigt = false}) async {
    final uuid = json['uuid'] as String;
    final key = '$typ:$uuid';
    final antwort = await transport.sync([
      {
        'type': typ,
        'items': [
          {
            ...json,
            '_basisVersion': _versionen[key],
            if (zuordnungBestaetigt) '_zuordnungBestaetigt': true,
          },
        ],
      },
    ]);
    for (final e in (antwort['ergebnisse'] as List? ?? const []).cast<Map>()) {
      if (e['uuid'] == uuid) _versionen[key] = (e['version'] as num).toInt();
    }
    final abgelehnt = (antwort['abgelehnt'] as List? ?? const []).cast<Map>();
    final konflikte = (antwort['konflikte'] as List? ?? const []).cast<Map>();
    if (!_geaendert.isClosed) _geaendert.add(typ);
    if (abgelehnt.isNotEmpty) {
      throw OnlineSpeicherFehler('Nicht gespeichert: ${abgelehnt.first['grund'] ?? 'vom Server abgelehnt'}');
    }
    if (konflikte.isNotEmpty) {
      final art = konflikte.first['art'];
      throw OnlineSpeicherFehler(art == 'zuordnung'
          ? 'Nicht gespeichert: Der Ortswechsel muss bestätigt werden.'
          : 'Nicht gespeichert: Der Datensatz wurde inzwischen von jemand anderem geändert. '
              'Die Ansicht zeigt jetzt den aktuellen Stand — bitte die Änderung erneut eingeben.');
    }
  }

  /// Löscht über [pfad] (z. B. `/geraete/<uuid>`); alle Ansichten laden neu.
  Future<void> loeschen(String typ, String uuid, String pfad) async {
    try {
      await transport.delete(pfad);
    } on ApiException catch (e) {
      if (!_meldungen.isClosed) _meldungen.add('Nicht gelöscht: ${e.message}');
      rethrow;
    }
    _versionen.remove('$typ:$uuid');
    _geaendert.add(null);
  }

  /// Ansichten eines Typs neu laden (z. B. nach Protokoll-Upload).
  void geaendert(String typ) {
    if (!_geaendert.isClosed) _geaendert.add(typ);
  }
}

/// Online-Datenschicht, wenn die Web-App angemeldet ist — sonst `null`
/// (Endgeräte und Solo-Modus arbeiten mit der lokalen Datenbank).
final onlineDatenProvider = Provider<OnlineDaten?>((ref) {
  if (!kIsWeb) return null;
  if (ref.watch(appModusProvider).valueOrNull != AppModus.company) return null;
  final daten = OnlineDaten(const ApiOnlineTransport());
  ref.onDispose(daten.dispose);
  return daten;
});

/// Meldungen der Online-Datenschicht für die Anzeige (AppScaffold).
final onlineMeldungenProvider = StreamProvider<String>(
  (ref) => ref.watch(onlineDatenProvider)?.meldungen ?? const Stream.empty(),
);
