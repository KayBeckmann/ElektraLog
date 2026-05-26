import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/src/config.dart';
import '../lib/src/middleware/auth_middleware.dart';
import '../lib/src/endpoints/auth_endpoint.dart';
import '../lib/src/endpoints/kunden_endpoint.dart';
import '../lib/src/endpoints/mandanten_endpoint.dart';
import '../lib/src/endpoints/protokoll_endpoint.dart';
import '../lib/src/db.dart';

void main() async {
  final config = ServerConfig.fromEnv();
  final conn = await openDb(config);

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
