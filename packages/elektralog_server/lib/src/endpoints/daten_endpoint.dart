import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../middleware/auth_middleware.dart';
import '../sync/sync_typen.dart';

/// Online-Lesezugriff der Web-App: je Ansicht genau die benötigten
/// Datensätze statt eines vollständigen Downloads. Format wie beim Sync
/// (App-Modell-JSON + `version`), damit Schreiben über `POST /api/sync`
/// mit `_basisVersion` dieselben Konfliktregeln nutzt.
///
/// GET    /api/daten/<typ>?<filter>=<uuid>[,<uuid>…]
/// GET    /api/daten/<typ>/<uuid>
/// DELETE /api/daten/messungen/<uuid>
/// DELETE /api/daten/geraetepruefungen/<uuid>   (nur Entwürfe)
class DatenEndpoint {
  DatenEndpoint(this.db);
  final Connection db;

  /// Erlaubte Filter je Typ: Query-Parameter → Spalte.
  static const filter = <String, Map<String, String>>{
    'kunden': {},
    'standorte': {'kundeUuid': 'kunde_uuid'},
    'verteiler': {'standortUuid': 'standort_uuid'},
    'komponenten': {'verteilerUuid': 'verteiler_uuid'},
    'messungen': {'komponenteUuid': 'komponente_uuid'},
    'sichtpruefungen': {'verteilerUuid': 'verteiler_uuid'},
    'raeume': {'standortUuid': 'standort_uuid'},
    'geraete': {'kundeUuid': 'kunde_uuid', 'standortUuid': 'standort_uuid', 'raumUuid': 'raum_uuid'},
    'geraetepruefungen': {'geraetUuid': 'geraet_uuid'},
  };

  static Response _json(int status, Object body) =>
      Response(status, body: jsonEncode(body), headers: {'Content-Type': 'application/json'});

  Map<String, dynamic> _zeile(SyncTyp typ, ResultRow r) {
    final m = r.toColumnMap();
    return {...typ.zuJson(m), 'version': (m['version'] as num).toInt()};
  }

  Future<Response> liste(Request request, String typName) async {
    final claims = verifyJwt(request);
    if (claims == null) return _json(401, {'error': 'Nicht authentifiziert'});
    final typ = syncTypen[typName];
    final erlaubt = filter[typName];
    if (typ == null || erlaubt == null) return _json(404, {'error': 'Unbekannter Datentyp'});

    final q = request.url.queryParameters;
    final unbekannt = q.keys.where((k) => !erlaubt.containsKey(k)).toList();
    if (unbekannt.isNotEmpty) return _json(400, {'error': 'Unbekannter Filter: ${unbekannt.join(', ')}'});

    final bedingungen = <String>[];
    final parameter = <String, Object?>{'fid': claims['firmaId']};
    for (final (i, e) in q.entries.indexed) {
      final ids = e.value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (ids.any((id) => !Uuid.isValidUUID(fromString: id))) return _json(400, {'error': 'Ungültige UUID'});
      bedingungen.add('${erlaubt[e.key]} = ANY(@f$i)');
      parameter['f$i'] = TypedValue(Type.uuidArray, ids);
    }
    final rows = await db.execute(
      Sql.named('SELECT * FROM ${typ.tabelle} WHERE firma_id = @fid'
          '${bedingungen.map((b) => ' AND $b').join()}'),
      parameters: parameter,
    );
    return _json(200, [for (final r in rows) _zeile(typ, r)]);
  }

  Future<Response> einzeln(Request request, String typName, String uuid) async {
    final claims = verifyJwt(request);
    if (claims == null) return _json(401, {'error': 'Nicht authentifiziert'});
    final typ = syncTypen[typName];
    if (typ == null) return _json(404, {'error': 'Unbekannter Datentyp'});
    if (!Uuid.isValidUUID(fromString: uuid)) return _json(400, {'error': 'Ungültige UUID'});
    final rows = await db.execute(
      Sql.named('SELECT * FROM ${typ.tabelle} WHERE uuid = @uuid AND firma_id = @fid'),
      parameters: {'uuid': uuid, 'fid': claims['firmaId']},
    );
    if (rows.isEmpty) return _json(404, {'error': 'Nicht gefunden'});
    return _json(200, _zeile(typ, rows.first));
  }

  /// Löschen für Typen ohne eigenen Endpunkt: Messungen und Prüfungs-
  /// Entwürfe (abgeschlossene Prüfungen sind unveränderlich).
  Future<Response> loeschen(Request request, String typName, String uuid) async {
    final claims = verifyJwt(request);
    if (claims == null) return _json(401, {'error': 'Nicht authentifiziert'});
    if (!Uuid.isValidUUID(fromString: uuid)) return _json(400, {'error': 'Ungültige UUID'});
    final sql = switch (typName) {
      'messungen' => 'DELETE FROM messungen WHERE uuid = @uuid AND firma_id = @fid',
      'geraetepruefungen' =>
        "DELETE FROM geraetepruefungen WHERE uuid = @uuid AND firma_id = @fid AND status = 'entwurf'",
      _ => null,
    };
    if (sql == null) return _json(404, {'error': 'Löschen hier nicht vorgesehen'});
    final r = await db.execute(Sql.named(sql), parameters: {'uuid': uuid, 'fid': claims['firmaId']});
    if (r.affectedRows == 0 && typName == 'geraetepruefungen') {
      final gibt = await db.execute(
        Sql.named('SELECT 1 FROM geraetepruefungen WHERE uuid = @uuid AND firma_id = @fid'),
        parameters: {'uuid': uuid, 'fid': claims['firmaId']},
      );
      if (gibt.isNotEmpty) return _json(409, {'error': 'Abgeschlossene Prüfungen sind unveränderlich'});
    }
    await db.execute(
      Sql.named('UPDATE firmen SET sync_revision = sync_revision + 1 WHERE id = @fid'),
      parameters: {'fid': claims['firmaId']},
    );
    return _json(200, {'success': true});
  }
}
