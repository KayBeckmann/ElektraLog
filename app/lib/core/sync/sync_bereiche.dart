import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../providers/sync_auswahl_provider.dart';
import 'sync_engine.dart';
import 'sync_meta.dart';

/// Wo liegt ein Datensatz des Verteiler-Aufbaus bzw. der Geräteprüfung?
/// `null` für Basisdaten (Kunden, Standorte, Verteiler, Räume) — die kommen
/// immer vollständig und hängen an keiner Auswahl.
typedef Bereich = ({String? verteiler, String? raum, String? standort, String? kunde});

/// Download-Auswahl dieses Arbeitsgeräts mit den lokalen Basisdaten
/// aufgelöst: Ein Kunde deckt seine Standorte ab, ein Standort seine
/// Verteiler (Anlagen) bzw. seine Räume (Geräte).
class SyncBereiche {
  SyncBereiche._(this.db, this._auswahl);

  final Database db;
  final ({
    Set<String> kunden,
    Set<String> standorte,
    Set<String> verteiler,
    Set<String> geraeteStandorte,
    Set<String> raeume
  }) _auswahl;

  final _standortKunde = <String, String?>{};
  final _verteilerStandort = <String, String?>{};
  final _komponenteVerteiler = <String, String?>{};
  final _geraet = <String, Map<String, Object?>?>{};

  static Future<SyncBereiche> laden(Database db) async {
    final r = SyncAuswahlRepository(db);
    return SyncBereiche._(db, (
      kunden: await r.getAktivierteKundeUuids(),
      standorte: await r.getAktivierteStandortUuids(),
      verteiler: await r.getAktivierteVerteilerUuids(),
      geraeteStandorte: await r.getAktivierteGeraeteStandortUuids(),
      raeume: await r.getAktivierteRaumUuids(),
    ));
  }

  Future<String?> _feld(
      StoreRef<String, Map<String, Object?>> store, Map<String, Object?> cache, String? uuid, String feld) async {
    if (uuid == null) return null;
    if (cache.containsKey(uuid)) return cache[uuid] as String?;
    final v = (await store.record(uuid).get(db))?[feld] as String?;
    cache[uuid] = v;
    return v;
  }

  Future<String?> _kundeVonStandort(String? s) => _feld(StorageService.standorteStore, _standortKunde, s, 'kundeUuid');
  Future<String?> _standortVonVerteiler(String? v) =>
      _feld(StorageService.verteilerStore, _verteilerStandort, v, 'standortUuid');
  Future<String?> _verteilerVonKomponente(String? k) =>
      _feld(StorageService.komponentenStore, _komponenteVerteiler, k, 'verteilerUuid');

  Future<Bereich> _anlage(String? verteiler) async {
    final standort = await _standortVonVerteiler(verteiler);
    return (verteiler: verteiler, raum: null, standort: standort, kunde: await _kundeVonStandort(standort));
  }

  Future<Bereich> _geraeteBereich(Map<String, Object?>? g) async {
    final standort = g?['standortUuid'] as String?;
    return (
      verteiler: null,
      raum: g?['raumUuid'] as String?,
      standort: standort,
      kunde: g?['kundeUuid'] as String? ?? await _kundeVonStandort(standort),
    );
  }

  /// Bereich eines Datensatzes; `null` = Basisdaten.
  Future<Bereich?> bereich(String typ, Map<String, Object?> json) async {
    switch (typ) {
      case 'komponenten':
      case 'sichtpruefungen':
        return _anlage(json['verteilerUuid'] as String?);
      case 'messungen':
        return _anlage(await _verteilerVonKomponente(json['komponenteUuid'] as String?));
      case 'geraete':
        return _geraeteBereich(json);
      case 'geraetepruefungen':
        final id = json['geraetUuid'] as String?;
        if (id != null && !_geraet.containsKey(id)) _geraet[id] = await StorageService.geraeteStore.record(id).get(db);
        return _geraeteBereich(id == null ? null : _geraet[id]);
    }
    return null;
  }

  /// Wird der Bereich heruntergeladen?
  bool ausgewaehlt(Bereich b) {
    final a = _auswahl;
    if (b.kunde != null && a.kunden.contains(b.kunde)) return true;
    if (b.verteiler != null) return a.verteiler.contains(b.verteiler) || a.standorte.contains(b.standort);
    return a.raeume.contains(b.raum) || a.geraeteStandorte.contains(b.standort);
  }

  /// Bereich zur Auswahl hinzufügen (Verteiler bzw. Raum, sonst Standort).
  Future<void> auswaehlen(Bereich b) async {
    if (ausgewaehlt(b)) return;
    final r = SyncAuswahlRepository(db);
    if (b.verteiler != null) {
      await r.setVerteilerAktiviert(b.verteiler!, true);
      _auswahl.verteiler.add(b.verteiler!);
    } else if (b.raum != null) {
      await r.setRaumAktiviert(b.raum!, true);
      _auswahl.raeume.add(b.raum!);
    } else if (b.standort != null) {
      await r.setGeraeteStandortAktiviert(b.standort!, true);
      _auswahl.geraeteStandorte.add(b.standort!);
    }
  }
}

/// Bereiche, in denen auf diesem Gerät gearbeitet wurde, bleiben
/// ausgewählt — sonst verschwände frisch Erfasstes nach dem Hochladen
/// wieder vom Gerät.
Future<void> bereicheAuswaehlen(Database db, Iterable<(String typ, Map<String, Object?> json)> datensaetze) async {
  final b = await SyncBereiche.laden(db);
  for (final (typ, json) in datensaetze) {
    final bereich = await b.bereich(typ, json);
    if (bereich != null) await b.auswaehlen(bereich);
  }
}

const _bestandUebernommen = 'meta:bestand_uebernommen';

/// Entfernt Anlagen-Aufbau und Geräte außerhalb der Auswahl vom Gerät —
/// aber nur, was vollständig auf dem Server liegt (Inhalt = zuletzt
/// synchronisierter Stand, kein offener Konflikt). Ungesendete Änderungen
/// bleiben, bis sie hochgeladen sind.
///
/// Beim ersten Lauf wird stattdessen der vorhandene Bestand ausgewählt,
/// damit ein Update der App nichts vom Gerät nimmt, was vorher da war.
/// Gibt die Anzahl entfernter Datensätze zurück.
Future<int> abgewaehltesEntfernen(Database db) async {
  final marker = StorageService.syncAuswahlStore.record(_bestandUebernommen);
  if (await marker.get(db) == null) {
    await bereicheAuswaehlen(db, [
      for (final typ in syncTypDefs)
        for (final s in await typ.store.find(db)) (typ.name, s.value),
    ]);
    await marker.put(db, {'typ': 'meta', 'uuid': 'bestand', 'am': DateTime.now().toUtc().toIso8601String()});
    return 0;
  }

  final b = await SyncBereiche.laden(db);
  final meta = SyncMetaRepository(db);
  final metas = await meta.alle();
  final offen = await SyncKonfliktRepository(db).schluessel();
  final weg = <(SyncTypDef, String)>[];
  for (final typ in syncTypDefs) {
    for (final s in await typ.store.find(db)) {
      final bereich = await b.bereich(typ.name, s.value);
      if (bereich == null || b.ausgewaehlt(bereich)) continue;
      final key = syncSchluessel(typ.name, s.key);
      final m = metas[key];
      if (offen.contains(key) || m == null || m.zuordnungBestaetigt) continue;
      if (m.hash != inhaltsHash(typ.normalisiere(s.value.cast<String, dynamic>()))) continue;
      weg.add((typ, s.key));
    }
  }
  // Kinder zuerst, damit Bereiche bis zum Schluss auflösbar bleiben.
  for (final (typ, uuid) in weg.reversed) {
    await typ.store.record(uuid).delete(db);
    await meta.delete(typ.name, uuid);
  }
  return weg.length;
}
