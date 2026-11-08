import 'package:elektralog/core/models/geraet.dart';
import 'package:flutter_test/flutter_test.dart';

/// M2: Geräte-Stammdaten — UUID, Pflichtangaben, Ersatzwert, Status.
void main() {
  Geraet neu({DateTime? letztePruefung}) => Geraet.neu(
        kundeUuid: 'k',
        standortUuid: 's',
        raumUuid: 'r',
        bezeichnung: 'Bohrmaschine',
        letztePruefung: letztePruefung,
        jetzt: DateTime(2026, 11, 8, 23, 30),
      );

  test('Neuanlage: UUID automatisch, aktiv, Erstellungsdatum als gekennzeichneter Ersatzwert', () {
    final a = neu();
    final b = neu();
    expect(a.uuid, isNot(b.uuid));
    expect(a.uuid, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(a.aktiv, isTrue);
    expect(a.letztePruefungDatum, '2026-11-08', reason: 'Kalendertag, nicht UTC-verschoben');
    expect(a.letztePruefungErsatzwert, isTrue);
    expect(a.fehler, isEmpty);
  });

  test('Angegebene letzte Prüfung ist kein Ersatzwert', () {
    final g = neu(letztePruefung: DateTime(2026, 2, 28));
    expect(g.letztePruefungDatum, '2026-02-28');
    expect(g.letztePruefungErsatzwert, isFalse);
  });

  test('Pflichtangaben und Werte wie auf dem Server', () {
    Geraet mit({String bez = 'X', String raum = 'r', String? sk, bool aktiv = true, String? grund, int? intervall}) =>
        Geraet(
          kundeUuid: 'k',
          standortUuid: 's',
          raumUuid: raum,
          bezeichnung: bez,
          schutzklasse: sk,
          aktiv: aktiv,
          inaktivGrund: grund,
          pruefintervallMonate: intervall,
        );
    expect(mit(bez: ' ').fehler, ['Bezeichnung fehlt']);
    expect(mit(raum: '').fehler, ['Raum fehlt']);
    expect(mit(sk: '2').fehler, hasLength(1));
    expect(mit(sk: 'II').fehler, isEmpty);
    expect(mit(aktiv: false).fehler, ['Inaktives Gerät braucht einen Grund']);
    expect(mit(aktiv: false, grund: 'defekt').fehler, isEmpty);
    expect(mit(intervall: 0).fehler, hasLength(1));
    expect(mit(intervall: 24).fehler, isEmpty);
  });

  test('Statuswechsel schreibt Historie, lässt Prüfdaten unverändert', () {
    final g = neu(letztePruefung: DateTime(2026, 1, 15));
    final inaktiv = g.mitStatus(aktiv: false, grund: 'defekt', benutzer: 'Kay', zeit: DateTime.utc(2026, 11, 1));
    expect(inaktiv.aktiv, isFalse);
    expect(inaktiv.inaktivGrund, 'defekt');
    expect(inaktiv.letztePruefungDatum, '2026-01-15');

    final wieder = inaktiv.mitStatus(aktiv: true, zeit: DateTime.utc(2026, 11, 5));
    expect(wieder.aktiv, isTrue);
    expect(wieder.inaktivGrund, isNull);
    expect(wieder.uuid, g.uuid);
    expect([for (final e in wieder.statusHistorie) (e.aktiv, e.grund)], [(false, 'defekt'), (true, null)]);
    expect(wieder.letztePruefungDatum, '2026-01-15', reason: 'Reaktivierung setzt keinen Prüftermin zurück');
  });

  test('JSON-Rundreise und Suche', () {
    final g = neu().mitStammdaten(bezeichnung: 'Kaffeemaschine', seriennummer: 'SN-99', inventarnummer: 'INV-1');
    final zurueck = Geraet.fromJson(g.toJson());
    expect(zurueck.toJson(), g.toJson());
    expect(g.passtZu('sn-9'), isTrue);
    expect(g.passtZu('inv-1'), isTrue);
    expect(g.passtZu(g.uuid.substring(0, 8)), isTrue);
    expect(g.passtZu('bohr'), isFalse);
  });
}
