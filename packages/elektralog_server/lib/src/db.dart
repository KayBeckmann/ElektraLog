import 'package:postgres/postgres.dart';
import 'config.dart';

Future<Connection> openDb(ServerConfig config) async {
  final conn = await Connection.open(
    Endpoint(
      host: config.dbHost,
      port: config.dbPort,
      database: config.dbName,
      username: config.dbUser,
      password: config.dbPassword,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );
  return conn;
}
