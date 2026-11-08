@Tags(['postgres'])
library;

import 'dart:io';

import 'package:elektralog_server/src/migrations.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

/// Migrationsläufer gegen echtes Postgres: Neuinstallation, Altbestand
/// aus der initdb-Zeit (ohne Versionstabelle), fehlgeschlagene und
/// nachträglich veränderte Migration.
void main() {
  group('Migrationsläufer', skip: skipWithoutDb, () {
    late Connection db;
    late Directory dir;

    setUp(() async {
      db = await openEmptyTestDb();
      dir = Directory.systemTemp.createTempSync('elektralog-migrations-');
      for (final f in Directory('migrations').listSync().whereType<File>()) {
        f.copySync('${dir.path}/${f.uri.pathSegments.last}');
      }
    });
    tearDown(() async {
      await db.close();
      dir.deleteSync(recursive: true);
    });

    Migrator migrator() => Migrator(db, directory: dir.path, log: (_) {});
    List<String> alle() => [
          for (final f in dir.listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList()..sort())
            f.replaceFirst('.sql', ''),
        ];
    Future<List<String>> versionen() async =>
        [for (final r in await db.execute('SELECT version FROM schema_migrations ORDER BY version')) r[0] as String];

    /// Wie früher `docker-entrypoint-initdb.d`: Dateien roh einspielen,
    /// ohne Versionstabelle.
    Future<void> altbestand(String bisEinschliesslich) async {
      for (final name in alle().where((n) => n.compareTo(bisEinschliesslich) <= 0)) {
        await db.execute(File('${dir.path}/$name.sql').readAsStringSync(), queryMode: QueryMode.simple);
      }
    }

    Future<int> anzahl(String sql) async => (await db.execute(sql)).first[0] as int;

    test('Neue Datenbank: alle Migrationen laufen, zweiter Start ändert nichts', () async {
      expect(await migrator().run(), alle());
      expect(await versionen(), alle());
      expect(await migrator().run(), isEmpty);
    });

    test('Altbestand mit allen Migrationen: wird übernommen, Daten bleiben unverändert', () async {
      await altbestand('008_sync_revision');
      await db.execute("INSERT INTO firmen (name) VALUES ('Firma A')");
      await db.execute(File('${dir.path}/006_default_rollen.sql').readAsStringSync(), queryMode: QueryMode.simple);
      final rollenVorher = await anzahl('SELECT count(*)::int FROM rollen');

      // Nur die idempotente 006 läuft erneut, sonst nichts.
      expect(await migrator().run(), ['006_default_rollen']);
      expect(await versionen(), alle());
      expect(await anzahl('SELECT count(*)::int FROM rollen'), rollenVorher, reason: 'keine doppelten Rollen');
      expect(await anzahl('SELECT count(*)::int FROM firmen'), 1);
    });

    test('Altbestand ohne 007/008: fehlende Migrationen werden nachgezogen', () async {
      await altbestand('006_default_rollen');
      await db.execute("INSERT INTO firmen (name) VALUES ('Firma A')");

      final angewendet = await migrator().run();
      expect(angewendet, containsAll(['007_firma_adresse', '008_sync_revision']));
      expect(angewendet, isNot(contains('005_aktualisiert_am')));
      expect(await anzahl('SELECT sync_revision::int FROM firmen'), 0);
      expect(await versionen(), alle());
    });

    test('Fehlgeschlagene Migration: Datenbank unverändert, später reparierte Datei läuft', () async {
      await migrator().run();
      File('${dir.path}/999_kaputt.sql').writeAsStringSync('''
        ALTER TABLE firmen ADD COLUMN probe TEXT;
        SELECT * FROM gibt_es_nicht;
      ''');

      await expectLater(migrator().run(), throwsA(isA<MigrationException>()));
      expect(await versionen(), isNot(contains('999_kaputt')));
      expect(
        await anzahl("SELECT count(*)::int FROM information_schema.columns WHERE table_name = 'firmen' AND column_name = 'probe'"),
        0,
        reason: 'halbe Migration zurückgerollt',
      );

      File('${dir.path}/999_kaputt.sql').writeAsStringSync('ALTER TABLE firmen ADD COLUMN probe TEXT;');
      expect(await migrator().run(), ['999_kaputt']);
    });

    test('Nachträglich veränderte Migration bricht den Start ab', () async {
      await migrator().run();
      File('${dir.path}/007_firma_adresse.sql').writeAsStringSync('-- geändert\n', mode: FileMode.append);
      await expectLater(
        migrator().run(),
        throwsA(isA<MigrationException>().having((e) => e.message, 'message', contains('007_firma_adresse'))),
      );
    });
  });
}
