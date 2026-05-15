import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
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
      final id = const Uuid().v4();

      await db.execute(
        Sql.named('INSERT INTO firmen (id, name) VALUES (@id, @name)'),
        parameters: {'id': id, 'name': name},
      );
      return Response.ok(
        jsonEncode({'id': id, 'name': name, 'status': 'aktiv'}),
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
