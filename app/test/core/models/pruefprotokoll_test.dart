// Task #103 — lokale PDF-Bytes im Pruefprotokoll für einen späteren Retry.
//
// Testet die reine Modell-Logik (toJson/fromJson, mitBackendUuid, ohnePdf)
// ohne Netzwerk/DB, analog zu sync_revision_test.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:elektralog/core/models/pruefprotokoll.dart';

void main() {
  group('Pruefprotokoll — pdfBase64', () {
    test('toJson/fromJson-Roundtrip erhält pdfBase64', () {
      final p = Pruefprotokoll(
        verteilerUuid: 'v-1',
        protokollDatum: DateTime.utc(2026, 8, 1),
        pdfBase64: 'AAECAw==',
      );
      final restored = Pruefprotokoll.fromJson(p.toJson());
      expect(restored.pdfBase64, 'AAECAw==');
      expect(restored.backendUuid, isNull);
    });

    test('fromJson ohne pdfBase64-Schlüssel (alter Datensatz) → null', () {
      final json = Pruefprotokoll(
        verteilerUuid: 'v-1',
        protokollDatum: DateTime.utc(2026, 8, 1),
      ).toJson()
        ..remove('pdfBase64');
      final restored = Pruefprotokoll.fromJson(json);
      expect(restored.pdfBase64, isNull);
    });

    test('mitBackendUuid behält pdfBase64 (Retry braucht es ggf. weiterhin)',
        () {
      final p = Pruefprotokoll(
        verteilerUuid: 'v-1',
        protokollDatum: DateTime.utc(2026, 8, 1),
        pdfBase64: 'AAECAw==',
      );
      final mitUuid = p.mitBackendUuid('backend-123');
      expect(mitUuid.backendUuid, 'backend-123');
      expect(mitUuid.pdfBase64, 'AAECAw==');
    });

    test('ohnePdf verwirft pdfBase64, behält alle anderen Felder', () {
      final p = Pruefprotokoll(
        verteilerUuid: 'v-1',
        protokollDatum: DateTime.utc(2026, 8, 1),
        prueferName: 'Max Muster',
        backendUuid: 'backend-123',
        pdfBase64: 'AAECAw==',
      );
      final ohnePdf = p.ohnePdf();
      expect(ohnePdf.pdfBase64, isNull);
      expect(ohnePdf.backendUuid, 'backend-123');
      expect(ohnePdf.prueferName, 'Max Muster');
      expect(ohnePdf.uuid, p.uuid);
    });

    test('neu erstelltes Protokoll ohne Upload hat pdfBase64, aber kein '
        'backendUuid — genau der "ausstehend"-Zustand für den Retry', () {
      final p = Pruefprotokoll(
        verteilerUuid: 'v-1',
        protokollDatum: DateTime.utc(2026, 8, 1),
        pdfBase64: 'AAECAw==',
      );
      expect(p.backendUuid, isNull);
      expect(p.pdfBase64, isNotNull);
    });
  });
}
