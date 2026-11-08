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
        jwtSecret: _requireJwtSecret(),
      );

  /// Ohne JWT_SECRET startet der Server nicht. Früher galt still ein
  /// bekannter Standardwert — damit hätte jeder gültige Tokens signieren
  /// können.
  static String _requireJwtSecret() {
    final secret = Platform.environment['JWT_SECRET'] ?? '';
    if (secret.isEmpty) {
      throw StateError('JWT_SECRET ist nicht gesetzt — Server startet nicht.');
    }
    if (secret.length < 32 || secret.startsWith('changeme')) {
      print('WARNUNG: JWT_SECRET ist kurz oder ein Beispielwert — '
          'bitte durch einen zufälligen Wert (mind. 32 Zeichen) ersetzen.');
    }
    return secret;
  }
}
