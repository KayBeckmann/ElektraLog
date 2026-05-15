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

  // POST /api/auth/register
  // Body: { "email", "passwort", "name", "firmenname" }
  Future<Response> register(Request request) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String;
      final passwort = body['passwort'] as String;
      final name = body['name'] as String;
      final firmenname = body['firmenname'] as String;

      // Prüfe ob Email bereits vergeben
      final existing = await db.execute(
        Sql.named('SELECT id FROM benutzer WHERE email = @email'),
        parameters: {'email': email},
      );
      if (existing.isNotEmpty) {
        return Response(
          409,
          body: jsonEncode({'error': 'Email bereits vergeben'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final hash = BCrypt.hashpw(passwort, BCrypt.gensalt());
      final firmaId = const Uuid().v4();
      final benutzerId = const Uuid().v4();

      // Firma + Benutzer anlegen (Transaktion)
      await db.runTx((ctx) async {
        await ctx.execute(
          Sql.named('INSERT INTO firmen (id, name) VALUES (@id, @name)'),
          parameters: {'id': firmaId, 'name': firmenname},
        );
        await ctx.execute(
          Sql.named(
            'INSERT INTO benutzer (id, firma_id, email, passwort_hash, name) '
            'VALUES (@id, @fid, @email, @hash, @name)',
          ),
          parameters: {
            'id': benutzerId,
            'fid': firmaId,
            'email': email,
            'hash': hash,
            'name': name,
          },
        );
        // Firmenadmin-Rolle anlegen und zuweisen
        final rolleId = const Uuid().v4();
        await ctx.execute(
          Sql.named(
            'INSERT INTO rollen (id, firma_id, name, ist_vorlage) '
            'VALUES (@id, @fid, @name, true)',
          ),
          parameters: {'id': rolleId, 'fid': firmaId, 'name': 'Firmenadmin'},
        );
        // Alle Berechtigungen der Admin-Rolle zuweisen
        await ctx.execute(
          Sql.named(
            'INSERT INTO rollen_berechtigungen (rollen_id, berechtigung_id) '
            'SELECT @rid, id FROM berechtigungen',
          ),
          parameters: {'rid': rolleId},
        );
        await ctx.execute(
          Sql.named(
            'INSERT INTO benutzer_rollen (benutzer_id, rollen_id, firma_id) '
            'VALUES (@bid, @rid, @fid)',
          ),
          parameters: {'bid': benutzerId, 'rid': rolleId, 'fid': firmaId},
        );
      });

      final token = _issueToken(benutzerId, firmaId, email, name, false);
      return Response.ok(
        jsonEncode({
          'token': token,
          'benutzerId': benutzerId,
          'firmaId': firmaId,
          'name': name,
          'istSuperadmin': false,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('register error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
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
          '       f.status AS firma_status '
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
      final token = _issueToken(benutzerId, firmaId, email, name, istSuperadmin);

      return Response.ok(
        jsonEncode({
          'token': token,
          'benutzerId': benutzerId,
          'firmaId': firmaId,
          'name': name,
          'istSuperadmin': istSuperadmin,
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
      String id, String firmaId, String email, String name, bool istSuperadmin) {
    final secret =
        Platform.environment['JWT_SECRET'] ?? 'changeme_jwt_secret';
    return JWT({
      'sub': id,
      'firmaId': firmaId,
      'email': email,
      'name': name,
      'istSuperadmin': istSuperadmin,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }).sign(SecretKey(secret), expiresIn: const Duration(days: 30));
  }
}
