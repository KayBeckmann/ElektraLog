import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

/// Migrationsläufer: spielt `migrations/*.sql` beim Serverstart in
/// Dateireihenfolge ein und merkt sich in `schema_migrations`, was schon
/// angewendet ist.
///
/// Regeln:
/// - Nur vorwärts. Eine angewendete Datei wird nie mehr geändert — eine
///   Änderung (Prüfsumme) bricht den Start ab. Korrekturen kommen als
///   neue Datei.
/// - Jede Datei läuft in einer eigenen Transaktion. Schlägt sie fehl,
///   bleibt die Datenbank auf dem Stand davor und der Server startet nicht.
/// - Rückweg ist das Backup (`docker/postgres/backup.sh`) vor dem Update,
///   kein Down-Skript.
///
/// Datenbanken aus der Zeit vor dem Läufer (Schema per
/// `docker-entrypoint-initdb.d` angelegt) haben keine Versionstabelle.
/// Für sie wird anhand des vorhandenen Schemas erkannt, welche der alten
/// Dateien bereits gelaufen sind ([_legacyMarkers]).
class Migrator {
  Migrator(this.db, {String? directory, void Function(String)? log})
      : directory = directory ?? Platform.environment['MIGRATIONS_DIR'] ?? 'migrations',
        _log = log ?? print;

  final Connection db;
  final String directory;
  final void Function(String) _log;

  /// Beliebige, feste Nummer für `pg_advisory_lock` — verhindert, dass
  /// zwei gleichzeitig startende Server dieselbe Migration ausführen.
  static const _lockId = 4711008001;

  /// Alte Migrationen und woran man erkennt, dass sie schon gelaufen sind.
  /// `006_default_rollen` fehlt absichtlich: sie ist idempotent und läuft
  /// auf Altbeständen einfach noch einmal.
  static final _legacyMarkers = {
    '001_initial': "SELECT to_regclass('public.firmen') IS NOT NULL",
    '002_seed_permissions': 'SELECT EXISTS (SELECT 1 FROM berechtigungen)',
    '003_superadmin': _columnExists('benutzer', 'ist_superadmin'),
    '004_protokolle': "SELECT to_regclass('public.protokolle') IS NOT NULL",
    '005_aktualisiert_am': "SELECT to_regclass('public.sichtpruefungen') IS NOT NULL",
    '007_firma_adresse': _columnExists('firmen', 'strasse'),
    '008_sync_revision': _columnExists('firmen', 'sync_revision'),
  };

  /// Führt alle ausstehenden Migrationen aus und liefert deren Namen.
  Future<List<String>> run() async {
    final files = _files();
    await db.execute('SELECT pg_advisory_lock($_lockId)');
    try {
      await _ensureVersionTable(files);
      final applied = await _applied();

      for (final name in applied.keys) {
        final file = files[name];
        if (file == null) {
          _log('WARNUNG: Migration $name ist angewendet, aber nicht im Server enthalten '
              '— läuft eine ältere Server-Version gegen eine neuere Datenbank?');
        } else if (file.checksum != applied[name]) {
          throw MigrationException(
              'Migration $name wurde nach dem Anwenden verändert (Prüfsumme weicht ab). '
              'Angewendete Migrationen nie ändern — Korrektur als neue Datei anlegen.');
        }
      }

      final pending = [for (final name in files.keys) if (!applied.containsKey(name)) name];
      for (final name in pending) {
        final file = files[name]!;
        _log('Migration $name wird angewendet …');
        try {
          await db.runTx((tx) async {
            await tx.execute(file.sql, queryMode: QueryMode.simple);
            await tx.execute(
              Sql.named('INSERT INTO schema_migrations (version, pruefsumme) VALUES (@v, @c)'),
              parameters: {'v': name, 'c': file.checksum},
            );
          });
        } catch (e) {
          throw MigrationException('Migration $name fehlgeschlagen, Datenbank unverändert: $e');
        }
      }
      if (pending.isEmpty) _log('Datenbankschema aktuell (${files.length} Migrationen).');
      return pending;
    } finally {
      await db.execute('SELECT pg_advisory_unlock($_lockId)');
    }
  }

  Map<String, _MigrationFile> _files() {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      throw MigrationException('Migrationsverzeichnis "$directory" fehlt.');
    }
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.sql')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return {
      for (final f in files)
        f.uri.pathSegments.last.replaceFirst(RegExp(r'\.sql$'), ''): _MigrationFile(f.readAsStringSync()),
    };
  }

  Future<void> _ensureVersionTable(Map<String, _MigrationFile> files) async {
    final exists = await _bool("SELECT to_regclass('public.schema_migrations') IS NOT NULL");
    if (exists) return;
    final legacy = await _bool("SELECT to_regclass('public.firmen') IS NOT NULL");

    await db.runTx((tx) async {
      await tx.execute('''
        CREATE TABLE schema_migrations (
          version TEXT PRIMARY KEY,
          pruefsumme TEXT NOT NULL,
          angewendet_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )''');
      if (!legacy) return;
      for (final entry in _legacyMarkers.entries) {
        final file = files[entry.key];
        if (file == null) continue;
        final rows = await tx.execute(entry.value);
        if (rows.first[0] != true) continue;
        await tx.execute(
          Sql.named('INSERT INTO schema_migrations (version, pruefsumme) VALUES (@v, @c)'),
          parameters: {'v': entry.key, 'c': file.checksum},
        );
        _log('Altbestand: ${entry.key} als bereits angewendet übernommen.');
      }
    });
  }

  Future<Map<String, String>> _applied() async {
    final rows = await db.execute('SELECT version, pruefsumme FROM schema_migrations ORDER BY version');
    return {for (final r in rows) r[0] as String: r[1] as String};
  }

  Future<bool> _bool(String sql) async => (await db.execute(sql)).first[0] == true;
}

String _columnExists(String table, String column) =>
    "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' "
    "AND table_name = '$table' AND column_name = '$column')";

class _MigrationFile {
  _MigrationFile(this.sql) : checksum = sha256.convert(utf8.encode(sql.replaceAll('\r\n', '\n'))).toString();
  final String sql;
  final String checksum;
}

class MigrationException implements Exception {
  MigrationException(this.message);
  final String message;
  @override
  String toString() => message;
}
