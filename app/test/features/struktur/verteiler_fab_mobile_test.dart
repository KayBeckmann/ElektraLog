import 'package:elektralog/features/struktur/verteiler_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Letzte Baumaktion kann unter dem FAB freigescrollt werden',
      (tester) async {
    tester.view.physicalSize = const Size(360, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {}, label: const Text('Komponente')),
      body: VerteilerContentScroll(
          child: Column(children: [
        const SizedBox(height: 900),
        FilledButton(
            onPressed: () {}, child: const Text('Wurzel-Element hinzufügen')),
      ])),
    )));
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -1100));
    await tester.pumpAndSettle();
    final last = tester.getRect(find.text('Wurzel-Element hinzufügen'));
    final fab = tester.getRect(find.byType(FloatingActionButton));
    expect(last.bottom, lessThan(fab.top));
  });
}
