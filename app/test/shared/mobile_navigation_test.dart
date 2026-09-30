import 'package:elektralog/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Fünf Ziele passen bei 360dp und großer Schrift in die Navigation',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? chosen;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.3),
        ),
        child: child!,
      ),
      home: Scaffold(
        bottomNavigationBar: MobileAppNavigation(
          location: '/kunden',
          isCompany: true,
          isAdmin: true,
          onNavigate: (route) => chosen = route,
        ),
      ),
    ));
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    expect(chosen, '/einstellungen');
  });

  testWidgets('Jedes aktive Ziel passt auch auf 320dp bei 150 % Schrift',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final route in [
      '/',
      '/kunden',
      '/struktur',
      '/team',
      '/einstellungen'
    ]) {
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: Scaffold(
            bottomNavigationBar: MobileAppNavigation(
          location: route,
          isCompany: true,
          isAdmin: true,
          onNavigate: (_) {},
        )),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: route);
    }
  });
}
