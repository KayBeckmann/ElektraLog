import 'package:elektralog/core/database/isar_service.dart';
import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/messung.dart';
import 'package:elektralog/core/models/standort.dart';
import 'package:elektralog/core/models/verteiler.dart';
import 'package:elektralog/core/models/verteiler_komponente.dart';
import 'package:elektralog/core/providers/sync_auswahl_provider.dart';
import 'package:elektralog/core/sync/sync_bereiche.dart';
import 'package:elektralog/core/sync/sync_engine.dart';
import 'package:elektralog/core/sync/sync_meta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

/// Download nur für die Auswahl; Abgewähltes verschwindet vom Gerät, sobald
/// es vollständig auf dem Server liegt; der Bestand vor dem Update bleibt.
void main() {
  setUpAll(disableSembastCooperator);
  var n = 0;
  late Database db;
  late SyncAuswahlRepository auswahl;

  /// Speichert den Datensatz so, als wäre er bereits synchronisiert.
  Future<void> synchron(String typ, Map<String, dynamic> json) async {
    final def = syncTypDef(typ)!;
    final norm = def.normalisiere(json);
    await def.store.record(norm['uuid'] as String).put(db, norm.cast<String, Object?>());
    await SyncMetaRepository(db).set(typ, norm['uuid'] as String, SyncMeta(version: 1, hash: inhaltsHash(norm)));
  }

  Future<Set<String>> lokal(String typ) async => (await syncTypDef(typ)!.store.findKeys(db)).toSet();

  Messung messung(String uuid, String komponente) => Messung(
      uuid: uuid,
      komponenteUuid: komponente,
      norm: 'vde_0100',
      pruefungDatum: DateTime.utc(2026, 11, 8),
      ergebnis: 'bestanden');

  setUp(() async {
    db = await databaseFactoryMemory.openDatabase('bereiche-${n++}.db');
    auswahl = SyncAuswahlRepository(db);
    await synchron('standorte', Standort(uuid: 's1', kundeUuid: 'k1', bezeichnung: 'Werk').toJson());
    await synchron('standorte', Standort(uuid: 's2', kundeUuid: 'k2', bezeichnung: 'Fremd').toJson());
    await synchron('verteiler', Verteiler(uuid: 'v1', standortUuid: 's1', bezeichnung: 'UV1').toJson());
    await synchron('verteiler', Verteiler(uuid: 'v2', standortUuid: 's2', bezeichnung: 'UV2').toJson());
    for (final (k, v) in [('kA', 'v1'), ('kB', 'v2')]) {
      await synchron(
          'komponenten', VerteilerKomponente(uuid: k, verteilerUuid: v, typ: 'rcd', zielbezeichnung: 'FI').toJson());
    }
    await synchron('messungen', messung('m1', 'kA').toJson());
    await synchron('messungen', messung('m2', 'kB').toJson());
    await synchron('geraete',
        Geraet(uuid: 'g1', kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'r1', bezeichnung: 'Lampe').toJson());
  });

  test('erster Lauf nach dem Update: vorhandener Bestand bleibt und ist ausgewählt', () async {
    expect(await abgewaehltesEntfernen(db), 0);
    expect(await lokal('messungen'), {'m1', 'm2'});
    expect(await auswahl.getAktivierteVerteilerUuids(), {'v1', 'v2'});
    expect(await auswahl.getAktivierteRaumUuids(), {'r1'});
  });

  group('nach dem ersten Lauf', () {
    setUp(() async {
      await abgewaehltesEntfernen(db);
      for (final v in ['v1', 'v2']) {
        await auswahl.setVerteilerAktiviert(v, false);
      }
      await auswahl.setRaumAktiviert('r1', false);
    });

    test('Abgewähltes und Hochgeladenes verschwindet, Basisdaten bleiben', () async {
      await auswahl.setVerteilerAktiviert('v1', true);
      expect(await abgewaehltesEntfernen(db), 3, reason: 'kB, m2, g1');
      expect(await lokal('komponenten'), {'kA'});
      expect(await lokal('messungen'), {'m1'});
      expect(await lokal('geraete'), isEmpty);
      expect(await lokal('verteiler'), {'v1', 'v2'}, reason: 'Namen bleiben zum Auswählen');
      expect(await SyncMetaRepository(db).get('messungen', 'm2'), isNull);
    });

    test('ungesendete Änderungen und neue Datensätze bleiben', () async {
      final def = syncTypDef('messungen')!;
      await def.store.record('m2').put(db, messung('m2', 'kB').copyWith(bemerkung: 'offline').toJson().cast());
      await def.store.record('m3').put(db, messung('m3', 'kB').toJson().cast());
      await abgewaehltesEntfernen(db);
      expect(await lokal('messungen'), {'m2', 'm3'});
    });

    test('ganzer Kunde deckt Anlagen und Geräte seiner Standorte ab', () async {
      await auswahl.setKundeAktiviert('k1', true);
      await abgewaehltesEntfernen(db);
      expect(await lokal('messungen'), {'m1'});
      expect(await lokal('geraete'), {'g1'});
    });

    test('wo gearbeitet wird, bleibt der Bereich ausgewählt', () async {
      await bereicheAuswaehlen(db, [('messungen', messung('m9', 'kB').toJson().cast())]);
      expect(await auswahl.getAktivierteVerteilerUuids(), {'v2'});
      await bereicheAuswaehlen(db, [
        (
          'geraete',
          Geraet(uuid: 'g2', kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'r7', bezeichnung: 'X').toJson().cast()
        ),
      ]);
      expect(await auswahl.getAktivierteRaumUuids(), {'r7'});
    });
  });
}
