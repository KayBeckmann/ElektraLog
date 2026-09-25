import 'dart:convert';

import 'package:elektralog/core/models/pruefprotokoll.dart';
import 'package:elektralog/core/models/verteiler_pruefstatus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 19);

  Pruefprotokoll protokoll({
    required DateTime datum,
    String? sichtpruefungErgebnis,
  }) =>
      Pruefprotokoll(
        verteilerUuid: 'verteiler-1',
        protokollDatum: datum,
        messdatenSnapshot: sichtpruefungErgebnis == null
            ? null
            : jsonEncode({
                'sichtpruefung': {'ergebnis': sichtpruefungErgebnis},
              }),
      );

  group('VerteilerPruefstatusInfo.ausLetztemProtokoll', () {
    test('bestandenes Protokoll außerhalb des 90-Tage-Fensters ist grün', () {
      final result = VerteilerPruefstatusInfo.ausLetztemProtokoll(
        protokoll(
            datum: DateTime.utc(2025, 9, 18),
            sichtpruefungErgebnis: 'bestanden'),
        pruefintervallJahre: 2,
        jetzt: now,
      );

      expect(result.status, VerteilerPruefstatus.bestanden);
      expect(result.letztePruefung, DateTime.utc(2025, 9, 18));
    });

    test('nicht bestandene oder mangelhafte Prüfung ist rot', () {
      final result = VerteilerPruefstatusInfo.ausLetztemProtokoll(
        protokoll(
            datum: DateTime.utc(2025, 9, 18),
            sichtpruefungErgebnis: 'mit_maengeln'),
        pruefintervallJahre: 2,
        jetzt: now,
      );

      expect(result.status, VerteilerPruefstatus.nichtBestanden);
    });

    test('nicht bestandene Messung im Snapshot ist rot', () {
      final result = VerteilerPruefstatusInfo.ausLetztemProtokoll(
        Pruefprotokoll(
          verteilerUuid: 'verteiler-1',
          protokollDatum: DateTime.utc(2025, 9, 18),
          messdatenSnapshot: jsonEncode({
            'sichtpruefung': {'ergebnis': 'bestanden'},
            'komponenten': [
              {
                'messungen': [
                  {'ergebnis': 'nicht_bestanden'},
                ],
              },
            ],
          }),
        ),
        pruefintervallJahre: 2,
        jetzt: now,
      );

      expect(result.status, VerteilerPruefstatus.nichtBestanden);
    });

    test(
        'anstehende oder überfällige Prüfung überschreibt das letzte Ergebnis mit grau',
        () {
      final result = VerteilerPruefstatusInfo.ausLetztemProtokoll(
        protokoll(
            datum: DateTime.utc(2025, 12, 18),
            sichtpruefungErgebnis: 'bestanden'),
        pruefintervallJahre: 1,
        jetzt: now,
      );

      expect(result.status, VerteilerPruefstatus.faellig);
      expect(result.naechstePruefung, DateTime(2026, 12, 18));
    });

    test(
        'fehlender oder alter Snapshot bleibt neutral statt als bestanden zu gelten',
        () {
      final result = VerteilerPruefstatusInfo.ausLetztemProtokoll(
        protokoll(datum: DateTime.utc(2025, 9, 18)),
        pruefintervallJahre: 2,
        jetzt: now,
      );

      expect(result.status, VerteilerPruefstatus.unbekannt);
      expect(result.letztePruefung, DateTime.utc(2025, 9, 18));
    });

    test('ohne Protokoll ist der Status neutral und zeigt kein Datum', () {
      final result = VerteilerPruefstatusInfo.ausLetztemProtokoll(
        null,
        pruefintervallJahre: 2,
        jetzt: now,
      );

      expect(result.status, VerteilerPruefstatus.unbekannt);
      expect(result.letztePruefung, isNull);
    });
  });
}
