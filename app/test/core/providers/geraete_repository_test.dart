import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/raum.dart';
import 'package:elektralog/core/providers/geraete_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M2: lokale Speicherung (offline) von Räumen und Geräten.
void main() {
  var n = 0;
  late RaeumeRepository raeume;
  late GeraeteRepository geraete;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = await databaseFactoryMemory.openDatabase('geraete-${n++}.db');
    raeume = RaeumeRepository(db);
    geraete = GeraeteRepository(db);
  });

  test('Offline anlegen und wiederfinden, UUID bleibt gleich', () async {
    final raum = Raum(standortUuid: 's', bezeichnung: 'Büro');
    await raeume.save(raum);
    final g = Geraet.neu(kundeUuid: 'k', standortUuid: 's', raumUuid: raum.uuid, bezeichnung: 'Lampe');
    await geraete.save(g);

    final gefunden = await geraete.getByUuid(g.uuid);
    expect(gefunden?.toJson(), g.toJson());
    expect(await geraete.watchByRaum(raum.uuid).first, hasLength(1));
    expect(await raeume.getByStandort('s'), hasLength(1));
  });

  test('Ungültige Geräte und Räume werden nicht gespeichert', () async {
    await expectLater(
      geraete.save(Geraet(kundeUuid: 'k', standortUuid: 's', raumUuid: '', bezeichnung: 'X')),
      throwsArgumentError,
    );
    await expectLater(raeume.save(Raum(standortUuid: 's', bezeichnung: ' ')), throwsArgumentError);
    expect(await geraete.getAlle(), isEmpty);
  });

  test('Raum mit Gerät lässt sich nicht löschen, leerer schon', () async {
    final voll = Raum(standortUuid: 's', bezeichnung: 'A');
    final leer = Raum(standortUuid: 's', bezeichnung: 'B');
    await raeume.save(voll);
    await raeume.save(leer);
    await geraete.save(Geraet.neu(kundeUuid: 'k', standortUuid: 's', raumUuid: voll.uuid, bezeichnung: 'G'));

    expect(await raeume.deleteWennLeer(voll.uuid), isFalse);
    expect(await raeume.deleteWennLeer(leer.uuid), isTrue);
    expect((await raeume.getByStandort('s')).map((r) => r.bezeichnung), ['A']);
  });
}
