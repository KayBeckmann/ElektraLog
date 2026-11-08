import 'package:elektralog/core/models/messung.dart';
import 'package:elektralog/core/providers/einstellungen_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zwei Prüfgeräte: Anlagenprüfung (Messungen, Verteiler-Protokolle) und
/// Geräteprüfung; jede Messung merkt sich ihr Prüfgerät.
void main() {
  Messung messung(String? pruefgeraet) => Messung(
        komponenteUuid: 'k',
        norm: 'vde_0100',
        pruefungDatum: DateTime(2026, 11, 8),
        ergebnis: 'bestanden',
        pruefgeraet: pruefgeraet,
      );

  test('Messung: Prüfgerät übersteht JSON, alte Daten ohne Feld bleiben lesbar', () {
    final m = messung('Fluke 1664 FC #123');
    expect(Messung.fromJson(m.toJson()).pruefgeraet, 'Fluke 1664 FC #123');
    expect(m.copyWith(bemerkung: 'x').pruefgeraet, 'Fluke 1664 FC #123');
    final alt = m.toJson()..remove('pruefgeraet');
    expect(Messung.fromJson(alt).pruefgeraet, isNull);
  });

  test('Vorschlag fürs Protokoll: Prüfgeräte der Messungen, sonst Einstellung', () {
    expect(
      pruefgeraeteAusMessungen([messung('A'), messung(' A '), messung('B'), messung(null)], ersatz: 'X'),
      'A / B',
    );
    expect(pruefgeraeteAusMessungen([messung(null), messung('  ')], ersatz: 'X'), 'X');
    expect(pruefgeraeteAusMessungen([], ersatz: ' '), isNull);
  });

  group('Einstellungen', () {
    Future<Einstellungen> laden() async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c.read(einstellungenProvider.future);
    }

    test('bisheriges Prüfgerät gilt als Prüfgerät für die Anlagenprüfung', () async {
      SharedPreferences.setMockInitialValues({'einstellungen.pruefgeraet': 'Metrel MI 3152'});
      final e = await laden();
      expect((e.pruefgeraetAnlagen, e.pruefgeraetGeraete), ('Metrel MI 3152', null));
    });

    test('beide Prüfgeräte werden getrennt gespeichert', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(einstellungenProvider.future);
      await c.read(einstellungenProvider.notifier).save(
            prueferName: '',
            firma: '',
            firmaStrasse: '',
            firmaPlz: '',
            firmaOrt: '',
            pruefgeraetAnlagen: 'Fluke 1664 FC',
            pruefgeraetGeraete: 'SECUTEST PRO',
            serverUrl: '',
          );
      final e = await laden();
      expect((e.pruefgeraetAnlagen, e.pruefgeraetGeraete), ('Fluke 1664 FC', 'SECUTEST PRO'));
    });
  });
}
