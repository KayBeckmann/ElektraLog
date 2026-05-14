import 'dart:io';

class ServerConfig {
  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUser;
  final String dbPassword;
  final int port;
  final String jwtSecret;

  const ServerConfig({
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUser,
    required this.dbPassword,
    required this.port,
    required this.jwtSecret,
  });

  factory ServerConfig.fromEnv() => ServerConfig(
        dbHost: Platform.environment['POSTGRES_HOST'] ?? 'localhost',
        dbPort:
            int.parse(Platform.environment['POSTGRES_PORT'] ?? '5432'),
        dbName: Platform.environment['POSTGRES_DB'] ?? 'elektralog',
        dbUser: Platform.environment['POSTGRES_USER'] ?? 'elektralog',
        dbPassword: Platform.environment['POSTGRES_PASSWORD'] ?? '',
        port: int.parse(Platform.environment['SERVERPOD_PORT'] ?? '8080'),
        jwtSecret:
            Platform.environment['JWT_SECRET'] ?? 'changeme_jwt_secret',
      );
}
