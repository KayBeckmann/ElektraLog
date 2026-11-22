import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:elektralog/core/api/versand_api.dart';
import 'package:elektralog/core/models/pruefprotokoll.dart';
import 'package:elektralog/core/providers/pruefprotokoll_provider.dart';
import 'package:elektralog/features/protokolle/protokoll_ergebnis_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _pdf = Uint8List.fromList(utf8.encode('%PDF-1.4 frisch erzeugt'));
final _hash = sha256.convert(_pdf).toString();

final _protokoll = Pruefprotokoll(
  verteilerUuid: 'v1',
  protokollDatum: DateTime(2026, 11, 22),
  verteilerBezeichnung: 'UV Nord',
  pdfBase64: base64Encode(_pdf),
);

class _FakeApi extends VersandApi {
  String archivHash = _hash;
  final sendungen = <({String id, String an, String hash})>[];

  @override
  Future<Map<String, dynamic>> info(String protokollId) async => {
        'smtpKonfiguriert': true,
        'pdfHash': archivHash,
        'dateiname': 'Protokoll_UV_Nord_2026-11-22.pdf',
        'standort': {'uuid': 's1', 'bezeichnung': 'Werk Nord', 'kontaktEmail': 'nord@muster.invalid'},
        'kunde': {'uuid': 'k1', 'name': 'Muster GmbH', 'kontaktEmail': null},
        'verlauf': const [],
      };

  @override
  Future<Map<String, dynamic>> senden({
    required String protokollId,
    required String anfrageId,
    required String empfaenger,
    List<String> cc = const [],
    required String pdfHash,
  }) async {
    sendungen.add((id: protokollId, an: empfaenger, hash: pdfHash));
    return {'status': 'gesendet'};
  }
}

/// Nur [ablegen] wird vom Ergebnisdialog benutzt (erneuter Upload).
class _FakeRepo implements PruefprotokollRepository {
  final ablagen = <Pruefprotokoll>[];
  String? naechsteId = 'b2';

  @override
  Future<ProtokollAblage> ablegen(Pruefprotokoll p, Uint8List bytes, {ProtokollUpload? upload}) async {
    ablagen.add(p);
    final id = naechsteId;
    return (lokal: p, upload: Future.value(id == null ? p : p.mitBackendUuid(id).ohnePdf()));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _FakeApi api;
  late _FakeRepo repo;
  final geteilt = <Uint8List>[];

  setUp(() {
    api = _FakeApi();
    repo = _FakeRepo();
    geteilt.clear();
  });

  Future<void> pump(
    WidgetTester tester, {
    bool company = true,
    ProtokollAblage? ablage,
    String? ablageFehler,
    bool settle = true,
  }) async {
    SharedPreferences.setMockInitialValues(company ? {'jwt_token': 't', 'firma_id': 'f1'} : {});
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      key: UniqueKey(),
      overrides: [
        versandApiProvider.overrideWithValue(api),
        pruefprotokollRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ProtokollErgebnisDialog(
            titel: 'Anlagenprüfung — UV Nord',
            dateiname: 'Protokoll_UV_Nord.pdf',
            bytes: _pdf,
            protokoll: _protokoll,
            ablage: ablage,
            ablageFehler: ablageFehler,
            ansehen: (b, n) async {},
            teilen: (b, n) async => geteilt.add(b),
          ),
        ),
      ),
    ));
    // Mit laufendem Upload dreht sich der Fortschrittskreis — kein Settle.
    settle ? await tester.pumpAndSettle() : await tester.pump(const Duration(milliseconds: 100));
  }

  FilledButton emailKnopf(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(const Key('ergebnis-email')));

  testWidgets('Versand erst nach bestätigtem Upload, dann direkt aus dem Ergebnis', (tester) async {
    final upload = Completer<Pruefprotokoll>();
    await pump(tester, ablage: (lokal: _protokoll, upload: upload.future), settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('ergebnis-laedt')), findsOneWidget);
    expect(emailKnopf(tester).onPressed, isNull, reason: 'ohne Archiv kein Versand');
    expect(api.sendungen, isEmpty, reason: 'nie automatisch senden');

    // PDF bleibt währenddessen teilbar.
    await tester.tap(find.byKey(const Key('ergebnis-teilen')));
    await tester.pump();
    expect(geteilt.single, _pdf);

    upload.complete(_protokoll.mitBackendUuid('b1').ohnePdf());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ergebnis-abgelegt')), findsOneWidget);
    expect(emailKnopf(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('ergebnis-email')));
    await tester.pumpAndSettle();
    expect(find.text('Standort: Werk Nord'), findsOneWidget);
    await tester.tap(find.byKey(const Key('versand-senden')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('versand-bestaetigen')));
    await tester.pumpAndSettle();

    expect(api.sendungen.single, (id: 'b1', an: 'nord@muster.invalid', hash: _hash));
    expect(find.byKey(const Key('ergebnis-gesendet')), findsOneWidget);
    expect(find.text('Per E-Mail an nord@muster.invalid gesendet.'), findsOneWidget);
  });

  testWidgets('Upload ausstehend (offline/Login): Senden gesperrt, erneut hochladen gibt frei', (tester) async {
    await pump(tester, ablage: (lokal: _protokoll, upload: Future.value(_protokoll)));
    expect(find.byKey(const Key('ergebnis-fehler')), findsOneWidget);
    expect(emailKnopf(tester).onPressed, isNull);

    await tester.tap(find.byKey(const Key('ergebnis-erneut-hochladen')));
    await tester.pumpAndSettle();
    expect(repo.ablagen.single.pdfBase64, isNotNull, reason: 'dieselbe lokale Fassung erneut hochladen');
    expect(find.byKey(const Key('ergebnis-fehler')), findsNothing);
    expect(emailKnopf(tester).onPressed, isNotNull);
  });

  testWidgets('Web-App: Upload gescheitert, Fehler sichtbar und erneuter Versuch möglich', (tester) async {
    repo.naechsteId = null;
    await pump(tester, ablageFehler: 'Nicht in der Dokumentenablage gespeichert: Serverfehler');
    expect(find.text('Nicht in der Dokumentenablage gespeichert: Serverfehler'), findsOneWidget);
    expect(emailKnopf(tester).onPressed, isNull);

    await tester.tap(find.byKey(const Key('ergebnis-erneut-hochladen')));
    await tester.pumpAndSettle();
    expect(repo.ablagen, hasLength(1));
    expect(find.byKey(const Key('ergebnis-erneut-hochladen')), findsOneWidget, reason: 'weiter nicht abgelegt');
    expect(emailKnopf(tester).onPressed, isNull);
  });

  testWidgets('Archiv weicht vom erzeugten PDF ab: Versand gesperrt', (tester) async {
    api.archivHash = 'abweichend';
    await pump(tester, ablage: (lokal: _protokoll.mitBackendUuid('b1').ohnePdf(), upload: Future.value(_protokoll)));
    await tester.tap(find.byKey(const Key('ergebnis-email')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('versand-hash-abweichung')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('versand-senden'))).onPressed, isNull);
  });

  testWidgets('Solo-Modus: nur ansehen und teilen, kein E-Mail-Versand', (tester) async {
    await pump(tester, company: false, ablage: (lokal: _protokoll, upload: Future.value(_protokoll)));
    expect(find.byKey(const Key('ergebnis-email')), findsNothing);
    expect(find.byKey(const Key('ergebnis-fehler')), findsNothing);
    await tester.tap(find.byKey(const Key('ergebnis-teilen')));
    await tester.pumpAndSettle();
    expect(geteilt, hasLength(1));
  });
}
