import 'dart:typed_data';

import '../api/api_service.dart';
import '../models/geraet.dart';
import '../models/geraete_pruefung.dart';
import '../models/kunde.dart';
import '../models/messung.dart';
import '../models/pruefmatrix.dart';
import '../models/pruefprotokoll.dart';
import '../models/raum.dart';
import '../models/sichtpruefung.dart';
import '../models/standort.dart';
import '../models/verteiler.dart';
import '../models/verteiler_komponente.dart';
import '../providers/geraete_provider.dart';
import '../providers/komponenten_provider.dart';
import '../providers/kunden_provider.dart';
import '../providers/messungen_provider.dart';
import '../providers/pruefprotokoll_provider.dart';
import '../providers/sichtpruefung_provider.dart';
import '../providers/standorte_provider.dart';
import '../providers/verteiler_provider.dart';
import 'online_daten.dart';

// Online-Umsetzungen der Repositories für die Web-App: gleiche Regeln und
// Sortierung wie die lokalen, Daten je Ansicht direkt vom Server.

int _nachText<T>(String Function(T) f, T a, T b) => f(a).toLowerCase().compareTo(f(b).toLowerCase());

class OnlineKundenRepository implements KundenRepository {
  const OnlineKundenRepository(this._d);
  final OnlineDaten _d;

  Future<List<Kunde>> _alle() async =>
      [for (final j in await _d.liste('kunden')) Kunde.fromJson(j)]..sort((a, b) => a.name.compareTo(b.name));

  @override
  Stream<List<Kunde>> watchAll() => _d.beobachte({'kunden'}, _alle);
  @override
  Future<List<Kunde>> getAll() => _alle();
  @override
  Future<Kunde?> getByUuid(String uuid) async => switch (await _d.einzeln('kunden', uuid)) {
        final j? => Kunde.fromJson(j),
        null => null,
      };
  @override
  Future<void> save(Kunde kunde) => _d.speichern('kunden', kunde.toJson());
  @override
  Future<void> delete(String uuid) => _d.loeschen('kunden', uuid, '/kunden/$uuid');
}

class OnlineStandorteRepository implements StandorteRepository {
  const OnlineStandorteRepository(this._d);
  final OnlineDaten _d;

  Future<List<Standort>> _liste([Map<String, String> filter = const {}]) async =>
      [for (final j in await _d.liste('standorte', filter)) Standort.fromJson(j)]
        ..sort((a, b) => _nachText<Standort>((s) => s.bezeichnung, a, b));

  Stream<List<Standort>> watchAlle() => _d.beobachte({'standorte'}, _liste);
  @override
  Stream<List<Standort>> watchByKunde(String kundeUuid) =>
      _d.beobachte({'standorte'}, () => _liste({'kundeUuid': kundeUuid}));
  @override
  Future<List<Standort>> getByKunde(String kundeUuid) => _liste({'kundeUuid': kundeUuid});
  @override
  Future<Standort?> getByUuid(String uuid) async => switch (await _d.einzeln('standorte', uuid)) {
        final j? => Standort.fromJson(j),
        null => null,
      };
  @override
  Future<int> countByKunde(String kundeUuid) async => (await getByKunde(kundeUuid)).length;
  @override
  Future<void> save(Standort standort) => _d.speichern('standorte', standort.toJson());
  @override
  Future<void> delete(String uuid) => _d.loeschen('standorte', uuid, '/standorte/$uuid');
}

class OnlineVerteilerRepository implements VerteilerRepository {
  const OnlineVerteilerRepository(this._d);
  final OnlineDaten _d;

  Future<List<Verteiler>> _liste([Map<String, String> filter = const {}]) async =>
      [for (final j in await _d.liste('verteiler', filter)) Verteiler.fromJson(j)]
        ..sort((a, b) => _nachText<Verteiler>((v) => v.bezeichnung, a, b));

  Stream<List<Verteiler>> watchAlle() => _d.beobachte({'verteiler'}, _liste);
  @override
  Stream<List<Verteiler>> watchByStandort(String standortUuid) =>
      _d.beobachte({'verteiler'}, () => _liste({'standortUuid': standortUuid}));
  @override
  Future<List<Verteiler>> getByStandort(String standortUuid) => _liste({'standortUuid': standortUuid});
  @override
  Future<Verteiler?> getByUuid(String uuid) async => switch (await _d.einzeln('verteiler', uuid)) {
        final j? => Verteiler.fromJson(j),
        null => null,
      };
  @override
  Future<void> save(Verteiler verteiler) => _d.speichern('verteiler', verteiler.toJson());
  @override
  Future<void> delete(String uuid) => _d.loeschen('verteiler', uuid, '/verteiler/$uuid');
}

class OnlineKomponentenRepository implements KomponentenRepository {
  const OnlineKomponentenRepository(this._d);
  final OnlineDaten _d;

  Future<List<VerteilerKomponente>> _liste(String verteilerUuid) async =>
      [for (final j in await _d.liste('komponenten', {'verteilerUuid': verteilerUuid})) VerteilerKomponente.fromJson(j)]
        ..sort((a, b) => a.position.compareTo(b.position));

  @override
  Stream<List<VerteilerKomponente>> watchByVerteiler(String verteilerUuid) =>
      _d.beobachte({'komponenten'}, () => _liste(verteilerUuid));
  @override
  Future<List<VerteilerKomponente>> getByVerteiler(String verteilerUuid) => _liste(verteilerUuid);
  @override
  Future<VerteilerKomponente?> getByUuid(String uuid) async => switch (await _d.einzeln('komponenten', uuid)) {
        final j? => VerteilerKomponente.fromJson(j),
        null => null,
      };
  @override
  Future<void> save(VerteilerKomponente komponente) => _d.speichern('komponenten', komponente.toJson());
  @override
  Future<void> delete(String uuid) => _d.loeschen('komponenten', uuid, '/komponenten/$uuid');
}

class OnlineMessungenRepository implements MessungenRepository {
  const OnlineMessungenRepository(this._d);
  final OnlineDaten _d;

  Future<List<Messung>> _liste([Map<String, String> filter = const {}]) async =>
      [for (final j in await _d.liste('messungen', filter)) Messung.fromJson(j)]
        ..sort((a, b) => b.pruefungDatum.compareTo(a.pruefungDatum));

  Stream<List<Messung>> watchAlle() => _d.beobachte({'messungen'}, _liste);
  @override
  Stream<List<Messung>> watchByKomponente(String komponenteUuid) =>
      _d.beobachte({'messungen'}, () => _liste({'komponenteUuid': komponenteUuid}));
  @override
  Future<List<Messung>> getByKomponente(String komponenteUuid) => _liste({'komponenteUuid': komponenteUuid});
  @override
  Future<void> deleteByKomponente(String komponenteUuid) async {
    for (final m in await getByKomponente(komponenteUuid)) {
      await delete(m.uuid);
    }
  }

  @override
  Future<List<Messung>> getAll() => _liste();
  @override
  Future<Messung?> getByUuid(String uuid) async => switch (await _d.einzeln('messungen', uuid)) {
        final j? => Messung.fromJson(j),
        null => null,
      };
  @override
  Future<void> save(Messung messung) => _d.speichern('messungen', messung.toJson());
  @override
  Future<void> delete(String uuid) => _d.loeschen('messungen', uuid, '/daten/messungen/$uuid');
  @override
  Future<List<Messung>> getByKomponenteUuids(List<String> uuids) async =>
      uuids.isEmpty ? <Messung>[] : await _liste({'komponenteUuid': uuids.join(',')});
}

class OnlineSichtpruefungRepository implements SichtpruefungRepository {
  const OnlineSichtpruefungRepository(this._d);
  final OnlineDaten _d;

  Future<List<Sichtpruefung>> _liste(String verteilerUuid) async =>
      [for (final j in await _d.liste('sichtpruefungen', {'verteilerUuid': verteilerUuid})) Sichtpruefung.fromJson(j)]
        ..sort((a, b) => b.pruefungDatum.compareTo(a.pruefungDatum));

  @override
  Stream<List<Sichtpruefung>> watchByVerteiler(String verteilerUuid) =>
      _d.beobachte({'sichtpruefungen'}, () => _liste(verteilerUuid));
  @override
  Future<Sichtpruefung?> getLatestByVerteiler(String verteilerUuid) async => (await _liste(verteilerUuid)).firstOrNull;
  @override
  Future<void> save(Sichtpruefung sichtpruefung) => _d.speichern('sichtpruefungen', sichtpruefung.toJson());
}

class OnlineRaeumeRepository implements RaeumeRepository {
  const OnlineRaeumeRepository(this._d);
  final OnlineDaten _d;

  Future<List<Raum>> _liste([Map<String, String> filter = const {}]) async =>
      [for (final j in await _d.liste('raeume', filter)) Raum.fromJson(j)]
        ..sort((a, b) => _nachText<Raum>((r) => r.bezeichnung, a, b));

  Stream<List<Raum>> watchAlle() => _d.beobachte({'raeume'}, _liste);
  @override
  Stream<List<Raum>> watchByStandort(String standortUuid) =>
      _d.beobachte({'raeume'}, () => _liste({'standortUuid': standortUuid}));
  @override
  Future<List<Raum>> getByStandort(String standortUuid) => _liste({'standortUuid': standortUuid});
  @override
  Future<Raum?> getByUuid(String uuid) async => switch (await _d.einzeln('raeume', uuid)) {
        final j? => Raum.fromJson(j),
        null => null,
      };
  @override
  Future<void> save(Raum raum) {
    if (raum.bezeichnung.trim().isEmpty) throw ArgumentError('Bezeichnung fehlt');
    return _d.speichern('raeume', raum.toJson());
  }

  @override
  Future<bool> deleteWennLeer(String uuid) async {
    if ((await _d.liste('geraete', {'raumUuid': uuid})).isNotEmpty) return false;
    try {
      await _d.loeschen('raeume', uuid, '/raeume/$uuid');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 409) return false;
      rethrow;
    }
  }
}

class OnlineGeraeteRepository implements GeraeteRepository {
  const OnlineGeraeteRepository(this._d);
  final OnlineDaten _d;

  Future<List<Geraet>> _liste([Map<String, String> filter = const {}]) async =>
      [for (final j in await _d.liste('geraete', filter)) Geraet.fromJson(j)]
        ..sort((a, b) => _nachText<Geraet>((g) => g.bezeichnung, a, b));

  @override
  Stream<List<Geraet>> watchByStandort(String standortUuid) =>
      _d.beobachte({'geraete'}, () => _liste({'standortUuid': standortUuid}));
  @override
  Stream<List<Geraet>> watchByRaum(String raumUuid) => _d.beobachte({'geraete'}, () => _liste({'raumUuid': raumUuid}));
  @override
  Stream<List<Geraet>> watchAlle() => _d.beobachte({'geraete'}, _liste);
  @override
  Stream<Geraet?> watch(String uuid) => _d.beobachte({'geraete'}, () => getByUuid(uuid));
  @override
  Future<Geraet?> getByUuid(String uuid) async => switch (await _d.einzeln('geraete', uuid)) {
        final j? => Geraet.fromJson(j),
        null => null,
      };
  @override
  Future<List<Geraet>> getAlle() => _liste();
  @override
  Future<void> save(Geraet geraet) {
    final fehler = geraet.fehler;
    if (fehler.isNotEmpty) throw ArgumentError(fehler.join(', '));
    return _d.speichern('geraete', geraet.toJson());
  }

  @override
  Future<void> saveUmgehaengt(Geraet geraet) {
    final fehler = geraet.fehler;
    if (fehler.isNotEmpty) throw ArgumentError(fehler.join(', '));
    return _d.speichern('geraete', geraet.toJson(), zuordnungBestaetigt: true);
  }

  @override
  Future<void> delete(String uuid) => _d.loeschen('geraete', uuid, '/geraete/$uuid');
}

class OnlineGeraetePruefungenRepository implements GeraetePruefungenRepository {
  const OnlineGeraetePruefungenRepository(this._d);
  final OnlineDaten _d;

  Future<List<GeraetePruefung>> _liste([Map<String, String> filter = const {}]) async =>
      [for (final j in await _d.liste('geraetepruefungen', filter)) GeraetePruefung.fromJson(j)]..sort((a, b) {
          final d = b.pruefungDatum.compareTo(a.pruefungDatum);
          return d != 0 ? d : b.erstelltAm.compareTo(a.erstelltAm);
        });

  @override
  Stream<List<GeraetePruefung>> watchByGeraet(String geraetUuid) =>
      _d.beobachte({'geraetepruefungen'}, () => _liste({'geraetUuid': geraetUuid}));
  @override
  Stream<List<GeraetePruefung>> watchAlle() => _d.beobachte({'geraetepruefungen'}, _liste);
  @override
  Stream<GeraetePruefung?> watch(String uuid) => _d.beobachte({'geraetepruefungen'}, () => getByUuid(uuid));
  @override
  Future<GeraetePruefung?> getByUuid(String uuid) async => switch (await _d.einzeln('geraetepruefungen', uuid)) {
        final j? => GeraetePruefung.fromJson(j),
        null => null,
      };
  @override
  Future<List<GeraetePruefung>> getByGeraet(String geraetUuid) => _liste({'geraetUuid': geraetUuid});
  @override
  Future<List<GeraetePruefung>> getAlle() => _liste();

  /// Gleiche Regeln wie lokal; der Server prüft zusätzlich. Prüfen und
  /// Senden laufen zusammen nacheinander (Tippen in der Prüfmaske).
  @override
  Future<void> save(GeraetePruefung p) =>
      _d.nacheinander('geraetepruefungen:${p.uuid}', () => _pruefenUndSenden(p));

  Future<void> _pruefenUndSenden(GeraetePruefung p) async {
    final bisher = await getByUuid(p.uuid);
    if (bisher != null && bisher.abgeschlossen) {
      throw StateError('Abgeschlossene Prüfung ist unveränderlich — Korrektur als neue Prüfung anlegen');
    }
    if (bisher == null) {
      final geraet = await OnlineGeraeteRepository(_d).getByUuid(p.geraetUuid);
      if (geraet == null) throw StateError('Gerät unbekannt');
      if (!geraet.aktiv) throw StateError('Inaktives Gerät: keine neue Prüfung');
    }
    if (p.abgeschlossen && abschlussFehler(p).isNotEmpty) {
      throw StateError(abschlussFehler(p).join(', '));
    }
    await _d.senden('geraetepruefungen', p.toJson());
  }

  @override
  Future<void> entwurfVerwerfen(String uuid) async {
    final p = await getByUuid(uuid);
    if (p == null || p.abgeschlossen) return;
    await _d.loeschen('geraetepruefungen', uuid, '/daten/geraetepruefungen/$uuid');
  }
}

/// Prüfverlauf aus der Dokumentenablage (Bezug = Verteiler bzw. Standort,
/// Raum oder Gerät); nichts wird im Browser gespeichert.
class OnlinePruefprotokollRepository implements PruefprotokollRepository {
  const OnlinePruefprotokollRepository(this._d, {this.laden = _laden});
  final OnlineDaten _d;

  /// `GET /api/protokolle[?bezug=…]` — in Tests ersetzbar.
  final Future<List<dynamic>> Function(String? bezug) laden;

  static Future<List<dynamic>> _laden(String? bezug) async =>
      await ApiService.onlineGet('/protokolle', {if (bezug != null) 'bezug': bezug}) as List;

  static Pruefprotokoll _protokoll(Map m) => Pruefprotokoll(
        uuid: m['id'] as String,
        verteilerUuid: m['bezugUuid'] as String? ?? '',
        art: m['art'] as String? ?? 'anlage',
        protokollDatum: DateTime.parse(m['protokollDatum'] as String),
        prueferName: m['prueferName'] as String?,
        verteilerBezeichnung: m['verteilerBezeichnung'] as String?,
        standortBezeichnung: m['standortBezeichnung'] as String?,
        kundenBezeichnung: m['kundenBezeichnung'] as String?,
        backendUuid: m['id'] as String,
        erstelltAm: DateTime.tryParse(m['erstelltAm'] as String? ?? ''),
      );

  Future<List<Pruefprotokoll>> _liste(String? bezug) async =>
      [for (final m in await laden(bezug)) _protokoll(m as Map)]..sort((a, b) => b.protokollDatum.compareTo(a.protokollDatum));

  Stream<List<Pruefprotokoll>> watchAlle() => _d.beobachte({'protokolle'}, () => _liste(null));
  @override
  Stream<List<Pruefprotokoll>> watchByVerteiler(String verteilerUuid) =>
      _d.beobachte({'protokolle'}, () => _liste(verteilerUuid));
  @override
  Future<List<Pruefprotokoll>> getByVerteiler(String verteilerUuid) => _liste(verteilerUuid);
  @override
  Future<Pruefprotokoll?> latestByVerteiler(String verteilerUuid) async => (await _liste(verteilerUuid)).firstOrNull;

  /// Nichts lokal — abgelegt wird über [ablegen].
  @override
  Future<void> save(Pruefprotokoll p) async {}
  @override
  Future<List<Pruefprotokoll>> getAusstehende() async => const [];

  @override
  Future<ProtokollAblage> ablegen(Pruefprotokoll p, Uint8List bytes, {ProtokollUpload? upload}) async {
    final id = await (upload ?? protokollHochladen)(p, bytes);
    if (id == null) throw OnlineSpeicherFehler('Upload in die Dokumentenablage fehlgeschlagen');
    _d.geaendert('protokolle');
    final abgelegt = p.mitBackendUuid(id).ohnePdf();
    return (lokal: abgelegt, upload: Future.value(abgelegt));
  }
}
