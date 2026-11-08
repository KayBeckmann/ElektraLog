import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../database/isar_service.dart';
import '../models/geraet.dart';
import '../models/geraete_pruefung.dart';
import '../models/kunde.dart';
import '../models/messung.dart';
import '../models/raum.dart';
import '../models/sichtpruefung.dart';
import '../models/standort.dart';
import '../models/verteiler.dart';
import '../models/verteiler_komponente.dart';
import '../providers/sync_auswahl_provider.dart';
import 'sync_bereiche.dart';
import 'sync_meta.dart';
import 'sync_revision.dart';

/// Ein synchronisierter Datensatztyp der App. [normalisiere] läuft immer
/// über das Modell, damit lokale und Serverfassung dasselbe Format haben.
class SyncTypDef {
  const SyncTypDef(this.name, this.store, this.normalisiere);

  final String name;
  final StoreRef<String, Map<String, Object?>> store;
  final Map<String, dynamic> Function(Map<String, dynamic> json) normalisiere;
}

/// Reihenfolge = Push-Reihenfolge (Eltern vor Kindern).
final syncTypDefs = <SyncTypDef>[
  SyncTypDef('kunden', StorageService.kundenStore, (j) => Kunde.fromJson(j).toJson()),
  SyncTypDef('standorte', StorageService.standorteStore, (j) => Standort.fromJson(j).toJson()),
  SyncTypDef('verteiler', StorageService.verteilerStore, (j) => Verteiler.fromJson(j).toJson()),
  SyncTypDef('komponenten', StorageService.komponentenStore, (j) => VerteilerKomponente.fromJson(j).toJson()),
  SyncTypDef('messungen', StorageService.messungenStore, (j) => Messung.fromJson(j).toJson()),
  SyncTypDef('sichtpruefungen', StorageService.sichtpruefungStore, (j) => Sichtpruefung.fromJson(j).toJson()),
  SyncTypDef('raeume', StorageService.raeumeStore, (j) => Raum.fromJson(j).toJson()),
  SyncTypDef('geraete', StorageService.geraeteStore, (j) => Geraet.fromJson(j).toJson()),
  SyncTypDef(
    'geraetepruefungen',
    StorageService.geraetepruefungenStore,
    (j) => GeraetePruefung.fromJson(j).toJson(),
  ),
];

SyncTypDef? syncTypDef(String name) => syncTypDefs.where((t) => t.name == name).firstOrNull;

/// Verbindung zum Server, in Tests ersetzbar.
abstract class SyncTransport {
  Future<Map<String, dynamic>> pull(Map<String, String> query);
  Future<Map<String, dynamic>> push(List<Map<String, dynamic>> batches);
}

class ApiSyncTransport implements SyncTransport {
  const ApiSyncTransport();

  @override
  Future<Map<String, dynamic>> pull(Map<String, String> query) => ApiService.pullAllQuery(query);

  @override
  Future<Map<String, dynamic>> push(List<Map<String, dynamic>> batches) => ApiService.syncAll(batches);
}

/// Wo die zuletzt gesehene Server-Revision liegt (M9.1), in Tests ersetzbar.
abstract class RevisionSpeicher {
  Future<int?> lesen(String key);
  Future<void> schreiben(String key, int wert);
}

class PrefsRevisionSpeicher implements RevisionSpeicher {
  const PrefsRevisionSpeicher();

  @override
  Future<int?> lesen(String key) async => (await SharedPreferences.getInstance()).getInt(key);

  @override
  Future<void> schreiben(String key, int wert) async => (await SharedPreferences.getInstance()).setInt(key, wert);
}

class PushErgebnis {
  const PushErgebnis({required this.gesendet, required this.konflikte, required this.abgelehnt});
  final int gesendet;
  final int konflikte;
  final int abgelehnt;
}

/// Versionierter Sync (Roadmap Geräteprüfung M3), siehe Server-`SyncEngine`.
///
/// - Push schickt nur lokal geänderte Datensätze (Inhalt ≠ zuletzt
///   synchronisierter Stand) mit ihrer Basisversion.
/// - Pull überschreibt nur unveränderte lokale Datensätze. Ist ein lokal
///   geänderter Datensatz auf dem Server inzwischen neuer, entsteht ein
///   Konflikt für den Nutzer — außer beide Fassungen sind inhaltlich gleich.
/// - Datensätze mit offenem Konflikt werden weder gesendet noch
///   überschrieben, bis der Nutzer sie zusammengeführt hat.
class SyncEngine {
  SyncEngine(
    this.db, {
    this.transport = const ApiSyncTransport(),
    this.revision = const PrefsRevisionSpeicher(),
    this.vollstaendig = false,
  })  : meta = SyncMetaRepository(db),
        konflikte = SyncKonfliktRepository(db);

  final Database db;
  final SyncTransport transport;
  final RevisionSpeicher revision;

  /// Alles laden, ohne Auswahl und ohne Entfernen — für die Web-App
  /// (Büro, immer online), die den ganzen Firmenbestand zeigen soll.
  final bool vollstaendig;
  final SyncMetaRepository meta;
  final SyncKonfliktRepository konflikte;

  static const revisionKey = 'sync_last_known_revision';
  static const _rollbackKey = 'sync_rollback_neu_gesendet_fuer';

  Future<PushErgebnis> push() async {
    final metas = await meta.alle();
    final offen = await konflikte.schluessel();
    final gesendet = <String, String>{}; // Schlüssel → Hash des gesendeten Inhalts
    final batches = <Map<String, dynamic>>[];

    for (final typ in syncTypDefs) {
      final items = <Map<String, dynamic>>[];
      for (final snap in await typ.store.find(db)) {
        final json = typ.normalisiere(snap.value.cast<String, dynamic>());
        final key = syncSchluessel(typ.name, snap.key);
        if (offen.contains(key)) continue;
        final m = metas[key];
        final hash = inhaltsHash(json);
        if (m != null && m.hash == hash && !m.zuordnungBestaetigt) continue;
        gesendet[key] = hash;
        items.add({
          ...json,
          '_basisVersion': m?.version,
          if (m?.zuordnungBestaetigt ?? false) '_zuordnungBestaetigt': true,
        });
      }
      if (items.isNotEmpty) batches.add({'type': typ.name, 'items': items});
    }
    if (batches.isEmpty) return const PushErgebnis(gesendet: 0, konflikte: 0, abgelehnt: 0);

    // Wo hier gearbeitet wurde, bleibt der Bereich für den Download ausgewählt.
    await bereicheAuswaehlen(db, [
      for (final b in batches)
        for (final item in b['items'] as List<Map<String, dynamic>>) (b['type'] as String, item.cast<String, Object?>()),
    ]);

    final antwort = await transport.push(batches);
    for (final e in (antwort['ergebnisse'] as List? ?? const []).cast<Map>()) {
      final key = syncSchluessel(e['type'] as String, e['uuid'] as String);
      final hash = gesendet[key];
      if (hash == null) continue;
      await meta.set(e['type'] as String, e['uuid'] as String, SyncMeta(version: (e['version'] as num).toInt(), hash: hash));
    }
    var offeneKonflikte = 0;
    for (final k in (antwort['konflikte'] as List? ?? const []).cast<Map>()) {
      if (await _konfliktAufnehmen(
        k['type'] as String,
        k['uuid'] as String,
        art: k['art'] as String? ?? 'konflikt',
        server: (k['server'] as Map).cast<String, dynamic>(),
        serverVersion: (k['version'] as num).toInt(),
      )) {
        offeneKonflikte++;
      }
    }
    final abgelehnt = (antwort['abgelehnt'] as List? ?? const []).cast<Map>();
    for (final a in abgelehnt) {
      final typ = syncTypDef(a['type'] as String);
      final lokal = typ == null ? null : await typ.store.record(a['uuid'] as String).get(db);
      if (typ == null || lokal == null) continue;
      await konflikte.put(SyncKonflikt(
        typ: typ.name,
        uuid: a['uuid'] as String,
        art: 'abgelehnt',
        lokal: typ.normalisiere(lokal.cast<String, dynamic>()),
        grund: a['grund'] as String?,
        erkanntAm: DateTime.now().toUtc(),
      ));
    }
    return PushErgebnis(gesendet: gesendet.length, konflikte: offeneKonflikte, abgelehnt: abgelehnt.length);
  }

  /// Gibt `true` zurück, wenn ein Server-Restore erkannt und der Merge
  /// deshalb übersprungen wurde (M9.1).
  Future<bool> pull() async {
    final auswahl = SyncAuswahlRepository(db);
    String liste(Set<String> s) => s.join(',');
    final data = await transport.pull(vollstaendig ? const {} : {
      'kunden': liste(await auswahl.getAktivierteKundeUuids()),
      'standorte': liste(await auswahl.getAktivierteStandortUuids()),
      'verteiler': liste(await auswahl.getAktivierteVerteilerUuids()),
      'geraeteStandorte': liste(await auswahl.getAktivierteGeraeteStandortUuids()),
      'raeume': liste(await auswahl.getAktivierteRaumUuids()),
    });

    final serverRevision = data['syncRevision'] as int?;
    if (serverRevision != null) {
      final lastKnown = await revision.lesen(revisionKey);
      final check = evaluateSyncRevision(lastKnown: lastKnown, serverRevision: serverRevision);
      if (check == RevisionCheck.rollbackDetected) {
        debugPrint('Sync-Rollback erkannt: Server-Revision $serverRevision < zuletzt bekannt $lastKnown '
            '— Pull-Merge übersprungen, lokale Daten werden erneut gesendet.');
        if (await revision.lesen(_rollbackKey) != lastKnown) {
          await meta.allesAlsUngesendetMarkieren();
          await revision.schreiben(_rollbackKey, lastKnown!);
        }
        return true;
      }
      // Baseline nur bei nicht-erkanntem Rollback fortschreiben, damit
      // ein erkannter Rollback bei jedem weiteren Sync erneut geprüft wird.
      await revision.schreiben(revisionKey, serverRevision);
    }

    final offen = await konflikte.schluessel();
    for (final typ in syncTypDefs) {
      for (final raw in (data[typ.name] as List? ?? const []).cast<Map>()) {
        final item = raw.cast<String, dynamic>();
        final version = (item['version'] as num?)?.toInt();
        final json = typ.normalisiere(item);
        final uuid = json['uuid'] as String;
        await _uebernehmen(typ, uuid, json, version, offen.contains(syncSchluessel(typ.name, uuid)));
      }
    }
    if (!vollstaendig) await abgewaehltesEntfernen(db);
    return false;
  }

  Future<void> _uebernehmen(SyncTypDef typ, String uuid, Map<String, dynamic> server, int? version, bool hatKonflikt) async {
    final record = typ.store.record(uuid);
    if (version == null) {
      // Server ohne Versionen (älterer Stand): Server hat Vorrang wie früher.
      await record.put(db, server.cast<String, Object?>());
      return;
    }
    if (hatKonflikt) {
      final k = await konflikte.get(typ.name, uuid);
      if (k != null && k.art != 'abgelehnt' && (k.serverVersion ?? 0) < version) {
        await konflikte.put(SyncKonflikt(
          typ: k.typ,
          uuid: k.uuid,
          art: k.art,
          lokal: k.lokal,
          server: server,
          serverVersion: version,
          erkanntAm: k.erkanntAm,
        ));
      }
      return;
    }
    final lokalRaw = await record.get(db);
    final m = await meta.get(typ.name, uuid);
    Future<void> uebernehmen() async {
      await record.put(db, server.cast<String, Object?>());
      await meta.set(typ.name, uuid, SyncMeta(version: version, hash: inhaltsHash(server)));
    }

    if (lokalRaw == null) return uebernehmen();
    final lokal = typ.normalisiere(lokalRaw.cast<String, dynamic>());
    final geaendert = m == null || m.hash != inhaltsHash(lokal) || m.zuordnungBestaetigt;
    if (!geaendert) return uebernehmen();
    if (m != null && m.version == version) return; // lokale Änderung wartet auf den Push
    if (gleicherInhalt(lokal, server)) return uebernehmen();
    await konflikte.put(SyncKonflikt(
      typ: typ.name,
      uuid: uuid,
      art: 'konflikt',
      lokal: lokal,
      server: server,
      serverVersion: version,
      erkanntAm: DateTime.now().toUtc(),
    ));
  }

  /// `true`, wenn der Nutzer entscheiden muss; inhaltsgleiche Fassungen
  /// werden still übernommen.
  Future<bool> _konfliktAufnehmen(
    String typName,
    String uuid, {
    required String art,
    required Map<String, dynamic> server,
    required int serverVersion,
  }) async {
    final typ = syncTypDef(typName);
    if (typ == null) return false;
    final serverJson = typ.normalisiere(server);
    final lokalRaw = await typ.store.record(uuid).get(db);
    final lokal = lokalRaw == null ? null : typ.normalisiere(lokalRaw.cast<String, dynamic>());
    if (lokal == null || (art == 'konflikt' && gleicherInhalt(lokal, serverJson))) {
      // Nichts zusammenzuführen (z. B. erster Sync nach dem Update).
      await typ.store.record(uuid).put(db, serverJson.cast<String, Object?>());
      await meta.set(typName, uuid, SyncMeta(version: serverVersion, hash: inhaltsHash(serverJson)));
      return false;
    }
    await konflikte.put(SyncKonflikt(
      typ: typName,
      uuid: uuid,
      art: art,
      lokal: lokal,
      server: serverJson,
      serverVersion: serverVersion,
      erkanntAm: DateTime.now().toUtc(),
    ));
    return true;
  }

  /// Nutzerentscheidung: [ergebnis] ist der zusammengeführte Datensatz.
  /// Er beruht danach auf der Serverversion des Konflikts und wird beim
  /// nächsten Push gesendet. [zuordnungBestaetigt]: der Nutzer hat den
  /// lokalen Ortswechsel eines Geräts ausdrücklich bestätigt.
  Future<void> aufloesen(SyncKonflikt k, Map<String, dynamic> ergebnis, {bool zuordnungBestaetigt = false}) async {
    final typ = syncTypDef(k.typ)!;
    final json = typ.normalisiere({...ergebnis, 'aktualisiertAm': DateTime.now().toUtc().toIso8601String()});
    await typ.store.record(k.uuid).put(db, json.cast<String, Object?>());
    final unveraendertGegenServer = k.server != null && gleicherInhalt(json, k.server!);
    await meta.set(
      k.typ,
      k.uuid,
      SyncMeta(
        version: k.serverVersion,
        // Ergebnis = Serverstand → nichts zu senden, sonst gilt es als geändert.
        hash: unveraendertGegenServer ? inhaltsHash(json) : '',
        zuordnungBestaetigt: zuordnungBestaetigt,
      ),
    );
    await konflikte.delete(k.typ, k.uuid);
  }

  /// Abgelehnten Datensatz verwerfen: lokale Fassung löschen, der nächste
  /// Pull holt ggf. die Serverfassung.
  Future<void> verwerfen(SyncKonflikt k) async {
    await syncTypDef(k.typ)!.store.record(k.uuid).delete(db);
    await meta.delete(k.typ, k.uuid);
    await konflikte.delete(k.typ, k.uuid);
  }
}
