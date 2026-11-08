import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../providers/isar_provider.dart';

/// Lokaler Sync-Zustand je Datensatz (Roadmap Geräteprüfung M3). Bewusst
/// getrennt von den Datensätzen selbst: Repositories speichern weiter nur
/// ihre Modelle, und „lokal geändert“ ergibt sich aus dem Vergleich des
/// aktuellen Inhalts mit dem zuletzt synchronisierten ([SyncMeta.hash]).
class SyncMeta {
  const SyncMeta({this.version, required this.hash, this.zuordnungBestaetigt = false});

  /// Serverversion, auf der der lokale Stand beruht.
  final int? version;

  /// Hash des zuletzt mit dem Server abgeglichenen Inhalts.
  final String hash;

  /// Der Nutzer hat einen Wechsel von Kunde/Standort/Raum bestätigt.
  final bool zuordnungBestaetigt;

  Map<String, Object?> toJson() => {
        'version': version,
        'hash': hash,
        'zuordnungBestaetigt': zuordnungBestaetigt,
      };

  factory SyncMeta.fromJson(Map<String, Object?> j) => SyncMeta(
        version: (j['version'] as num?)?.toInt(),
        hash: j['hash'] as String? ?? '',
        zuordnungBestaetigt: j['zuordnungBestaetigt'] as bool? ?? false,
      );
}

/// Inhalts-Hash unabhängig von der Schlüsselreihenfolge.
String inhaltsHash(Map<String, dynamic> json) {
  final keys = json.keys.toList()..sort();
  return sha1.convert(utf8.encode(jsonEncode({for (final k in keys) k: json[k]}))).toString();
}

/// Gleicher Inhalt, Zeitstempel ausgenommen (die setzt jede Speicherung neu).
bool gleicherInhalt(Map<String, dynamic> a, Map<String, dynamic> b) {
  Map<String, dynamic> ohne(Map<String, dynamic> m) =>
      {...m}..removeWhere((k, _) => k == 'aktualisiertAm' || k == 'erstelltAm');
  return inhaltsHash(ohne(a)) == inhaltsHash(ohne(b));
}

String syncSchluessel(String typ, String uuid) => '$typ:$uuid';

class SyncMetaRepository {
  const SyncMetaRepository(this._db);
  final Database _db;

  static final store = stringMapStoreFactory.store('sync_meta');

  Future<SyncMeta?> get(String typ, String uuid) async {
    final v = await store.record(syncSchluessel(typ, uuid)).get(_db);
    return v == null ? null : SyncMeta.fromJson(v);
  }

  Future<Map<String, SyncMeta>> alle() async => {
        for (final s in await store.find(_db)) s.key: SyncMeta.fromJson(s.value),
      };

  Future<void> set(String typ, String uuid, SyncMeta meta) =>
      store.record(syncSchluessel(typ, uuid)).put(_db, meta.toJson());

  Future<void> delete(String typ, String uuid) => store.record(syncSchluessel(typ, uuid)).delete(_db);

  /// Bestätigter Ortswechsel eines Geräts: wird beim nächsten Push als
  /// `_zuordnungBestaetigt` mitgeschickt und danach zurückgesetzt.
  Future<void> bestaetigeZuordnung(String typ, String uuid) async {
    final meta = await get(typ, uuid);
    await set(
      typ,
      uuid,
      SyncMeta(version: meta?.version, hash: meta?.hash ?? '', zuordnungBestaetigt: true),
    );
  }

  /// Nach einem erkannten Server-Restore (M9.1): alles gilt als ungesendet
  /// und wird erneut hochgeladen; Abweichungen landen als Konflikt beim Nutzer.
  Future<void> allesAlsUngesendetMarkieren() => store.delete(_db);
}

/// Ein vom Nutzer aufzulösender Sync-Fall.
class SyncKonflikt {
  const SyncKonflikt({
    required this.typ,
    required this.uuid,
    required this.art,
    required this.lokal,
    this.server,
    this.serverVersion,
    this.grund,
    required this.erkanntAm,
  });

  final String typ;
  final String uuid;

  /// `konflikt` (gleichzeitige Änderung), `zuordnung` (Ortswechsel eines
  /// Geräts ohne Bestätigung) oder `abgelehnt` (Server nimmt nicht an).
  final String art;
  final Map<String, dynamic> lokal;
  final Map<String, dynamic>? server;
  final int? serverVersion;
  final String? grund;
  final DateTime erkanntAm;

  String get schluessel => syncSchluessel(typ, uuid);

  Map<String, Object?> toJson() => {
        'typ': typ,
        'uuid': uuid,
        'art': art,
        'lokal': lokal,
        'server': server,
        'serverVersion': serverVersion,
        'grund': grund,
        'erkanntAm': erkanntAm.toUtc().toIso8601String(),
      };

  factory SyncKonflikt.fromJson(Map<String, Object?> j) => SyncKonflikt(
        typ: j['typ'] as String,
        uuid: j['uuid'] as String,
        art: j['art'] as String,
        lokal: (j['lokal'] as Map).cast<String, dynamic>(),
        server: (j['server'] as Map?)?.cast<String, dynamic>(),
        serverVersion: (j['serverVersion'] as num?)?.toInt(),
        grund: j['grund'] as String?,
        erkanntAm: DateTime.parse(j['erkanntAm'] as String),
      );
}

class SyncKonfliktRepository {
  const SyncKonfliktRepository(this._db);
  final Database _db;

  static final store = stringMapStoreFactory.store('sync_konflikte');

  Future<void> put(SyncKonflikt k) => store.record(k.schluessel).put(_db, k.toJson());

  Future<SyncKonflikt?> get(String typ, String uuid) async {
    final v = await store.record(syncSchluessel(typ, uuid)).get(_db);
    return v == null ? null : SyncKonflikt.fromJson(v);
  }

  Future<Set<String>> schluessel() async => (await store.findKeys(_db)).toSet();

  Future<void> delete(String typ, String uuid) => store.record(syncSchluessel(typ, uuid)).delete(_db);

  Stream<List<SyncKonflikt>> watchAlle() => store
      .query(finder: Finder(sortOrders: [SortOrder('erkanntAm')]))
      .onSnapshots(_db)
      .map((snaps) => [for (final s in snaps) SyncKonflikt.fromJson(s.value)]);
}

final syncKonflikteProvider = StreamProvider<List<SyncKonflikt>>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => SyncKonfliktRepository(db).watchAlle(),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});
