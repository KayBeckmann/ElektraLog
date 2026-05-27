import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';
import '../lib/src/config.dart';
import '../lib/src/middleware/auth_middleware.dart';
import '../lib/src/endpoints/auth_endpoint.dart';
import '../lib/src/endpoints/kunden_endpoint.dart';
import '../lib/src/endpoints/mandanten_endpoint.dart';
import '../lib/src/endpoints/protokoll_endpoint.dart';
import '../lib/src/endpoints/firma_endpoint.dart';
import '../lib/src/db.dart';

/// Legt den Superadmin beim ersten Start an, falls noch keiner existiert.
/// Liest E-Mail und Passwort aus den Env-Vars SUPERADMIN_EMAIL / SUPERADMIN_PASSWORD.
/// Wird bei jedem Neustart geprüft — existiert bereits ein Superadmin, passiert nichts.
Future<void> _ensureSuperadmin(Connection conn) async {
  final email    = Platform.environment['SUPERADMIN_EMAIL'];
  final password = Platform.environment['SUPERADMIN_PASSWORD'];

  if (email == null || email.isEmpty || password == null || password.isEmpty) {
    print('SUPERADMIN_EMAIL/SUPERADMIN_PASSWORD nicht gesetzt — Seed übersprungen.');
    return;
  }

  final existing = await conn.execute(
    Sql.named('SELECT id FROM benutzer WHERE ist_superadmin = true LIMIT 1'),
  );
  if (existing.isNotEmpty) {
    print('Superadmin bereits vorhanden — kein Seed nötig.');
    return;
  }

  final firmaId     = const Uuid().v4();
  final benutzerId  = const Uuid().v4();
  final hash        = BCrypt.hashpw(password, BCrypt.gensalt());

  await conn.runTx((ctx) async {
    await ctx.execute(
      Sql.named('INSERT INTO firmen (id, name) VALUES (@id, @name)'),
      parameters: {'id': firmaId, 'name': '_ElektraLog-System_'},
    );
    await ctx.execute(
      Sql.named(
        'INSERT INTO benutzer '
        '(id, firma_id, email, passwort_hash, name, ist_superadmin) '
        'VALUES (@id, @fid, @email, @hash, @name, true)',
      ),
      parameters: {
        'id':    benutzerId,
        'fid':   firmaId,
        'email': email,
        'hash':  hash,
        'name':  'SuperAdmin',
      },
    );
  });

  print('Superadmin angelegt: $email');
}

void main() async {
  final config = ServerConfig.fromEnv();
  final conn = await openDb(config);

  await _ensureSuperadmin(conn);

  final router = Router()
    // Health check (public)
    ..get('/api/health', (_) => Response.ok('{"status":"ok"}',
        headers: {'Content-Type': 'application/json'}))
    // Auth (public)
    ..post('/api/auth/register', (req) => AuthEndpoint(conn).register(req))
    ..post('/api/auth/login', (req) => AuthEndpoint(conn).login(req))
    // Kunden (requires JWT)
    ..get('/api/kunden', (req) => KundenEndpoint(conn).list(req))
    ..post('/api/kunden', (req) => KundenEndpoint(conn).create(req))
    ..put('/api/kunden/<uuid>',
        (req, uuid) => KundenEndpoint(conn).update(req, uuid))
    ..delete('/api/kunden/<uuid>',
        (req, uuid) => KundenEndpoint(conn).delete(req, uuid))
    // Sync endpoint
    ..post('/api/sync', (req) => KundenEndpoint(conn).sync(req))
    // Mandanten (Superadmin only)
    ..get('/api/admin/firmen', (req) => MandantenEndpoint(conn).list(req))
    ..post('/api/admin/firmen', (req) => MandantenEndpoint(conn).create(req))
    ..patch('/api/admin/firmen/<id>/status',
        (req, id) => MandantenEndpoint(conn).updateStatus(req, id))
    ..get('/api/admin/firmen/<id>/benutzer',
        (req, id) => MandantenEndpoint(conn).listBenutzer(req, id))
    ..post('/api/admin/firmen/<id>/benutzer',
        (req, id) => MandantenEndpoint(conn).createBenutzer(req, id))
    ..patch('/api/admin/benutzer/<id>/status',
        (req, id) => MandantenEndpoint(conn).updateBenutzerStatus(req, id))
    ..delete('/api/admin/benutzer/<id>',
        (req, id) => MandantenEndpoint(conn).deleteBenutzer(req, id))
    // Firma-eigene Benutzerverwaltung (jeder eingeloggte Company-User)
    ..get('/api/firma/benutzer',
        (req) => FirmaEndpoint(conn).listBenutzer(req))
    ..post('/api/firma/benutzer',
        (req) => FirmaEndpoint(conn).createBenutzer(req))
    ..patch('/api/firma/benutzer/<id>',
        (req, id) => FirmaEndpoint(conn).updateBenutzer(req, id))
    ..patch('/api/firma/benutzer/<id>/status',
        (req, id) => FirmaEndpoint(conn).updateBenutzerStatus(req, id))
    ..patch('/api/firma/benutzer/<id>/rolle',
        (req, id) => FirmaEndpoint(conn).updateBenutzerRolle(req, id))
    ..delete('/api/firma/benutzer/<id>',
        (req, id) => FirmaEndpoint(conn).deleteBenutzer(req, id))
    // Protokoll-Archiv (append-only, rechtssicher)
    ..post('/api/protokolle', (req) => ProtokollEndpoint(conn).create(req))
    ..get('/api/protokolle', (req) => ProtokollEndpoint(conn).list(req))
    ..get('/api/protokolle/<id>',
        (req, id) => ProtokollEndpoint(conn).get(req, id))
    ..get('/api/protokolle/<id>/pdf',
        (req, id) => ProtokollEndpoint(conn).getPdf(req, id));

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addMiddleware(firmaSperreMiddleware(conn))
      .addHandler(router.call);

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    config.port,
  );
  print('ElektraLog Server running on port ${server.port}');
}
