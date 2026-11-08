import 'dart:convert';
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

String? _jwtSecret;

/// Schlüssel zum Signieren und Prüfen der JWTs. Wird einmal beim Start
/// aus [ServerConfig] gesetzt (siehe [buildHandler]) — kein Fallback auf
/// einen bekannten Standardwert, sonst könnte jeder Tokens fälschen.
String get jwtSecret =>
    _jwtSecret ?? (throw StateError('JWT-Secret nicht konfiguriert'));
void setJwtSecret(String value) {
  if (value.isEmpty) throw ArgumentError('JWT-Secret darf nicht leer sein');
  _jwtSecret = value;
}

/// Verifiziert den JWT aus dem Authorization-Header.
/// Gibt die Claims zurück oder null bei ungültigem Token.
///
/// Loggt bewusst nichts: Header und Token gehören nie ins Log, wer die
/// Container-Logs lesen kann, könnte sich sonst als jeder Nutzer anmelden.
Map<String, dynamic>? verifyJwt(Request request) {
  final auth = request.headers['authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  try {
    final jwt = JWT.verify(auth.substring(7), SecretKey(jwtSecret));
    return jwt.payload as Map<String, dynamic>;
  } catch (_) {
    // Ungültig, abgelaufen oder kaputt formatiert — Grund nicht loggen.
    return null;
  }
}

/// Middleware: Prüft bei jeder authentifizierten Anfrage ob die Firma
/// noch aktiv ist. Gesperrte Firmen erhalten 403, auch mit gültigem JWT.
///
/// Öffentliche Routen (kein Authorization-Header) werden durchgeleitet.
Middleware firmaSperreMiddleware(Pool db) =>
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

/// Die drei vergebbaren Rollennamen pro Firma (siehe Migration 006).
const kRolleFirmenadmin = 'Firmenadmin';
const kRolleProjektleiter = 'Projektleiter';
const kRolleMonteur = 'Monteur';
const kBekannteRollen = [kRolleFirmenadmin, kRolleProjektleiter, kRolleMonteur];

/// Liest die Rolle aus den JWT-Claims. Ältere Tokens ohne 'rolle'-Claim
/// fallen auf Firmenadmin/Monteur zurück, je nach 'istAdmin'-Claim.
String rolleVon(Map<String, dynamic> claims) =>
    claims['rolle'] as String? ??
    (claims['istAdmin'] == true ? kRolleFirmenadmin : kRolleMonteur);

/// Firmenadmin und Projektleiter dürfen Stammdaten uneingeschränkt anlegen,
/// bearbeiten und löschen (siehe Obsidian-Inbox "Rollen"-Notiz).
bool hatVollzugriff(Map<String, dynamic> claims) {
  final rolle = rolleVon(claims);
  return rolle == kRolleFirmenadmin || rolle == kRolleProjektleiter;
}

/// Prüft ob die Claims einen Firmenadmin ausweisen.
/// Gibt 403 zurück wenn nicht; null bei Erfolg (Response nur bei Fehler).
Response? requireAdmin(Map<String, dynamic>? claims) {
  if (claims == null) {
    return Response(
      401,
      body: jsonEncode({'error': 'Nicht authentifiziert'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
  if (claims['istAdmin'] != true) {
    return Response(
      403,
      body: jsonEncode({'error': 'Keine Berechtigung (nur für Admins)'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
  return null;
}

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
