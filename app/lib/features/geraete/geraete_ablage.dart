import 'dart:convert';
import 'dart:typed_data';

import 'package:sembast/sembast.dart';

import '../../core/api/api_service.dart';
import '../../core/models/geraete_protokoll.dart';
import '../../core/models/geraete_pruefung.dart';
import '../../core/models/pruefprotokoll.dart';
import '../../core/providers/pruefprotokoll_provider.dart';

/// Lädt ein Protokoll in die Dokumentenablage; liefert die Backend-ID oder
/// null (offline, nicht angemeldet). In Tests ersetzbar.
typedef ProtokollUpload = Future<String?> Function(Pruefprotokoll p, Uint8List bytes);

Future<String?> _hochladen(Pruefprotokoll p, Uint8List bytes) => ApiService.uploadProtokoll(
      pdfBytes: bytes,
      verteilerBezeichnung: p.verteilerBezeichnung ?? '',
      standortBezeichnung: p.standortBezeichnung,
      kundenBezeichnung: p.kundenBezeichnung,
      prueferName: p.prueferName,
      firmaName: p.firma,
      protokollDatum: p.protokollDatum,
      messdatenJson: p.messdatenSnapshot,
      art: p.art,
    );

/// Messdaten-Snapshot eines Geräteprotokolls: Übersicht und die
/// abgeschlossenen Prüfungen, so wie sie im PDF stehen.
String geraeteSnapshot({
  required String titel,
  ProtokollFilter? filter,
  List<UebersichtZeile> zeilen = const [],
  required List<GeraetePruefung> pruefungen,
}) =>
    jsonEncode({
      'art': 'geraete',
      'titel': titel,
      if (filter != null) 'filter': filter.name,
      'uebersicht': [
        for (final z in zeilen)
          {
            'geraetUuid': z.geraet.uuid,
            'bezeichnung': z.geraet.bezeichnung,
            'raum': z.raum,
            'status': z.status,
            'mitProtokoll': z.mitProtokoll,
          },
      ],
      'pruefungen': [for (final p in pruefungen) p.toJson()],
    });

/// Legt ein unterschriebenes Geräteprotokoll ab (wie bei der
/// Anlagenprüfung): zuerst lokal samt PDF, dann Upload in die
/// Dokumentenablage. Kehrt nach dem lokalen Speichern zurück; `upload`
/// läuft im Hintergrund weiter (schlechter Empfang blockiert nicht).
/// Scheitert er, holt `SyncService.retryAusstehendeProtokolle` ihn mit
/// demselben PDF nach.
Future<({Pruefprotokoll lokal, Future<Pruefprotokoll> upload})> geraeteProtokollAblegen(
  Database db, {
  required String bezugUuid,
  required String titel,
  required Uint8List bytes,
  required String snapshot,
  String? kunde,
  String? standort,
  String? pruefer,
  String? firma,
  ProtokollUpload? upload,
}) async {
  final repo = PruefprotokollRepository(db);
  final protokoll = Pruefprotokoll(
    verteilerUuid: bezugUuid,
    art: 'geraete',
    protokollDatum: DateTime.now(),
    prueferName: pruefer?.isEmpty ?? true ? null : pruefer,
    firma: firma?.isEmpty ?? true ? null : firma,
    verteilerBezeichnung: titel,
    standortBezeichnung: standort,
    kundenBezeichnung: kunde,
    messdatenSnapshot: snapshot,
    pdfBase64: base64Encode(bytes),
  );
  await repo.save(protokoll);

  Future<Pruefprotokoll> hochladen() async {
    final backendUuid = await (upload ?? _hochladen)(protokoll, bytes).catchError((Object _) => null);
    if (backendUuid == null) return protokoll;
    final abgelegt = protokoll.mitBackendUuid(backendUuid).ohnePdf();
    await repo.save(abgelegt);
    return abgelegt;
  }

  return (lokal: protokoll, upload: hochladen());
}
