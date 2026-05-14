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

      final token = _issueToken(benutzerId, firmaId, email, name);
      return Response.ok(
        jsonEncode({
          'token': token,
          'benutzerId': benutzerId,
          'firmaId': firmaId,
          'name': name,
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
          "SELECT id, firma_id, passwort_hash, name FROM benutzer "
          "WHERE email = @email AND status = 'aktiv'",
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

      final benutzerId = row[0].toString();
      final firmaId = row[1].toString();
      final name = row[3] as String;
      final token = _issueToken(benutzerId, firmaId, email, name);

      return Response.ok(
        jsonEncode({
          'token': token,
          'benutzerId': benutzerId,
          'firmaId': firmaId,
          'name': name,
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
      String id, String firmaId, String email, String name) {
    final secret =
        Platform.environment['JWT_SECRET'] ?? 'changeme_jwt_secret';
    return JWT({
      'sub': id,
      'firmaId': firmaId,
      'email': email,
      'name': name,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }).sign(SecretKey(secret), expiresIn: const Duration(days: 30));
  }
}
