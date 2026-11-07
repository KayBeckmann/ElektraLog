import 'dart:convert';
import 'dart:io';

import 'package:elektralog_server/src/app.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

/// Test-Postgres aus `ELEKTRALOG_TEST_DB=host:port:db:user:passwort`,
/// z. B. `localhost:55434:test:test:test`. Ohne die Variable werden die
/// Server-Tests übersprungen statt gegen eine echte Datenbank zu laufen.
final String? testDbSpec = Platform.environment['ELEKTRALOG_TEST_DB'];

/// Grund zum Überspringen (für `group(..., skip: ...)`), `false` = laufen.
Object get skipWithoutDb => testDbSpec == null ? 'ELEKTRALOG_TEST_DB nicht gesetzt' : false;

const superadminEmail = 'superadmin@test.invalid';
const superadminPassword = 'superadmin-passwort';

/// Echter Server-Handler gegen eine frisch migrierte Test-Datenbank.
/// Die Datenbank wird bei [start] komplett geleert — nie auf eine
/// produktive Datenbank zeigen lassen.
class TestServer {
  late Connection db;
  late Handler handler;

  Future<void> start() async {
    final parts = testDbSpec!.split(':');
    db = await Connection.open(
      Endpoint(
        host: parts[0],
        port: int.parse(parts[1]),
        database: parts[2],
        username: parts[3],
        password: parts[4],
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    await db.execute('DROP SCHEMA public CASCADE; CREATE SCHEMA public;', queryMode: QueryMode.simple);
    await applyMigrations(db);
    await ensureSuperadmin(db, email: superadminEmail, password: superadminPassword);
    handler = buildHandler(db, logRequests: false);
  }

  Future<void> stop() => db.close();

  /// Ruft den Handler direkt auf (ohne Socket) und liefert Status + JSON.
  Future<({int status, dynamic body})> call(String method, String path, {Object? body, String? token}) async {
    final response = await handler(Request(
      method,
      Uri.parse('http://localhost$path'),
      body: body == null ? null : jsonEncode(body),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      },
    ));
    final text = await response.readAsString();
    dynamic decoded;
    try {
      decoded = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      decoded = text;
    }
    return (status: response.statusCode, body: decoded);
  }

  Future<String> login(String email, String passwort) async {
    final r = await call('POST', '/api/auth/login', body: {'email': email, 'passwort': passwort});
    if (r.status != 200) throw StateError('Login $email fehlgeschlagen: ${r.status} ${r.body}');
    return (r.body as Map)['token'] as String;
  }

  /// Legt über die Superadmin-API eine Firma samt Benutzer an und
  /// liefert dessen Token und die Firmen-ID.
  Future<({String token, String firmaId})> firmaMitBenutzer(String firmaName, String email) async {
    final admin = await login(superadminEmail, superadminPassword);
    final firma = await call('POST', '/api/admin/firmen', body: {'name': firmaName}, token: admin);
    final firmaId = (firma.body as Map)['id'] as String;
    final benutzer = await call(
      'POST',
      '/api/admin/firmen/$firmaId/benutzer',
      body: {'email': email, 'passwort': 'passwort-12345', 'name': firmaName},
      token: admin,
    );
    if (benutzer.status != 200) throw StateError('Benutzer anlegen: ${benutzer.status} ${benutzer.body}');
    return (token: await login(email, 'passwort-12345'), firmaId: firmaId);
  }
}

/// Spielt alle SQL-Migrationen in Dateireihenfolge ein — dieselben
/// Dateien, die `docker-compose.yml` beim ersten Start der Datenbank lädt.
Future<void> applyMigrations(Connection db) async {
  final files = Directory('migrations').listSync().whereType<File>().where((f) => f.path.endsWith('.sql')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    await db.execute(file.readAsStringSync(), queryMode: QueryMode.simple);
  }
}
