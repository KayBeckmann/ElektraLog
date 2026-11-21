import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:elektralog/core/api/api_service.dart';
import 'package:elektralog/core/api/versand_api.dart';
import 'package:elektralog/features/einstellungen/smtp_einstellungen.dart';
import 'package:elektralog/features/protokolle/protokoll_versand_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _pdf = Uint8List.fromList(utf8.encode('%PDF-1.4 archiviert'));
final _hash = sha256.convert(_pdf).toString();

class _FakeApi extends VersandApi {
  Map<String, dynamic> antwort = {};
  final sendungen = <Map<String, Object?>>[];
  final smtpGespeichert = <Map<String, Object?>>[];
  final tests = <String>[];
  Object? sendeFehler;
  Map<String, dynamic> smtp = {'konfiguriert': false};

  @override
  Future<Map<String, dynamic>> info(String protokollId) async => antwort;

  @override
  Future<Map<String, dynamic>> senden({
    required String protokollId,
    required String anfrageId,
    required String empfaenger,
    List<String> cc = const [],
    required String pdfHash,
  }) async {
    sendungen.add({'id': protokollId, 'anfrageId': anfrageId, 'an': empfaenger, 'cc': cc, 'hash': pdfHash});
    if (sendeFehler case final f?) throw f;
    return {'status': 'gesendet'};
  }

  @override
  Future<Uint8List> pdf(String protokollId) async => _pdf;

  @override
  Future<Map<String, dynamic>> getSmtp() async => smtp;

  @override
  Future<Map<String, dynamic>> putSmtp({
    required String host,
    required int port,
    required String tlsModus,
    required String absenderEmail,
    String? absenderName,
    String? benutzer,
    String? passwort,
  }) async {
    smtpGespeichert.add({
      'host': host,
      'port': port,
      'tlsModus': tlsModus,
      'absenderEmail': absenderEmail,
      'benutzer': benutzer,
      'passwort': passwort,
    });
    return smtp = {
      'konfiguriert': true,
      'host': host,
      'port': port,
      'tlsModus': tlsModus,
      'absenderEmail': absenderEmail,
      'absenderName': absenderName,
      'benutzer': benutzer,
      'passwortGesetzt': passwort != null && passwort.isNotEmpty || smtp['passwortGesetzt'] == true,
    };
  }

  @override
  Future<void> testSmtp(String empfaenger) async => tests.add(empfaenger);
}

Map<String, dynamic> _info({
  bool smtp = true,
  Map<String, dynamic>? standort = const {
    'uuid': 's1',
    'bezeichnung': 'Werk Nord',
    'kontaktPerson': 'Herr Nord',
    'kontaktEmail': 'nord@muster.invalid',
  },
  List verlauf = const [],
}) =>
    {
      'smtpKonfiguriert': smtp,
      'pdfHash': _hash,
      'dateiname': 'Protokoll_UV_Nord_2026-11-20.pdf',
      'standort': standort,
      'kunde': {'uuid': 'k1', 'name': 'Muster GmbH', 'ansprechpartner': 'Frau Zentral', 'kontaktEmail': 'zentrale@muster.invalid'},
      'verlauf': verlauf,
    };

void main() {
  late _FakeApi api;
  final angezeigt = <String>[];
  String? ergebnis;

  setUp(() {
    api = _FakeApi();
    angezeigt.clear();
    ergebnis = null;
  });

  Future<void> oeffne(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [versandApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => ergebnis = await showDialog<String>(
                context: context,
                builder: (_) => ProtokollVersandDialog(
                  protokollId: 'p1',
                  titel: 'Anlagenprüfung — UV Nord',
                  pdfAnzeigen: (bytes, name) async => angezeigt.add(name),
                ),
              ),
              child: const Text('öffnen'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('öffnen'));
    await tester.pumpAndSettle();
  }

  /// Gewählter Empfänger laut RadioGroup (`standort`, `kunde`, `andere`
  /// oder `null`).
  String? gewaehlt(WidgetTester tester) {
    final gruppe = tester.widget(find.byWidgetPredicate((w) => w is RadioGroup)) as dynamic;
    return (gruppe.groupValue as Enum?)?.name;
  }

  Future<void> sendenUndBestaetigen(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('versand-senden')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('versand-bestaetigen')));
    await tester.pumpAndSettle();
  }

  testWidgets('Standort-E-Mail vorgeschlagen, Kunde nur wählbar; Bestätigung mit archivierter Fassung', (tester) async {
    api.antwort = _info();
    await oeffne(tester);

    expect(find.text('Standort: Werk Nord'), findsOneWidget);
    expect(gewaehlt(tester), 'standort');
    expect(find.textContaining('Kunde Muster GmbH (nicht der Standort)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('versand-pdf-ansehen')));
    await tester.pumpAndSettle();
    expect(angezeigt, ['Protokoll_UV_Nord_2026-11-20.pdf']);

    await tester.enterText(find.byKey(const Key('versand-cc')), 'buero@firma.invalid; chef@firma.invalid');
    await tester.tap(find.byKey(const Key('versand-senden')));
    await tester.pumpAndSettle();
    expect(find.text('An: nord@muster.invalid'), findsOneWidget);
    expect(find.textContaining('Prüfsumme ${_hash.substring(0, 12)}'), findsOneWidget);
    await tester.tap(find.byKey(const Key('versand-bestaetigen')));
    await tester.pumpAndSettle();

    expect(api.sendungen.single, allOf(
      containsPair('an', 'nord@muster.invalid'),
      containsPair('cc', ['buero@firma.invalid', 'chef@firma.invalid']),
      containsPair('hash', _hash),
    ));
    expect(ergebnis, 'nord@muster.invalid');
    expect(find.byType(ProtokollVersandDialog), findsNothing);
  });

  testWidgets('Standort ohne E-Mail: kein Vorschlag, Kunde muss bewusst gewählt werden', (tester) async {
    api.antwort = _info(standort: {'uuid': 's1', 'bezeichnung': 'Werk Süd', 'kontaktPerson': null, 'kontaktEmail': null});
    await oeffne(tester);
    expect(find.byKey(const Key('versand-standort-ohne-email')), findsOneWidget);
    expect(find.byKey(const Key('versand-empfaenger-standort')), findsNothing);
    expect(gewaehlt(tester), isNull);
    expect(tester.widget<FilledButton>(find.byKey(const Key('versand-senden'))).onPressed, isNull);

    await tester.tap(find.byKey(const Key('versand-empfaenger-kunde')));
    await tester.pumpAndSettle();
    await sendenUndBestaetigen(tester);
    expect(api.sendungen.single['an'], 'zentrale@muster.invalid');
  });

  testWidgets('Ohne SMTP kein Versand; ungültige andere Adresse wird abgefangen', (tester) async {
    api.antwort = _info(smtp: false);
    await oeffne(tester);
    expect(find.byKey(const Key('versand-kein-smtp')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('versand-senden'))).onPressed, isNull);

    await tester.tap(find.text('Schließen'));
    await tester.pumpAndSettle();
    api.antwort = _info();
    await tester.tap(find.text('öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('versand-empfaenger-andere')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('versand-andere')), 'kein-at');
    await tester.tap(find.byKey(const Key('versand-senden')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('versand-fehler')), findsOneWidget);
    expect(find.text('Protokoll versenden?'), findsNothing);
    expect(api.sendungen, isEmpty);
  });

  testWidgets('Verbindungsabbruch: Wiederholung mit derselben Anfrage-ID; Serverfehler: neue ID', (tester) async {
    api.antwort = _info(verlauf: [
      {'empfaenger': 'nord@muster.invalid', 'cc': [], 'status': 'gesendet', 'erstelltAm': '2026-11-20T09:00:00Z', 'benutzer': 'Kay'},
    ]);
    await oeffne(tester);
    expect(find.textContaining('an nord@muster.invalid · Kay — gesendet'), findsOneWidget);

    api.sendeFehler = Exception('Zeitüberschreitung');
    await sendenUndBestaetigen(tester);
    expect(find.textContaining('nicht doppelt'), findsOneWidget);
    await sendenUndBestaetigen(tester);
    expect(api.sendungen[0]['anfrageId'], api.sendungen[1]['anfrageId']);

    api.sendeFehler = ApiException(502, 'Versand abgelehnt: Mailbox voll');
    await sendenUndBestaetigen(tester);
    expect(find.text('Versand abgelehnt: Mailbox voll'), findsOneWidget);
    await sendenUndBestaetigen(tester);
    expect(api.sendungen[3]['anfrageId'], isNot(api.sendungen[2]['anfrageId']));
    expect(find.byType(ProtokollVersandDialog), findsOneWidget);
  });

  group('SMTP-Einstellungen', () {
    Future<void> zeige(WidgetTester tester, Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        // Neuer Container je Aufruf, sonst bleibt der Modus zwischengespeichert.
        key: UniqueKey(),
        overrides: [versandApiProvider.overrideWithValue(api)],
        child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SmtpEinstellungen()))),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('Firmenadmin richtet ein, Passwort leer = unverändert, Testnachricht', (tester) async {
      await zeige(tester, {'jwt_token': 't', 'ist_admin': true, 'rolle': 'Firmenadmin'});
      await tester.enterText(find.byKey(const Key('smtp-host')), 'smtp.firma.invalid');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SSL/TLS (meist Port 465)').last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '465'), findsOneWidget, reason: 'Standardport mitgezogen');
      await tester.enterText(find.byKey(const Key('smtp-absender')), 'protokolle@firma.invalid');
      await tester.enterText(find.byKey(const Key('smtp-passwort')), 'geheim');
      await tester.tap(find.byKey(const Key('smtp-speichern')));
      await tester.pumpAndSettle();
      expect(api.smtpGespeichert.last, {
        'host': 'smtp.firma.invalid',
        'port': 465,
        'tlsModus': 'ssl',
        'absenderEmail': 'protokolle@firma.invalid',
        'benutzer': null,
        'passwort': 'geheim',
      });
      expect(find.text('Gespeichert — leer lassen, um es zu behalten'), findsOneWidget);
      expect(tester.widget<TextFormField>(find.byKey(const Key('smtp-passwort'))).controller!.text, isEmpty);

      await tester.tap(find.byKey(const Key('smtp-speichern')));
      await tester.pumpAndSettle();
      expect(api.smtpGespeichert.last['passwort'], isNull, reason: 'leer lassen behält das Passwort');

      await tester.tap(find.byKey(const Key('smtp-testen')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('smtp-test-empfaenger')), 'kay@firma.invalid');
      await tester.tap(find.text('Senden'));
      await tester.pumpAndSettle();
      expect(api.tests, ['kay@firma.invalid']);
    });

    testWidgets('Monteur und Solo-Modus sehen nur einen Hinweis', (tester) async {
      await zeige(tester, {'jwt_token': 't', 'ist_admin': false, 'rolle': 'Monteur'});
      expect(find.byKey(const Key('smtp-host')), findsNothing);
      expect(find.textContaining('richtet der Firmenadmin ein'), findsOneWidget);
      await zeige(tester, {});
      expect(find.textContaining('nur mit Firmenkonto'), findsOneWidget);
    });
  });
}
