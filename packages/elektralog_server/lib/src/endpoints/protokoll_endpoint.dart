import 'dart:convert';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import '../middleware/auth_middleware.dart';

/// Endpoint für die rechtssichere Protokoll-Ablage.
///
/// POST /api/protokolle       — Protokoll mit PDF hochladen (append-only)
/// GET  /api/protokolle       — Protokoll-Liste der eigenen Firma
/// GET  /api/protokolle/:id   — Einzelnes Protokoll (Metadaten ohne PDF)
/// GET  /api/protokolle/:id/pdf — PDF herunterladen
class ProtokollEndpoint {
  final Connection db;
  ProtokollEndpoint(this.db);

  // POST /api/protokolle
  // Body: {
  //   "verteilerBezeichnung", "standortBezeichnung", "kundenBezeichnung",
  //   "prueferName", "firmaName", "protokollDatum" (ISO8601),
  //   "messdatenJson", "pdfBase64", "pdfHash"
  // }
  Future<Response> create(Request request) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final firmaId = claims['firmaId'] as String;
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final pdfBase64 = body['pdfBase64'] as String?;
      final pdfHash = body['pdfHash'] as String?;
      if (pdfBase64 == null || pdfHash == null || pdfBase64.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'pdfBase64 und pdfHash erforderlich'}),
            headers: {'Content-Type': 'application/json'});
      }

      final pdfBytes = base64Decode(pdfBase64);

      // Protokolldatum vom Client; Erstellungszeitpunkt kommt vom Server
      DateTime protokollDatum;
      try {
        protokollDatum =
            DateTime.parse(body['protokollDatum'] as String? ?? '');
      } catch (_) {
        protokollDatum = DateTime.now();
      }

      final rows = await db.execute(
        Sql.named(
          'INSERT INTO protokolle ('
          '  firma_id, verteiler_bezeichnung, standort_bezeichnung, '
          '  kunden_bezeichnung, pruefer_name, firma_name, '
          '  protokoll_datum, messdaten_json, pdf_data, pdf_hash'
          ') VALUES ('
          '  @firma_id, @vb, @sb, @kb, @pn, @fn, '
          '  @pd, @mj, @pdf, @hash'
          ') RETURNING id, erstellt_am',
        ),
        parameters: {
          'firma_id': firmaId,
          'vb': body['verteilerBezeichnung'] as String? ?? '',
          'sb': body['standortBezeichnung'],
          'kb': body['kundenBezeichnung'],
          'pn': body['prueferName'],
          'fn': body['firmaName'],
          'pd': protokollDatum.toUtc(),
          'mj': body['messdatenJson'],
          'pdf': TypedValue(Type.byteArray, pdfBytes),
          'hash': pdfHash,
        },
      );

      final row = rows.first;
      return Response.ok(
        jsonEncode({
          'id': row[0].toString(),
          'erstelltAm': row[1].toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('protokolle.create error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // GET /api/protokolle — Liste (ohne PDF-Daten)
  Future<Response> list(Request request) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final firmaId = claims['firmaId'] as String;
      final rows = await db.execute(
        Sql.named(
          'SELECT id, verteiler_bezeichnung, standort_bezeichnung, '
          '  kunden_bezeichnung, pruefer_name, protokoll_datum, '
          '  pdf_hash, erstellt_am '
          'FROM protokolle WHERE firma_id = @fid '
          'ORDER BY erstellt_am DESC',
        ),
        parameters: {'fid': firmaId},
      );

      final result = rows
          .map((r) => {
                'id': r[0].toString(),
                'verteilerBezeichnung': r[1],
                'standortBezeichnung': r[2],
                'kundenBezeichnung': r[3],
                'prueferName': r[4],
                'protokollDatum': r[5].toString(),
                'pdfHash': r[6],
                'erstelltAm': r[7].toString(),
              })
          .toList();

      return Response.ok(
        jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('protokolle.list error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // GET /api/protokolle/:id — Metadaten + messdaten_json (ohne PDF-Bytes)
  Future<Response> get(Request request, String id) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final firmaId = claims['firmaId'] as String;
      final rows = await db.execute(
        Sql.named(
          'SELECT id, verteiler_bezeichnung, standort_bezeichnung, '
          '  kunden_bezeichnung, pruefer_name, firma_name, '
          '  protokoll_datum, messdaten_json, pdf_hash, erstellt_am '
          'FROM protokolle WHERE id = @id AND firma_id = @fid',
        ),
        parameters: {'id': id, 'fid': firmaId},
      );

      if (rows.isEmpty) {
        return Response(404,
            body: jsonEncode({'error': 'Nicht gefunden'}),
            headers: {'Content-Type': 'application/json'});
      }

      final r = rows.first;
      return Response.ok(
        jsonEncode({
          'id': r[0].toString(),
          'verteilerBezeichnung': r[1],
          'standortBezeichnung': r[2],
          'kundenBezeichnung': r[3],
          'prueferName': r[4],
          'firmaName': r[5],
          'protokollDatum': r[6].toString(),
          'messdatenJson': r[7],
          'pdfHash': r[8],
          'erstelltAm': r[9].toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('protokolle.get error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // GET /api/protokolle/:id/pdf — PDF-Download
  Future<Response> getPdf(Request request, String id) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      final firmaId = claims['firmaId'] as String;
      final rows = await db.execute(
        Sql.named(
          'SELECT pdf_data, verteiler_bezeichnung, protokoll_datum '
          'FROM protokolle WHERE id = @id AND firma_id = @fid',
        ),
        parameters: {'id': id, 'fid': firmaId},
      );

      if (rows.isEmpty) {
        return Response(404,
            body: jsonEncode({'error': 'Nicht gefunden'}),
            headers: {'Content-Type': 'application/json'});
      }

      final r = rows.first;
      final raw = r[0];
      final Uint8List pdfBytes;
      if (raw is Uint8List) {
        pdfBytes = raw;
      } else if (raw is List<int>) {
        pdfBytes = Uint8List.fromList(raw);
      } else {
        print('getPdf: unexpected pdf_data type: ${raw?.runtimeType}');
        return Response.internalServerError(
          body: jsonEncode({'error': 'PDF-Daten fehlerhaft (interner Fehler)'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      final bezeichnung = (r[1] as String?)?.replaceAll(' ', '_') ?? 'Protokoll';
      final datum = r[2].toString().substring(0, 10);

      return Response(
        200,
        body: Stream<List<int>>.value(pdfBytes),
        headers: {
          'Content-Type': 'application/pdf',
          'Content-Disposition':
              'attachment; filename="Protokoll_${bezeichnung}_$datum.pdf"',
          'Content-Length': pdfBytes.length.toString(),
        },
      );
    } catch (e, st) {
      print('protokolle.getPdf error: $e\n$st');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
