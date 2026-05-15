import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/src/config.dart';
import '../lib/src/middleware/auth_middleware.dart';
import '../lib/src/endpoints/auth_endpoint.dart';
import '../lib/src/endpoints/kunden_endpoint.dart';
import '../lib/src/endpoints/mandanten_endpoint.dart';
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
        (req, id) => MandantenEndpoint(conn).updateStatus(req, id));

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
