import 'package:postgres/postgres.dart';
import 'config.dart';

Endpoint _endpoint(ServerConfig config) => Endpoint(
      host: config.dbHost,
      port: config.dbPort,
      database: config.dbName,
      username: config.dbUser,
      password: config.dbPassword,
    );

/// Einzelne Verbindung für Migrationen und Start (Advisory-Lock gilt je
/// Sitzung) — danach schließen.
Future<Connection> openDb(ServerConfig config) => Connection.open(
      _endpoint(config),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

/// Verbindungspool für den laufenden Betrieb (parallele Anfragen).
Pool openPool(ServerConfig config) => Pool.withEndpoints(
      [_endpoint(config)],
      settings: const PoolSettings(maxConnectionCount: 6, sslMode: SslMode.disable),
    );
