import 'dart:convert';
import 'dart:typed_data';

import '../../core/models/geraete_protokoll.dart';
import '../../core/models/geraete_pruefung.dart';
import '../../core/models/pruefprotokoll.dart';
import '../../core/providers/pruefprotokoll_provider.dart';

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
/// Anlagenprüfung, siehe [PruefprotokollRepository.ablegen]): Endgeräte
/// speichern zuerst lokal samt PDF und laden im Hintergrund hoch — offline
/// holt `SyncService.retryAusstehendeProtokolle` den Upload nach; die
/// Web-App lädt direkt hoch.
Future<ProtokollAblage> geraeteProtokollAblegen(
  PruefprotokollRepository repo, {
  required String bezugUuid,
  required String titel,
  required Uint8List bytes,
  required String snapshot,
  String? kunde,
  String? standort,
  String? pruefer,
  String? firma,
  ProtokollUpload? upload,
}) =>
    repo.ablegen(
      Pruefprotokoll(
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
      ),
      bytes,
      upload: upload,
    );
