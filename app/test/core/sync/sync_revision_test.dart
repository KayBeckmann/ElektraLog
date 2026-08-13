// Roadmap Phase 9, M9.1 — "Sync-Verhalten nach Server-Backup/Rücksetzung".
//
// Testet die reine Entscheidungslogik ohne Netzwerk/DB, damit sich das
// Rollback-Szenario deterministisch und schnell prüfen lässt (siehe
// M9.1-Checkliste: "Testfälle mit simuliertem Server-Restore ergänzen").

import 'package:flutter_test/flutter_test.dart';
import 'package:elektralog/core/sync/sync_revision.dart';

void main() {
  group('evaluateSyncRevision', () {
    test('kein bekannter Baseline-Wert → noBaseline (erster Kontakt)', () {
      final result = evaluateSyncRevision(lastKnown: null, serverRevision: 0);
      expect(result, RevisionCheck.noBaseline);
    });

    test('noBaseline auch bei bereits hoher Server-Revision', () {
      final result =
          evaluateSyncRevision(lastKnown: null, serverRevision: 9999);
      expect(result, RevisionCheck.noBaseline);
    });

    test('Server-Revision höher als bekannt → advanced', () {
      final result =
          evaluateSyncRevision(lastKnown: 10, serverRevision: 11);
      expect(result, RevisionCheck.advanced);
    });

    test('Server-Revision unverändert → unchanged', () {
      final result =
          evaluateSyncRevision(lastKnown: 10, serverRevision: 10);
      expect(result, RevisionCheck.unchanged);
    });

    test('Server-Revision niedriger als bekannt → rollbackDetected', () {
      final result =
          evaluateSyncRevision(lastKnown: 50, serverRevision: 12);
      expect(result, RevisionCheck.rollbackDetected);
    });

    test('Server-Restore-Szenario: Revision springt um genau 1 zurück', () {
      // Grenzfall: schon ein einziger Schritt Rückwärtssprung muss erkannt
      // werden, nicht erst ab einer größeren Differenz.
      final result =
          evaluateSyncRevision(lastKnown: 5, serverRevision: 4);
      expect(result, RevisionCheck.rollbackDetected);
    });

    test('Reihenfolge mehrerer Syncs nach echtem Restore bleibt konsistent',
        () {
      // Simuliert: Client kannte Revision 100, Server wird auf Backup mit
      // Revision 40 zurückgesetzt. Jeder weitere Push erhöht die
      // (rollbackte) Server-Revision um 1 — der Rollback bleibt erkannt,
      // bis der Server wieder bei/über 100 angekommen ist.
      const lastKnown = 100;
      for (var serverRevision = 40; serverRevision < 100; serverRevision++) {
        expect(
          evaluateSyncRevision(
              lastKnown: lastKnown, serverRevision: serverRevision),
          RevisionCheck.rollbackDetected,
          reason: 'serverRevision=$serverRevision sollte noch als Rollback '
              'gegenüber lastKnown=$lastKnown gelten',
        );
      }
      expect(
        evaluateSyncRevision(lastKnown: lastKnown, serverRevision: 100),
        RevisionCheck.unchanged,
      );
      expect(
        evaluateSyncRevision(lastKnown: lastKnown, serverRevision: 101),
        RevisionCheck.advanced,
      );
    });
  });
}
