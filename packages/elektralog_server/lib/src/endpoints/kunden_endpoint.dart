import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';
import '../middleware/auth_middleware.dart';
import '../sync/sync_engine.dart';

class KundenEndpoint {
  final Connection db;
  KundenEndpoint(this.db);

  /// Erhöht den Sync-Revision-Zähler der Firma um 1 (Roadmap M9.1:
  /// Server-Rollback-Erkennung) und gibt den neuen Wert zurück. Wird bei
  /// jeder mutierenden Operation aufgerufen, die synchronisierte Daten
  /// verändert — nicht pro Einzeldatensatz, sondern pro abgeschlossener
  /// Operation, das reicht für die reine Monotonie-Prüfung des Clients.
  Future<int> _bumpRevision(String firmaId) async {
    final rows = await db.execute(
      Sql.named(
        'UPDATE firmen SET sync_revision = sync_revision + 1 '
        'WHERE id = @fid RETURNING sync_revision',
      ),
      parameters: {'fid': firmaId},
    );
    return (rows.first[0] as num).toInt();
  }

  /// Zerlegt einen komma-getrennten Query-Parameter (`?standorte=a,b,c`) in
  /// eine UUID-Liste. `null`/leer/nur Whitespace → leere Liste.
  List<String> _splitUuidListe(String? param) {
    if (param == null || param.trim().isEmpty) return const [];
    return param
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // GET /api/kunden
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
          'SELECT uuid, firma_id, name, strasse, plz, ort, '
          'kontakt_email, kontakt_telefon, erstellt_am, aktualisiert_am '
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
                'aktualisiertAm': r[9].toString(),
              })
          .toList();
      return Response.ok(jsonEncode(result),
          headers: {'Content-Type': 'application/json'});
    } catch (e, st) {
      print('kunden.list error: $e\n$st');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  // POST /api/kunden
  Future<Response> create(Request request) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final firmaId = claims['firmaId'] as String;
      final rows = await db.execute(
        Sql.named(
          'INSERT INTO kunden (firma_id, name, strasse, plz, ort, '
          'kontakt_email, kontakt_telefon) '
          'VALUES (@fid, @name, @strasse, @plz, @ort, @email, @tel) '
          'RETURNING uuid, erstellt_am, aktualisiert_am',
        ),
        parameters: {
          'fid': firmaId,
          'name': body['name'] as String,
          'strasse': body['strasse'],
          'plz': body['plz'],
          'ort': body['ort'],
          'email': body['kontaktEmail'],
          'tel': body['kontaktTelefon'],
        },
      );
      final row = rows.first;
      return Response.ok(
        jsonEncode({
          'uuid': row[0].toString(),
          'firmaId': firmaId,
          'name': body['name'],
          'strasse': body['strasse'],
          'plz': body['plz'],
          'ort': body['ort'],
          'kontaktEmail': body['kontaktEmail'],
          'kontaktTelefon': body['kontaktTelefon'],
          'erstelltAm': row[1].toString(),
          'aktualisiertAm': row[2].toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('kunden.create error: $e\n$st');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  // PUT /api/kunden/:uuid
  Future<Response> update(Request request, String uuid) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final firmaId = claims['firmaId'] as String;
      await db.execute(
        Sql.named(
          'UPDATE kunden SET '
          'name = COALESCE(@name, name), '
          'strasse = @strasse, plz = @plz, ort = @ort, '
          'kontakt_email = @email, kontakt_telefon = @tel, '
          'aktualisiert_am = NOW(), version = version + 1 '
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
      return Response.ok(jsonEncode({'success': true}),
          headers: {'Content-Type': 'application/json'});
    } catch (e, st) {
      print('kunden.update error: $e\n$st');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  // DELETE /api/kunden/:uuid
  Future<Response> delete(Request request, String uuid) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }
    try {
      final firmaId = claims['firmaId'] as String;
      await db.execute(
        Sql.named(
            'DELETE FROM kunden WHERE uuid = @uuid AND firma_id = @fid'),
        parameters: {'uuid': uuid, 'fid': firmaId},
      );
      await _bumpRevision(firmaId);
      return Response.ok(jsonEncode({'success': true}),
          headers: {'Content-Type': 'application/json'});
    } catch (e, st) {
      print('kunden.delete error: $e\n$st');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  // DELETE /api/standorte/:uuid
  Future<Response> deleteStandort(Request request, String uuid) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }
    try {
      final firmaId = claims['firmaId'] as String;
      await db.execute(
        Sql.named(
            'DELETE FROM standorte WHERE uuid = @uuid AND firma_id = @fid'),
        parameters: {'uuid': uuid, 'fid': firmaId},
      );
      await _bumpRevision(firmaId);
      return Response.ok(jsonEncode({'success': true}),
          headers: {'Content-Type': 'application/json'});
    } catch (e, st) {
      print('standorte.delete error: $e\n$st');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  // DELETE /api/verteiler/:uuid
  Future<Response> deleteVerteiler(Request request, String uuid) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }
    try {
      final firmaId = claims['firmaId'] as String;
      await db.execute(
        Sql.named(
            'DELETE FROM verteiler WHERE uuid = @uuid AND firma_id = @fid'),
        parameters: {'uuid': uuid, 'fid': firmaId},
      );
      await _bumpRevision(firmaId);
      return Response.ok(jsonEncode({'success': true}),
          headers: {'Content-Type': 'application/json'});
    } catch (e, st) {
      print('verteiler.delete error: $e\n$st');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  // DELETE /api/komponenten/:uuid
  Future<Response> deleteKomponente(Request request, String uuid) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }
    try {
      final firmaId = claims['firmaId'] as String;
      await db.execute(
        Sql.named(
            'DELETE FROM verteiler_komponenten WHERE uuid = @uuid AND firma_id = @fid'),
        parameters: {'uuid': uuid, 'fid': firmaId},
      );
      await _bumpRevision(firmaId);
      return Response.ok(jsonEncode({'success': true}),
          headers: {'Content-Type': 'application/json'});
    } catch (e, st) {
      print('komponenten.delete error: $e\n$st');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  // DELETE /api/raeume/:uuid — nur leere Räume (Geräte erst umhängen).
  Future<Response> deleteRaum(Request request, String uuid) =>
      _deleteGeraeteDatensatz(request, 'raeume', uuid,
          belegt: 'Raum enthält noch Geräte — erst umhängen oder löschen.');

  // DELETE /api/geraete/:uuid
  Future<Response> deleteGeraet(Request request, String uuid) =>
      _deleteGeraeteDatensatz(request, 'geraete', uuid,
          belegt: 'Gerät hat Prüfungen — inaktiv setzen statt löschen.');

  Future<Response> _deleteGeraeteDatensatz(
      Request request, String tabelle, String uuid,
      {required String belegt}) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }
    if (!Uuid.isValidUUID(fromString: uuid)) {
      return Response(400,
          body: jsonEncode({'error': 'Ungültige UUID'}),
          headers: {'Content-Type': 'application/json'});
    }
    final firmaId = claims['firmaId'] as String;
    if (tabelle == 'geraete') {
      final pruefungen = await db.execute(
        Sql.named('SELECT 1 FROM geraetepruefungen WHERE geraet_uuid = @uuid AND firma_id = @fid LIMIT 1'),
        parameters: {'uuid': uuid, 'fid': firmaId},
      );
      if (pruefungen.isNotEmpty) {
        return Response(409,
            body: jsonEncode({'error': belegt}),
            headers: {'Content-Type': 'application/json'});
      }
    }
    try {
      await db.execute(
        Sql.named('DELETE FROM $tabelle WHERE uuid = @uuid AND firma_id = @fid'),
        parameters: {'uuid': uuid, 'fid': firmaId},
      );
    } on ServerException catch (e) {
      // 23503 = foreign_key_violation: noch abhängige Datensätze.
      if (e.code == '23503') {
        return Response(409,
            body: jsonEncode({'error': belegt}),
            headers: {'Content-Type': 'application/json'});
      }
      rethrow;
    }
    await _bumpRevision(firmaId);
    return Response.ok(jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'});
  }

  // GET /api/sync — Alle Rohdaten der Firma für Client-Pull, mit Version
  // pro Datensatz (Roadmap Geräteprüfung M3).
  //
  // Roadmap M9.7 — selektive Synchronisation: Kunden sowie die Basisdaten
  // von Standorten/Verteilern und Räume werden IMMER vollständig geliefert,
  // damit der Nutzer überhaupt browsen und etwas auswählen kann. Der
  // "Aufbau" eines Verteilers (Komponentenbaum, Messungen, Sichtprüfungen)
  // und Geräte kommen nur für die per Query-Parameter gewählte Auswahl
  // (`standorte`/`verteiler` bzw. `geraeteStandorte`/`raeume`).
  //
  // Fehlen ALLE Parameter komplett (nicht nur leer), gilt das alte
  // Verhalten (alles liefern) — Abwärtskompatibilität für ältere Clients.
  Future<Response> pullAll(Request request) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }
    try {
      final fid = claims['firmaId'] as String;
      final q = request.url.queryParameters;
      const namen = ['standorte', 'verteiler', 'geraeteStandorte', 'raeume'];
      final listen = {for (final n in namen) n: _splitUuidListe(q[n])};
      final ungueltig = listen.values
          .expand((l) => l)
          .where((id) => !Uuid.isValidUUID(fromString: id))
          .toList();
      if (ungueltig.isNotEmpty) {
        return Response(400,
            body: jsonEncode({
              'error': 'Ungültige UUID in der Sync-Auswahl: ${ungueltig.join(', ')}'
            }),
            headers: {'Content-Type': 'application/json'});
      }
      final auswahl = namen.any(q.containsKey)
          ? SyncAuswahl(
              standorte: listen['standorte']!,
              verteiler: listen['verteiler']!,
              geraeteStandorte: listen['geraeteStandorte']!,
              raeume: listen['raeume']!,
            )
          : null;

      final revisionRows = await db.execute(
        Sql.named('SELECT sync_revision FROM firmen WHERE id = @fid'),
        parameters: {'fid': fid},
      );
      final syncRevision = revisionRows.isEmpty
          ? 0
          : (revisionRows.first[0] as num).toInt();

      return Response.ok(
        jsonEncode({
          // Roadmap M9.1: Client vergleicht diesen Wert mit dem zuletzt
          // gesehenen, um einen Server-Restore auf ein älteres Backup zu
          // erkennen (siehe Migration 008 + SyncService._evaluateRevision).
          'syncRevision': syncRevision,
          ...await SyncEngine(db).pull(fid, auswahl),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      print('pullAll error: $e\n$st');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  // POST /api/sync — versionierter Bulk-Upsert (siehe SyncEngine).
  // Format: { "batches": [{ "type": "kunden", "items": [...] }, ...] }
  // Backward compat: { "type": "kunden", "items": [...] } still works.
  // Antwort: synced, syncRevision, ergebnisse (neue Versionen), konflikte
  // (mit Serverfassung), abgelehnt (mit Grund).
  Future<Response> sync(Request request) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final firmaId = claims['firmaId'] as String;

      final batches = body.containsKey('batches')
          ? (body['batches'] as List).map((e) => (e as Map).cast<String, dynamic>()).toList()
          : [body];
      final ergebnis =
          await SyncEngine(db).push(firmaId, claims['sub'] as String?, batches);

      // Revision auch bei leerem Batch/0 synced Items erhöhen: der Client
      // hat einen Sync-Versuch gemacht, das allein reicht als "diese Firma
      // ist noch aktiv/erreichbar"-Signal und hält die Monotonie-Prüfung
      // robust gegenüber Batches, die nur aus bereits bekannten Items
      // bestehen (kein Fehlerfall, aber synced kann 0 sein).
      final revision = await _bumpRevision(firmaId);

      return Response.ok(
          jsonEncode({
            'synced': (ergebnis['ergebnisse'] as List).length,
            'syncRevision': revision,
            ...ergebnis,
          }),
          headers: {'Content-Type': 'application/json'});
    } catch (e, st) {
      print('sync error: $e\n$st');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }
}
