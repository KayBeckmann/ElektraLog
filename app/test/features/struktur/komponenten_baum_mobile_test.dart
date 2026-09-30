import 'package:elektralog/core/models/verteiler_komponente.dart';
import 'package:elektralog/core/providers/komponenten_provider.dart';
import 'package:elektralog/core/providers/messungen_provider.dart';
import 'package:elektralog/features/struktur/komponenten_baum_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tiefer Strukturknoten bleibt auf 360dp lesbar', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final nodes = <VerteilerKomponente>[
      for (var depth = 0; depth < 5; depth++)
        VerteilerKomponente(
          uuid: 'node-$depth',
          verteilerUuid: 'verteiler',
          parentUuid: depth == 0 ? null : 'node-${depth - 1}',
          typ: 'vorsicherung',
          betriebsmittelkennzeichen: 'F${depth + 1}',
          zielbezeichnung: depth == 4
              ? 'Außenbeleuchtung im Gelände'
              : 'Vorsicherung $depth',
          position: depth,
        ),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        komponentenByVerteilerProvider('verteiler')
            .overrideWith((ref) => Stream.value(nodes)),
        for (final node in nodes)
          messungenByKomponenteProvider(node.uuid)
              .overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: KomponentenBaumWidget(
                verteilerUuid: 'verteiler',
                onAddKomponente: (_) {},
                onEditKomponente: (_) {},
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final label = find.text('Außenbeleuchtung im Gelände');
    expect(label, findsOneWidget);
    expect(tester.getSize(label).width, greaterThan(120));
    expect(tester.getSize(label).height, lessThan(80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Komponentenbaum bleibt auf 320dp mit großer Schrift lesbar',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final nodes = [
      for (var depth = 0; depth < 5; depth++)
        VerteilerKomponente(
          uuid: 'deep-$depth',
          verteilerUuid: 'v',
          parentUuid: depth == 0 ? null : 'deep-${depth - 1}',
          typ: 'vorsicherung',
          zielbezeichnung:
              depth == 4 ? 'Außenbeleuchtung im Gelände' : 'Ebene $depth',
        ),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        komponentenByVerteilerProvider('v')
            .overrideWith((ref) => Stream.value(nodes)),
        for (final node in nodes)
          messungenByKomponenteProvider(node.uuid)
              .overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
            body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: KomponentenBaumWidget(
                  verteilerUuid: 'v',
                  onAddKomponente: (_) {},
                  onEditKomponente: (_) {})),
        )),
      ),
    ));
    await tester.pumpAndSettle();
    final label = find.text('Außenbeleuchtung im Gelände');
    expect(tester.getSize(label).width, greaterThan(120));
    expect(tester.getSize(label).height, lessThan(100));
    expect(tester.takeException(), isNull);
  });
}
