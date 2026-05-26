import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';
import '../middleware/auth_middleware.dart';

class FirmaEndpoint {
  final Connection db;
  FirmaEndpoint(this.db);

  // GET /api/firma/benutzer — eigene Mitarbeiter auflisten
  Future<Response> listBenutzer(Request request) async {
    final claims = verifyJwt(request);
    if (claims == null) return _unauthorized();
    final firmaId = claims['firmaId'] as String;

    try {
      final rows = await db.execute(
        Sql.named(
          'SELECT id, email, name, status, erstellt_am '
          'FROM benutzer WHERE firma_id = @firmaId AND ist_superadmin = false '
          'ORDER BY name',
        ),
        parameters: {'firmaId': firmaId},
      );
      final result = rows
          .map((r) => {
                'id': r[0].toString(),
                'email': r[1],
                'name': r[2],
                'status': r[3],
                'erstelltAm': r[4].toString(),
              })
          .toList();
      return Response.ok(
        jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('firma.listBenutzer error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // POST /api/firma/benutzer — Mitarbeiter anlegen
  // Body: { "email", "passwort", "name" }
  Future<Response> createBenutzer(Request request) async {
    final claims = verifyJwt(request);
    if (claims == null) return _unauthorized();
    final firmaId = claims['firmaId'] as String;

    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String;
      final passwort = body['passwort'] as String;
      final name = body['name'] as String;

      final existing = await db.execute(
        Sql.named('SELECT id FROM benutzer WHERE email = @email'),
        parameters: {'email': email},
      );
      if (existing.isNotEmpty) {
        return Response(409,
            body: jsonEncode({'error': 'E-Mail bereits vergeben'}),
            headers: {'Content-Type': 'application/json'});
      }

      final hash = BCrypt.hashpw(passwort, BCrypt.gensalt());
      final benutzerId = const Uuid().v4();

      await db.runTx((ctx) async {
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
        // Standard-Rolle der Firma zuweisen
        final rolle = await ctx.execute(
          Sql.named(
            'SELECT id FROM rollen WHERE firma_id = @fid AND ist_vorlage = true LIMIT 1',
          ),
          parameters: {'fid': firmaId},
        );
        if (rolle.isNotEmpty) {
          final rolleId = rolle.first[0].toString();
          await ctx.execute(
            Sql.named(
              'INSERT INTO benutzer_rollen (benutzer_id, rollen_id, firma_id) '
              'VALUES (@bid, @rid, @fid)',
            ),
            parameters: {'bid': benutzerId, 'rid': rolleId, 'fid': firmaId},
          );
        }
      });

      return Response.ok(
        jsonEncode({
          'id': benutzerId,
          'email': email,
          'name': name,
          'status': 'aktiv',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('firma.createBenutzer error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // PATCH /api/firma/benutzer/:id/status — sperren/entsperren
  // Body: { "status": "aktiv" | "gesperrt" }
  Future<Response> updateBenutzerStatus(Request request, String id) async {
    final claims = verifyJwt(request);
    if (claims == null) return _unauthorized();
    final firmaId = claims['firmaId'] as String;
    final eigeneId = claims['sub'] as String;

    if (id == eigeneId) {
      return Response(400,
          body: jsonEncode({'error': 'Eigenen Account nicht sperren'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final status = body['status'] as String?;

      if (status != 'aktiv' && status != 'gesperrt') {
        return Response(400,
            body: jsonEncode({'error': 'Ungültiger Status'}),
            headers: {'Content-Type': 'application/json'});
      }

      final result = await db.execute(
        Sql.named(
          'UPDATE benutzer SET status = @status '
          'WHERE id = @id AND firma_id = @firmaId AND ist_superadmin = false '
          'RETURNING id, email, name, status',
        ),
        parameters: {'status': status, 'id': id, 'firmaId': firmaId},
      );

      if (result.isEmpty) {
        return Response(404,
            body: jsonEncode({'error': 'Benutzer nicht gefunden'}),
            headers: {'Content-Type': 'application/json'});
      }

      final row = result.first;
      return Response.ok(
        jsonEncode({
          'id': row[0].toString(),
          'email': row[1],
          'name': row[2],
          'status': row[3],
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('firma.updateBenutzerStatus error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // DELETE /api/firma/benutzer/:id — Mitarbeiter entfernen
  Future<Response> deleteBenutzer(Request request, String id) async {
    final claims = verifyJwt(request);
    if (claims == null) return _unauthorized();
    final firmaId = claims['firmaId'] as String;
    final eigeneId = claims['sub'] as String;

    if (id == eigeneId) {
      return Response(400,
          body: jsonEncode({'error': 'Eigenen Account nicht löschen'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final result = await db.execute(
        Sql.named(
          'DELETE FROM benutzer '
          'WHERE id = @id AND firma_id = @firmaId AND ist_superadmin = false '
          'RETURNING id',
        ),
        parameters: {'id': id, 'firmaId': firmaId},
      );

      if (result.isEmpty) {
        return Response(404,
            body: jsonEncode({'error': 'Benutzer nicht gefunden'}),
            headers: {'Content-Type': 'application/json'});
      }

      return Response.ok(
        jsonEncode({'deleted': id}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('firma.deleteBenutzer error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Response _unauthorized() => Response(
        401,
        body: jsonEncode({'error': 'Nicht authentifiziert'}),
        headers: {'Content-Type': 'application/json'},
      );
}
