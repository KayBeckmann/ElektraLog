import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../lib/src/app.dart';
import '../lib/src/config.dart';
import '../lib/src/db.dart';

void main() async {
  final config = ServerConfig.fromEnv();
  final conn = await openDb(config);

  await ensureSuperadmin(conn);

  final handler = buildHandler(conn, jwtSecret: config.jwtSecret);

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    config.port,
  );
  print('ElektraLog Server running on port ${server.port}');
}
