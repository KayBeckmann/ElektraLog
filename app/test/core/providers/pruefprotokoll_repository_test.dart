// Task #104 — automatischer Retry ausstehender Protokoll-Uploads.
//
// Testet PruefprotokollRepository.getAusstehende() gegen eine echte,
// aber In-Memory-Sembast-Datenbank (kein Netzwerk, keine Plattform-IO) —
// stellt sicher, dass genau die Protokolle gefunden werden, die noch kein
// backendUuid, aber noch ihr PDF lokal haben.

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:elektralog/core/models/pruefprotokoll.dart';
import 'package:elektralog/core/providers/pruefprotokoll_provider.dart';

void main() {
  group('PruefprotokollRepository.getAusstehende', () {
    late PruefprotokollRepository repo;
    var dbCounter = 0;

    setUp(() async {
      // Eigener DB-Pfad pro Test: databaseFactoryMemory hält In-Memory-DBs
      // unter ihrem Pfad über openDatabase-Aufrufe hinweg am Leben — bei
      // gleichem Namen würden Datensätze aus vorherigen Tests sonst in den
      // nächsten Test durchsickern.
      final db = await databaseFactoryMemory
          .openDatabase('test-${dbCounter++}.db');
      repo = PruefprotokollRepository(db);
    });

    test('leere DB → keine ausstehenden Protokolle', () async {
      final result = await repo.getAusstehende();
      expect(result, isEmpty);
    });

    test('Protokoll mit PDF, aber ohne backendUuid → ausstehend', () async {
      final p = Pruefprotokoll(
        verteilerUuid: 'v-1',
        protokollDatum: DateTime.utc(2026, 8, 1),
        pdfBase64: 'AAECAw==',
      );
      await repo.save(p);

      final result = await repo.getAusstehende();
      expect(result, hasLength(1));
      expect(result.single.uuid, p.uuid);
    });

    test('bereits hochgeladenes Protokoll (backendUuid gesetzt, kein PDF '
        'mehr) → nicht mehr ausstehend', () async {
      final p = Pruefprotokoll(
        verteilerUuid: 'v-1',
        protokollDatum: DateTime.utc(2026, 8, 1),
        pdfBase64: 'AAECAw==',
      );
      await repo.save(p.mitBackendUuid('backend-123').ohnePdf());

      final result = await repo.getAusstehende();
      expect(result, isEmpty);
    });

    test('Protokoll ohne PDF und ohne backendUuid (z.B. Altbestand vor '
        'Task #103) → nicht als ausstehend gemeldet, da kein Retry möglich',
        () async {
      final p = Pruefprotokoll(
        verteilerUuid: 'v-1',
        protokollDatum: DateTime.utc(2026, 8, 1),
      );
      await repo.save(p);

      final result = await repo.getAusstehende();
      expect(result, isEmpty);
    });

    test('gemischter Bestand → nur die tatsächlich ausstehenden werden '
        'gefunden', () async {
      final ausstehend1 = Pruefprotokoll(
        verteilerUuid: 'v-1',
        protokollDatum: DateTime.utc(2026, 8, 1),
        pdfBase64: 'AAECAw==',
      );
      final ausstehend2 = Pruefprotokoll(
        verteilerUuid: 'v-2',
        protokollDatum: DateTime.utc(2026, 8, 2),
        pdfBase64: 'AAECAw==',
      );
      final hochgeladen = Pruefprotokoll(
        verteilerUuid: 'v-3',
        protokollDatum: DateTime.utc(2026, 8, 3),
        pdfBase64: 'AAECAw==',
      ).mitBackendUuid('backend-xyz').ohnePdf();

      await repo.save(ausstehend1);
      await repo.save(ausstehend2);
      await repo.save(hochgeladen);

      final result = await repo.getAusstehende();
      expect(result.map((p) => p.uuid).toSet(),
          {ausstehend1.uuid, ausstehend2.uuid});
    });
  });
}
