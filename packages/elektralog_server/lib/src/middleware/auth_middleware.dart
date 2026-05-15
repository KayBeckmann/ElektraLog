import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';

Middleware corsMiddleware() => (handler) => (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await handler(request);
      return response.change(headers: _corsHeaders);
    };

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

/// Verifiziert den JWT aus dem Authorization-Header.
/// Gibt die Claims zurück oder null bei ungültigem Token.
Map<String, dynamic>? verifyJwt(Request request) {
  final auth = request.headers['authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  final token = auth.substring(7);
  try {
    final secret =
        Platform.environment['JWT_SECRET'] ?? 'changeme_jwt_secret';
    final jwt = JWT.verify(token, SecretKey(secret));
    return jwt.payload as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Middleware: Prüft bei jeder authentifizierten Anfrage ob die Firma
/// noch aktiv ist. Gesperrte Firmen erhalten 403, auch mit gültigem JWT.
///
/// Öffentliche Routen (kein Authorization-Header) werden durchgeleitet.
Middleware firmaSperreMiddleware(Connection db) =>
    (handler) => (request) async {
          final auth = request.headers['authorization'];
          if (auth == null || !auth.startsWith('Bearer ')) {
            return handler(request);
          }
          final claims = verifyJwt(request);
          if (claims == null) return handler(request);

          final firmaId = claims['firmaId'] as String?;
          if (firmaId == null) return handler(request);

          try {
            final rows = await db.execute(
              Sql.named('SELECT status FROM firmen WHERE id = @id'),
              parameters: {'id': firmaId},
            );
            if (rows.isEmpty || rows.first[0] != 'aktiv') {
              return Response(
                403,
                body: jsonEncode({
                  'error': 'Zugang gesperrt. '
                      'Bitte wenden Sie sich an support@elektralog.de.',
                }),
                headers: {'Content-Type': 'application/json'},
              );
            }
          } catch (e) {
            // DB-Fehler → sicherheitshalber blockieren
            return Response.internalServerError(
              body: jsonEncode({'error': 'Authentifizierungsfehler'}),
              headers: {'Content-Type': 'application/json'},
            );
          }

          return handler(request);
        };

/// Prüft ob die Claims einen Superadmin ausweisen.
/// Gibt 403 zurück wenn nicht; null bei Erfolg (Response nur bei Fehler).
Response? requireSuperadmin(Map<String, dynamic>? claims) {
  if (claims == null) {
    return Response(
      401,
      body: jsonEncode({'error': 'Nicht authentifiziert'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
  if (claims['istSuperadmin'] != true) {
    return Response(
      403,
      body: jsonEncode({'error': 'Keine Superadmin-Berechtigung'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
  return null;
}
