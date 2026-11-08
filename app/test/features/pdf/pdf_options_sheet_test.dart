import 'package:elektralog/features/pdf/pdf_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Das Protokoll übernimmt das Prüfgerät der Messungen; ohne Angabe dort
/// das Prüfgerät Anlagenprüfung — nie das der Geräteprüfung.
void main() {
  Future<String> feld(WidgetTester tester, {String? vorschlag}) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: Scaffold(body: PdfOptionsSheet(titel: 'UV1', pruefgeraet: vorschlag))),
    ));
    await tester.pumpAndSettle();
    final f = tester.widget<TextField>(find.widgetWithText(TextField, 'Prüfgerät'));
    return f.controller!.text;
  }

  setUp(() => SharedPreferences.setMockInitialValues({
        'einstellungen.pruefgeraet': 'Fluke 1664 FC',
        'einstellungen.pruefgeraetGeraete': 'SECUTEST PRO',
      }));

  testWidgets('Prüfgerät aus den Messungen', (tester) async {
    expect(await feld(tester, vorschlag: 'Metrel MI 3152 / Fluke 1664 FC'), 'Metrel MI 3152 / Fluke 1664 FC');
  });

  testWidgets('ohne Messungs-Angabe: Prüfgerät Anlagenprüfung', (tester) async {
    expect(await feld(tester), 'Fluke 1664 FC');
  });
}
