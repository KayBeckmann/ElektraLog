import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';

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
          '       ) AS ist_admin '
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
      final token = _issueToken(benutzerId, firmaId, email, name, istSuperadmin, istAdmin);

      return Response.ok(
        jsonEncode({
          'token': token,
          'benutzerId': benutzerId,
          'firmaId': firmaId,
          'name': name,
          'firmaName': firmaName,
          'istSuperadmin': istSuperadmin,
          'istAdmin': istAdmin,
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

  String _issueToken(
      String id, String firmaId, String email, String name,
      bool istSuperadmin, bool istAdmin) {
    final secret =
        Platform.environment['JWT_SECRET'] ?? 'changeme_jwt_secret';
    return JWT({
      'sub': id,
      'firmaId': firmaId,
      'email': email,
      'name': name,
      'istSuperadmin': istSuperadmin,
      'istAdmin': istAdmin,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }).sign(SecretKey(secret), expiresIn: const Duration(days: 30));
  }
}
