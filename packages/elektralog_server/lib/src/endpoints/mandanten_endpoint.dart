import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import '../middleware/auth_middleware.dart';

class MandantenEndpoint {
  final Connection db;
  MandantenEndpoint(this.db);

  // GET /api/admin/firmen — Superadmin: list all companies
  Future<Response> list(Request request) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(
        401,
        body: jsonEncode({'error': 'Nicht authentifiziert'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
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

  // POST /api/admin/firmen — Superadmin: create company
  Future<Response> create(Request request) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(
        401,
        body: jsonEncode({'error': 'Nicht authentifiziert'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
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
}
