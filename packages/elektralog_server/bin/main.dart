import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../lib/src/app.dart';
import '../lib/src/config.dart';
import '../lib/src/db.dart';
import '../lib/src/migrations.dart';

void main() async {
  final config = ServerConfig.fromEnv();
  final conn = await openDb(config);

  // Schema vor allem anderen nachziehen — schlägt eine Migration fehl,
  // startet der Server nicht (Datenbank bleibt auf dem alten Stand).
  await Migrator(conn).run();
  await ensureSuperadmin(conn);
  await conn.close();

  final handler = buildHandler(openPool(config), jwtSecret: config.jwtSecret);

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    config.port,
  );
  print('ElektraLog Server running on port ${server.port}');
}
