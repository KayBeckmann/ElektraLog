import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import '../middleware/auth_middleware.dart';

class KundenEndpoint {
  final Connection db;
  KundenEndpoint(this.db);

  // GET /api/kunden
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
      final firmaId = claims['firmaId'] as String;
      final rows = await db.execute(
        Sql.named(
          'SELECT uuid, firma_id, name, strasse, plz, ort, '
          'kontakt_email, kontakt_telefon, erstellt_am '
          'FROM kunden WHERE firma_id = @fid ORDER BY name',
        ),
        parameters: {'fid': firmaId},
      );
      final result = rows
          .map((r) => {
                'uuid': r[0].toString(),
                'firmaId': r[1].toString(),
                'name': r[2],
                'strasse': r[3],
                'plz': r[4],
                'ort': r[5],
                'kontaktEmail': r[6],
                'kontaktTelefon': r[7],
                'erstelltAm': r[8].toString(),
              })
          .toList();
      return Response.ok(
        jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('kunden.list error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // POST /api/kunden
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
      final firmaId = claims['firmaId'] as String;
      final name = body['name'] as String;
      final strasse = body['strasse'] as String?;
      final plz = body['plz'] as String?;
      final ort = body['ort'] as String?;
      final kontaktEmail = body['kontaktEmail'] as String?;
      final kontaktTelefon = body['kontaktTelefon'] as String?;

      final rows = await db.execute(
        Sql.named(
          'INSERT INTO kunden (firma_id, name, strasse, plz, ort, '
          'kontakt_email, kontakt_telefon) '
          'VALUES (@fid, @name, @strasse, @plz, @ort, @email, @tel) '
          'RETURNING uuid, erstellt_am',
        ),
        parameters: {
          'fid': firmaId,
          'name': name,
          'strasse': strasse,
          'plz': plz,
          'ort': ort,
          'email': kontaktEmail,
          'tel': kontaktTelefon,
        },
      );
      final row = rows.first;
      return Response.ok(
        jsonEncode({
          'uuid': row[0].toString(),
          'firmaId': firmaId,
          'name': name,
          'strasse': strasse,
          'plz': plz,
          'ort': ort,
          'kontaktEmail': kontaktEmail,
          'kontaktTelefon': kontaktTelefon,
          'erstelltAm': row[1].toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('kunden.create error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // PUT /api/kunden/:uuid
  Future<Response> update(Request request, String uuid) async {
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
      final firmaId = claims['firmaId'] as String;

      await db.execute(
        Sql.named(
          'UPDATE kunden SET '
          'name = COALESCE(@name, name), '
          'strasse = @strasse, '
          'plz = @plz, '
          'ort = @ort, '
          'kontakt_email = @email, '
          'kontakt_telefon = @tel '
          'WHERE uuid = @uuid AND firma_id = @fid',
        ),
        parameters: {
          'name': body['name'],
          'strasse': body['strasse'],
          'plz': body['plz'],
          'ort': body['ort'],
          'email': body['kontaktEmail'],
          'tel': body['kontaktTelefon'],
          'uuid': uuid,
          'fid': firmaId,
        },
      );
      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('kunden.update error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // DELETE /api/kunden/:uuid
  Future<Response> delete(Request request, String uuid) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(
        401,
        body: jsonEncode({'error': 'Nicht authentifiziert'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    try {
      final firmaId = claims['firmaId'] as String;
      await db.execute(
        Sql.named(
          'DELETE FROM kunden WHERE uuid = @uuid AND firma_id = @fid',
        ),
        parameters: {'uuid': uuid, 'fid': firmaId},
      );
      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('kunden.delete error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // POST /api/sync — Bulk-Upsert for offline sync
  Future<Response> sync(Request request) async {
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
      final type = body['type'] as String?;
      final items = body['items'] as List<dynamic>? ?? [];
      final firmaId = claims['firmaId'] as String;
      int synced = 0;

      if (type == 'kunden') {
        for (final item in items) {
          final k = item as Map<String, dynamic>;
          await db.execute(
            Sql.named(
              'INSERT INTO kunden (uuid, firma_id, name, strasse, plz, ort, '
              'kontakt_email, kontakt_telefon) '
              'VALUES (@uuid, @fid, @name, @strasse, @plz, @ort, @email, @tel) '
              'ON CONFLICT (uuid) DO UPDATE SET '
              'name = EXCLUDED.name, '
              'strasse = EXCLUDED.strasse, '
              'plz = EXCLUDED.plz, '
              'ort = EXCLUDED.ort, '
              'kontakt_email = EXCLUDED.kontakt_email, '
              'kontakt_telefon = EXCLUDED.kontakt_telefon',
            ),
            parameters: {
              'uuid': k['uuid'] as String,
              'fid': firmaId,
              'name': k['name'] as String,
              'strasse': k['strasse'],
              'plz': k['plz'],
              'ort': k['ort'],
              'email': k['kontaktEmail'],
              'tel': k['kontaktTelefon'],
            },
          );
          synced++;
        }
      }

      return Response.ok(
        jsonEncode({'synced': synced, 'type': type}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('sync error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
