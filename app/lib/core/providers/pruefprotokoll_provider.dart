import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../api/api_service.dart';
import '../database/isar_service.dart';
import '../models/pruefprotokoll.dart';
import '../online/online_daten.dart';
import '../online/online_repositories.dart';
import 'isar_provider.dart';

/// Lädt ein Protokoll in die Dokumentenablage; liefert die Backend-ID oder
/// null (offline, nicht angemeldet). In Tests ersetzbar.
typedef ProtokollUpload = Future<String?> Function(Pruefprotokoll p, Uint8List bytes);

Future<String?> protokollHochladen(Pruefprotokoll p, Uint8List bytes) => ApiService.uploadProtokoll(
      pdfBytes: bytes,
      verteilerBezeichnung: p.verteilerBezeichnung ?? '',
      standortBezeichnung: p.standortBezeichnung,
      kundenBezeichnung: p.kundenBezeichnung,
      prueferName: p.prueferName,
      firmaName: p.firma,
      protokollDatum: p.protokollDatum,
      messdatenJson: p.messdatenSnapshot,
      art: p.art,
      bezugUuid: p.verteilerUuid,
    );

/// Ergebnis von [PruefprotokollRepository.ablegen]: sofort gespeichert,
/// [upload] meldet den Stand in der Dokumentenablage.
typedef ProtokollAblage = ({Pruefprotokoll lokal, Future<Pruefprotokoll> upload});

/// Prüfverlauf und Dokumentenablage; lokal (Endgeräte) oder online
/// (Web-App, liest den Verlauf aus der Ablage). `PruefprotokollRepository(db)`
/// liefert die lokale Umsetzung.
abstract interface class PruefprotokollRepository {
  const factory PruefprotokollRepository(Database db) = LokalesPruefprotokollRepository;

  Stream<List<Pruefprotokoll>> watchByVerteiler(String verteilerUuid);
  Future<List<Pruefprotokoll>> getByVerteiler(String verteilerUuid);
  Future<Pruefprotokoll?> latestByVerteiler(String verteilerUuid);
  Future<void> save(Pruefprotokoll p);
  Future<List<Pruefprotokoll>> getAusstehende();

  /// Legt ein erzeugtes PDF ab: Endgeräte speichern zuerst lokal und laden
  /// im Hintergrund hoch (offline später per Sync); die Web-App lädt direkt
  /// hoch und wirft, wenn das nicht klappt.
  Future<ProtokollAblage> ablegen(Pruefprotokoll p, Uint8List bytes, {ProtokollUpload? upload});
}

class LokalesPruefprotokollRepository implements PruefprotokollRepository {
  const LokalesPruefprotokollRepository(this._db);
  final Database _db;

  @override
  Stream<List<Pruefprotokoll>> watchByVerteiler(String verteilerUuid) {
    final finder = Finder(
      filter: Filter.equals('verteilerUuid', verteilerUuid),
      sortOrders: [SortOrder('protokollDatum', false)],
    );
    return StorageService.pruefprotokollStore
        .query(finder: finder)
        .onSnapshots(_db)
        .map((s) => s
            .map((snap) =>
                Pruefprotokoll.fromJson(snap.value.cast<String, dynamic>()))
            .toList());
  }

  @override
  Future<List<Pruefprotokoll>> getByVerteiler(String verteilerUuid) async {
    final finder = Finder(
      filter: Filter.equals('verteilerUuid', verteilerUuid),
      sortOrders: [SortOrder('protokollDatum', false)],
    );
    final snaps =
        await StorageService.pruefprotokollStore.find(_db, finder: finder);
    return snaps
        .map((snap) =>
            Pruefprotokoll.fromJson(snap.value.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Pruefprotokoll?> latestByVerteiler(String verteilerUuid) async {
    final finder = Finder(
      filter: Filter.equals('verteilerUuid', verteilerUuid),
      sortOrders: [SortOrder('protokollDatum', false)],
      limit: 1,
    );
    final snaps =
        await StorageService.pruefprotokollStore.find(_db, finder: finder);
    if (snaps.isEmpty) return null;
    return Pruefprotokoll.fromJson(snaps.first.value.cast<String, dynamic>());
  }

  @override
  Future<void> save(Pruefprotokoll p) async {
    await StorageService.pruefprotokollStore
        .record(p.uuid)
        .put(_db, p.toJson().cast<String, Object?>());
  }

  /// Protokolle, die noch nicht im Backend angekommen sind, aber noch ihr
  /// Original-PDF lokal vorhalten — also erneut hochgeladen werden können.
  /// Basis für [SyncService.retryAusstehendeProtokolle].
  @override
  Future<List<Pruefprotokoll>> getAusstehende() async {
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('backendUuid', null),
        Filter.notEquals('pdfBase64', null),
      ]),
    );
    final snaps =
        await StorageService.pruefprotokollStore.find(_db, finder: finder);
    return snaps
        .map((snap) =>
            Pruefprotokoll.fromJson(snap.value.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<ProtokollAblage> ablegen(Pruefprotokoll p, Uint8List bytes, {ProtokollUpload? upload}) async {
    await save(p);
    Future<Pruefprotokoll> hochladen() async {
      final id = await (upload ?? protokollHochladen)(p, bytes).catchError((Object _) => null);
      if (id == null) return p;
      final abgelegt = p.mitBackendUuid(id).ohnePdf();
      await save(abgelegt);
      return abgelegt;
    }

    return (lokal: p, upload: hochladen());
  }
}

final pruefprotokollRepositoryProvider =
    Provider<PruefprotokollRepository>((ref) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlinePruefprotokollRepository(o);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => PruefprotokollRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

final pruefprotokolleByVerteilerProvider =
    StreamProvider.family<List<Pruefprotokoll>, String>(
        (ref, verteilerUuid) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlinePruefprotokollRepository(o).watchByVerteiler(verteilerUuid);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) =>
        PruefprotokollRepository(db).watchByVerteiler(verteilerUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

final allePruefprotokolleProvider =
    StreamProvider<List<Pruefprotokoll>>((ref) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlinePruefprotokollRepository(o).watchAlle();
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) {
      final finder = Finder(sortOrders: [SortOrder('protokollDatum', false)]);
      return StorageService.pruefprotokollStore
          .query(finder: finder)
          .onSnapshots(db)
          .map((snaps) => snaps
              .map((snap) =>
                  Pruefprotokoll.fromJson(snap.value.cast<String, dynamic>()))
              .toList());
    },
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});
