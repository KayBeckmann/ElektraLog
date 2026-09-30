import 'package:elektralog/features/struktur/verteiler_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Verteiler-Breadcrumb behält den aktuellen Verteiler auf 360dp im Bild',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: VerteilerBreadcrumb(
        kunde: 'G. C. Hahn & Co. Stabilisierungstechnik GmbH',
        standort: 'Hauptwerk',
        verteiler: 'NSHV 1-3',
        onKunde: () {},
        onStandort: () {},
      ),
    )));
    expect(find.text('NSHV 1-3'), findsOneWidget);
    final rect = tester.getRect(find.text('NSHV 1-3'));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });
}
