import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:bcrypt/bcrypt.dart';
import '../middleware/auth_middleware.dart';

class MandantenEndpoint {
  final Connection db;
  MandantenEndpoint(this.db);

  // GET /api/admin/firmen — Superadmin: alle Firmen auflisten
  Future<Response> list(Request request) async {
    final claims = verifyJwt(request);
    final err = requireSuperadmin(claims);
    if (err != null) return err;

    try {
      final rows = await db.execute(
        Sql.named(
          'SELECT id, name, status, erstellt_am FROM firmen ORDER BY name',
        ),
      );
      final result = rows
          .map((r) => {
                'id': r[0].toString(),
                'name': r[1],
                'status': r[2],
                'erstelltAm': r[3].toString(),
              })
          .toList();
      return Response.ok(
        jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('firmen.list error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // POST /api/admin/firmen — Superadmin: Firma anlegen
  Future<Response> create(Request request) async {
    final claims = verifyJwt(request);
    final err = requireSuperadmin(claims);
    if (err != null) return err;

    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final name = body['name'] as String;
      final firmaId = const Uuid().v4();
      final rolleId = const Uuid().v4();

      await db.runTx((ctx) async {
        await ctx.execute(
          Sql.named('INSERT INTO firmen (id, name) VALUES (@id, @name)'),
          parameters: {'id': firmaId, 'name': name},
        );
        // Firmenadmin-Rolle sofort anlegen — damit createBenutzer sie findet
        await ctx.execute(
          Sql.named(
            'INSERT INTO rollen (id, firma_id, name, ist_vorlage) '
            'VALUES (@id, @fid, @name, true)',
          ),
          parameters: {'id': rolleId, 'fid': firmaId, 'name': 'Firmenadmin'},
        );
        await ctx.execute(
          Sql.named(
            'INSERT INTO rollen_berechtigungen (rollen_id, berechtigung_id) '
            'SELECT @rid, id FROM berechtigungen',
          ),
          parameters: {'rid': rolleId},
        );
      });

      return Response.ok(
        jsonEncode({'id': firmaId, 'name': name, 'status': 'aktiv'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('firmen.create error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // GET /api/admin/firmen/:id/benutzer — Superadmin: Benutzer einer Firma auflisten
  Future<Response> listBenutzer(Request request, String firmaId) async {
    final claims = verifyJwt(request);
    final err = requireSuperadmin(claims);
    if (err != null) return err;

    try {
      final rows = await db.execute(
        Sql.named(
          'SELECT b.id, b.email, b.name, b.status, b.erstellt_am, '
          '       EXISTS( '
          '         SELECT 1 FROM benutzer_rollen br '
          '         JOIN rollen r ON r.id = br.rollen_id '
          '         WHERE br.benutzer_id = b.id AND r.ist_vorlage = true '
          '       ) AS ist_admin '
          'FROM benutzer b '
          'WHERE b.firma_id = @firmaId AND b.ist_superadmin = false '
          'ORDER BY b.name',
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
                'istAdmin': r[5] as bool? ?? false,
              })
          .toList();
      return Response.ok(
        jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('benutzer.list error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // POST /api/admin/firmen/:id/benutzer — Superadmin: Benutzer für Firma anlegen
  // Body: { "email", "passwort", "name" }
  Future<Response> createBenutzer(Request request, String firmaId) async {
    final claims = verifyJwt(request);
    final err = requireSuperadmin(claims);
    if (err != null) return err;

    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String;
      final passwort = body['passwort'] as String;
      final name = body['name'] as String;

      // Firma-Existenz prüfen
      final firma = await db.execute(
        Sql.named('SELECT id FROM firmen WHERE id = @id'),
        parameters: {'id': firmaId},
      );
      if (firma.isEmpty) {
        return Response(404,
            body: jsonEncode({'error': 'Firma nicht gefunden'}),
            headers: {'Content-Type': 'application/json'});
      }

      // Doppelte E-Mail prüfen
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
        // Firmenadmin-Rolle zuweisen falls vorhanden
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
        jsonEncode({'id': benutzerId, 'email': email, 'name': name, 'status': 'aktiv'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('benutzer.create error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // PATCH /api/admin/benutzer/:id/rolle — Superadmin: Firmenadmin-Rolle vergeben/entziehen
  // Body: { "istAdmin": true | false }
  Future<Response> updateBenutzerRolle(Request request, String id) async {
    final claims = verifyJwt(request);
    final err = requireSuperadmin(claims);
    if (err != null) return err;

    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final istAdmin = body['istAdmin'] as bool?;
      if (istAdmin == null) {
        return Response(400,
            body: jsonEncode({'error': 'istAdmin fehlt'}),
            headers: {'Content-Type': 'application/json'});
      }

      // Firma des Benutzers ermitteln
      final benutzerRows = await db.execute(
        Sql.named(
          'SELECT firma_id FROM benutzer '
          'WHERE id = @id AND ist_superadmin = false',
        ),
        parameters: {'id': id},
      );
      if (benutzerRows.isEmpty) {
        return Response(404,
            body: jsonEncode({'error': 'Benutzer nicht gefunden'}),
            headers: {'Content-Type': 'application/json'});
      }
      final firmaId = benutzerRows.first[0].toString();

      // Firmenadmin-Rolle der Firma ermitteln
      final rolleRows = await db.execute(
        Sql.named(
          'SELECT id FROM rollen WHERE firma_id = @firmaId AND ist_vorlage = true LIMIT 1',
        ),
        parameters: {'firmaId': firmaId},
      );
      if (rolleRows.isEmpty) {
        return Response(404,
            body: jsonEncode({'error': 'Keine Firmenadmin-Rolle gefunden'}),
            headers: {'Content-Type': 'application/json'});
      }
      final rolleId = rolleRows.first[0].toString();

      if (istAdmin) {
        await db.execute(
          Sql.named(
            'INSERT INTO benutzer_rollen (benutzer_id, rollen_id, firma_id) '
            'VALUES (@bid, @rid, @fid) ON CONFLICT DO NOTHING',
          ),
          parameters: {'bid': id, 'rid': rolleId, 'fid': firmaId},
        );
      } else {
        await db.execute(
          Sql.named(
            'DELETE FROM benutzer_rollen '
            'WHERE benutzer_id = @bid AND rollen_id = @rid AND firma_id = @fid',
          ),
          parameters: {'bid': id, 'rid': rolleId, 'fid': firmaId},
        );
      }

      return Response.ok(
        jsonEncode({'id': id, 'istAdmin': istAdmin}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('benutzer.updateRolle error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // PATCH /api/admin/benutzer/:id/status — Superadmin: Benutzer sperren/entsperren
  // Body: { "status": "aktiv" | "gesperrt" }
  Future<Response> updateBenutzerStatus(Request request, String id) async {
    final claims = verifyJwt(request);
    final err = requireSuperadmin(claims);
    if (err != null) return err;

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
          'UPDATE benutzer SET status = @status WHERE id = @id '
          'AND ist_superadmin = false '
          'RETURNING id, email, name, status',
        ),
        parameters: {'status': status, 'id': id},
      );

      if (result.isEmpty) {
        return Response(404,
            body: jsonEncode({'error': 'Benutzer nicht gefunden oder Superadmin-Schutz'}),
            headers: {'Content-Type': 'application/json'});
      }

      final row = result.first;
      return Response.ok(
        jsonEncode({'id': row[0].toString(), 'email': row[1], 'name': row[2], 'status': row[3]}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('benutzer.updateStatus error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // DELETE /api/admin/benutzer/:id — Superadmin: Benutzer löschen
  Future<Response> deleteBenutzer(Request request, String id) async {
    final claims = verifyJwt(request);
    final err = requireSuperadmin(claims);
    if (err != null) return err;

    try {
      final result = await db.execute(
        Sql.named(
          'DELETE FROM benutzer WHERE id = @id AND ist_superadmin = false RETURNING id',
        ),
        parameters: {'id': id},
      );

      if (result.isEmpty) {
        return Response(404,
            body: jsonEncode({'error': 'Benutzer nicht gefunden oder Superadmin-Schutz'}),
            headers: {'Content-Type': 'application/json'});
      }

      return Response.ok(
        jsonEncode({'deleted': id}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('benutzer.delete error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // DELETE /api/admin/firmen/:id — Superadmin: Firma und alle zugehörigen Daten löschen
  Future<Response> deleteFirma(Request request, String id) async {
    final claims = verifyJwt(request);
    final err = requireSuperadmin(claims);
    if (err != null) return err;

    try {
      await db.runTx((ctx) async {
        // benutzer_rollen der Firma-Benutzer entfernen
        await ctx.execute(
          Sql.named(
            'DELETE FROM benutzer_rollen WHERE benutzer_id IN '
            '(SELECT id FROM benutzer WHERE firma_id = @id)',
          ),
          parameters: {'id': id},
        );
        // Rollen-Berechtigungen der Firma-Rollen entfernen
        await ctx.execute(
          Sql.named(
            'DELETE FROM rollen_berechtigungen WHERE rollen_id IN '
            '(SELECT id FROM rollen WHERE firma_id = @id)',
          ),
          parameters: {'id': id},
        );
        await ctx.execute(
          Sql.named('DELETE FROM rollen WHERE firma_id = @id'),
          parameters: {'id': id},
        );
        await ctx.execute(
          Sql.named('DELETE FROM protokolle WHERE firma_id = @id'),
          parameters: {'id': id},
        );
        await ctx.execute(
          Sql.named('DELETE FROM kunden WHERE firma_id = @id'),
          parameters: {'id': id},
        );
        await ctx.execute(
          Sql.named(
            'DELETE FROM benutzer WHERE firma_id = @id AND ist_superadmin = false',
          ),
          parameters: {'id': id},
        );
        await ctx.execute(
          Sql.named('DELETE FROM firmen WHERE id = @id'),
          parameters: {'id': id},
        );
      });
      return Response.ok(
        jsonEncode({'deleted': id}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('firma.delete error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // PATCH /api/admin/firmen/:id/status — Superadmin: Firma sperren/entsperren
  // Body: { "status": "gesperrt" | "aktiv" }
  Future<Response> updateStatus(Request request, String id) async {
    final claims = verifyJwt(request);
    final err = requireSuperadmin(claims);
    if (err != null) return err;

    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final status = body['status'] as String?;

      if (status != 'aktiv' && status != 'gesperrt') {
        return Response(
          400,
          body: jsonEncode(
              {'error': 'Ungültiger Status. Erlaubt: "aktiv" oder "gesperrt"'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await db.execute(
        Sql.named(
          'UPDATE firmen SET status = @status WHERE id = @id '
          'RETURNING id, name, status',
        ),
        parameters: {'status': status, 'id': id},
      );

      if (result.isEmpty) {
        return Response(
          404,
          body: jsonEncode({'error': 'Firma nicht gefunden'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final row = result.first;
      return Response.ok(
        jsonEncode({
          'id': row[0].toString(),
          'name': row[1],
          'status': row[2],
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('firmen.updateStatus error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
