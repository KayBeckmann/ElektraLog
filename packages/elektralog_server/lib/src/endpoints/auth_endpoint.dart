import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';
import '../middleware/auth_middleware.dart';

class AuthEndpoint {
  final Connection db;
  AuthEndpoint(this.db);

  // POST /api/auth/register — deaktiviert, Accounts werden durch SuperAdmin angelegt
  Future<Response> register(Request request) async {
    return Response(
      403,
      body: jsonEncode({
        'error': 'Selbst-Registrierung ist deaktiviert. '
            'Bitte wenden Sie sich an Ihren Administrator.',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // POST /api/auth/login
  // Body: { "email", "passwort" }
  Future<Response> login(Request request) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String;
      final passwort = body['passwort'] as String;

      final rows = await db.execute(
        Sql.named(
          'SELECT b.id, b.firma_id, b.passwort_hash, b.name, b.ist_superadmin, '
          '       f.status AS firma_status, f.name AS firma_name, '
          '       EXISTS( '
          '         SELECT 1 FROM benutzer_rollen br '
          '         JOIN rollen r ON r.id = br.rollen_id '
          '         WHERE br.benutzer_id = b.id AND r.ist_vorlage = true '
          '       ) AS ist_admin, '
          '       ( '
          '         SELECT r.name FROM benutzer_rollen br '
          '         JOIN rollen r ON r.id = br.rollen_id '
          '         WHERE br.benutzer_id = b.id LIMIT 1 '
          '       ) AS rolle_name '
          'FROM benutzer b '
          'JOIN firmen f ON f.id = b.firma_id '
          "WHERE b.email = @email AND b.status = 'aktiv'",
        ),
        parameters: {'email': email},
      );
      if (rows.isEmpty) {
        return Response(
          401,
          body: jsonEncode({'error': 'Ungültige Anmeldedaten'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final row = rows.first;
      final storedHash = row[2] as String;
      if (!BCrypt.checkpw(passwort, storedHash)) {
        return Response(
          401,
          body: jsonEncode({'error': 'Ungültige Anmeldedaten'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Firma gesperrt? Superadmins dürfen sich trotzdem anmelden.
      final istSuperadmin = row[4] as bool? ?? false;
      final firmaStatus = row[5] as String? ?? 'aktiv';
      if (firmaStatus != 'aktiv' && !istSuperadmin) {
        return Response(
          403,
          body: jsonEncode({
            'error': 'Zugang gesperrt. '
                'Bitte wenden Sie sich an support@elektralog.de.',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final benutzerId = row[0].toString();
      final firmaId = row[1].toString();
      final name = row[3] as String;
      final firmaName = row[6] as String;
      final istAdmin = row[7] as bool? ?? false;
      final rolle = row[8] as String? ?? (istAdmin ? kRolleFirmenadmin : kRolleMonteur);
      final token = _issueToken(
          benutzerId, firmaId, email, name, istSuperadmin, istAdmin, rolle);

      return Response.ok(
        jsonEncode({
          'token': token,
          'benutzerId': benutzerId,
          'firmaId': firmaId,
          'name': name,
          'firmaName': firmaName,
          'istSuperadmin': istSuperadmin,
          'istAdmin': istAdmin,
          'rolle': rolle,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('login error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // PATCH /api/auth/me/passwort
  // Body: { "altesPasswort", "neuesPasswort" }
  Future<Response> changePassword(Request request) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht angemeldet'}),
          headers: {'Content-Type': 'application/json'});
    }
    final benutzerId = claims['sub'] as String;

    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final altesPasswort = body['altesPasswort'] as String? ?? '';
      final neuesPasswort = body['neuesPasswort'] as String? ?? '';

      if (altesPasswort.isEmpty || neuesPasswort.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'Altes und neues Passwort erforderlich'}),
            headers: {'Content-Type': 'application/json'});
      }
      if (neuesPasswort.length < 6) {
        return Response(400,
            body: jsonEncode({'error': 'Neues Passwort muss mindestens 6 Zeichen haben'}),
            headers: {'Content-Type': 'application/json'});
      }

      final rows = await db.execute(
        Sql.named('SELECT passwort_hash FROM benutzer WHERE id = @id'),
        parameters: {'id': benutzerId},
      );
      if (rows.isEmpty) {
        return Response(404,
            body: jsonEncode({'error': 'Benutzer nicht gefunden'}),
            headers: {'Content-Type': 'application/json'});
      }

      final storedHash = rows.first[0] as String;
      if (!BCrypt.checkpw(altesPasswort, storedHash)) {
        return Response(401,
            body: jsonEncode({'error': 'Aktuelles Passwort ist falsch'}),
            headers: {'Content-Type': 'application/json'});
      }

      final newHash = BCrypt.hashpw(neuesPasswort, BCrypt.gensalt());
      await db.execute(
        Sql.named('UPDATE benutzer SET passwort_hash = @hash WHERE id = @id'),
        parameters: {'hash': newHash, 'id': benutzerId},
      );

      return Response.ok(
        jsonEncode({'message': 'Passwort erfolgreich geändert'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('changePassword error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  String _issueToken(
      String id, String firmaId, String email, String name,
      bool istSuperadmin, bool istAdmin, String rolle) {
    final secret =
        Platform.environment['JWT_SECRET'] ?? 'changeme_jwt_secret';
    return JWT({
      'sub': id,
      'firmaId': firmaId,
      'email': email,
      'name': name,
      'istSuperadmin': istSuperadmin,
      'istAdmin': istAdmin,
      'rolle': rolle,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }).sign(SecretKey(secret), expiresIn: const Duration(days: 30));
  }
}
