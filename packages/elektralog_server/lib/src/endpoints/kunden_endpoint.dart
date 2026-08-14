import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import '../middleware/auth_middleware.dart';

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
          'aktualisiert_am = NOW() '
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

  // GET /api/sync — Alle Rohdaten der Firma für Client-Pull.
  //
  // Roadmap M9.7 — selektive Synchronisation: Kunden sowie die Basisdaten
  // von Standorten/Verteilern (Bezeichnung, Adresse) werden IMMER
  // vollständig geliefert, damit der Nutzer überhaupt browsen und etwas
  // auswählen kann. Der "Aufbau" eines Verteilers (Komponentenbaum,
  // Messungen, Sichtprüfungen) wird dagegen nur für Verteiler geliefert,
  // die der Client über die Query-Parameter `standorte`/`verteiler`
  // (komma-getrennte UUID-Listen) explizit angefordert hat — entweder
  // direkt per Verteiler-UUID oder indirekt über den gesamten Standort.
  //
  // Fehlen BEIDE Parameter komplett (nicht nur leer), gilt das alte
  // Verhalten (alles liefern) — Abwärtskompatibilität für ältere Clients,
  // die noch nichts von der Auswahl wissen.
  Future<Response> pullAll(Request request) async {
    final claims = verifyJwt(request);
    if (claims == null) {
      return Response(401,
          body: jsonEncode({'error': 'Nicht authentifiziert'}),
          headers: {'Content-Type': 'application/json'});
    }
    try {
      final fid = claims['firmaId'] as String;

      final standorteParam = request.url.queryParameters['standorte'];
      final verteilerParam = request.url.queryParameters['verteiler'];
      final filterAktiv = standorteParam != null || verteilerParam != null;
      final angeforderteStandorte = _splitUuidListe(standorteParam);
      final angeforderteVerteiler = _splitUuidListe(verteilerParam);

      // Menge der Verteiler-UUIDs, deren Aufbau geliefert werden darf —
      // Mandantengrenze (firma_id) gilt hier zusätzlich zur Auswahl, damit
      // eine falsch/böswillig übergebene fremde UUID nie zu einem Leak
      // über Firmengrenzen hinweg führen kann.
      List<String> erlaubteVerteilerUuids = const [];
      if (filterAktiv &&
          (angeforderteStandorte.isNotEmpty ||
              angeforderteVerteiler.isNotEmpty)) {
        final rows = await db.execute(
          Sql.named(
            'SELECT uuid FROM verteiler WHERE firma_id = @fid '
            'AND (uuid = ANY(@vuuids) OR standort_uuid = ANY(@suuids))',
          ),
          parameters: {
            'fid': fid,
            'vuuids': TypedValue(Type.uuidArray, angeforderteVerteiler),
            'suuids': TypedValue(Type.uuidArray, angeforderteStandorte),
          },
        );
        erlaubteVerteilerUuids = rows.map((r) => r[0].toString()).toList();
      }

      final revisionRows = await db.execute(
        Sql.named('SELECT sync_revision FROM firmen WHERE id = @fid'),
        parameters: {'fid': fid},
      );
      final syncRevision = revisionRows.isEmpty
          ? 0
          : (revisionRows.first[0] as num).toInt();

      final kunden = await db.execute(
        Sql.named('SELECT uuid, name, strasse, plz, ort, '
            'kontakt_email, kontakt_telefon, erstellt_am, aktualisiert_am '
            'FROM kunden WHERE firma_id = @fid'),
        parameters: {'fid': fid},
      );

      final standorte = await db.execute(
        Sql.named('SELECT uuid, kunde_uuid, bezeichnung, strasse, plz, ort, '
            'erstellt_am, aktualisiert_am '
            'FROM standorte WHERE firma_id = @fid'),
        parameters: {'fid': fid},
      );

      final verteiler = await db.execute(
        Sql.named('SELECT uuid, standort_uuid, bezeichnung, bemerkung, '
            'anlagendaten_json, pruefintervall_jahre, erstellt_am, aktualisiert_am '
            'FROM verteiler WHERE firma_id = @fid'),
        parameters: {'fid': fid},
      );

      final komponenten = filterAktiv
          ? await db.execute(
              Sql.named('SELECT uuid, verteiler_uuid, parent_uuid, typ, '
                  'betriebsmittelkennzeichen, zielbezeichnung, position, '
                  'eigenschaften_json, erstellt_am, aktualisiert_am '
                  'FROM verteiler_komponenten '
                  'WHERE firma_id = @fid AND verteiler_uuid = ANY(@vuuids)'),
              parameters: {
                'fid': fid,
                'vuuids': TypedValue(Type.uuidArray, erlaubteVerteilerUuids),
              },
            )
          : await db.execute(
              Sql.named('SELECT uuid, verteiler_uuid, parent_uuid, typ, '
                  'betriebsmittelkennzeichen, zielbezeichnung, position, '
                  'eigenschaften_json, erstellt_am, aktualisiert_am '
                  'FROM verteiler_komponenten WHERE firma_id = @fid'),
              parameters: {'fid': fid},
            );

      final messungen = filterAktiv
          ? await db.execute(
              Sql.named(
                  'SELECT m.uuid, m.komponente_uuid, m.norm, m.pruefung_datum, '
                  'm.pruefer_name, m.messwert_json, m.ergebnis, m.bemerkung, '
                  'm.erstellt_am, m.aktualisiert_am '
                  'FROM messungen m '
                  'JOIN verteiler_komponenten vk ON vk.uuid = m.komponente_uuid '
                  'WHERE m.firma_id = @fid AND vk.verteiler_uuid = ANY(@vuuids)'),
              parameters: {
                'fid': fid,
                'vuuids': TypedValue(Type.uuidArray, erlaubteVerteilerUuids),
              },
            )
          : await db.execute(
              Sql.named('SELECT uuid, komponente_uuid, norm, pruefung_datum, '
                  'pruefer_name, messwert_json, ergebnis, bemerkung, '
                  'erstellt_am, aktualisiert_am '
                  'FROM messungen WHERE firma_id = @fid'),
              parameters: {'fid': fid},
            );

      final sichtpruefungen = filterAktiv
          ? await db.execute(
              Sql.named(
                  'SELECT uuid, verteiler_uuid, pruefung_datum, pruefer_name, '
                  'checkliste_json, maengel, ergebnis, naechste_pruefung_datum, '
                  'erstellt_am, aktualisiert_am '
                  'FROM sichtpruefungen '
                  'WHERE firma_id = @fid AND verteiler_uuid = ANY(@vuuids)'),
              parameters: {
                'fid': fid,
                'vuuids': TypedValue(Type.uuidArray, erlaubteVerteilerUuids),
              },
            )
          : await db.execute(
              Sql.named(
                  'SELECT uuid, verteiler_uuid, pruefung_datum, pruefer_name, '
                  'checkliste_json, maengel, ergebnis, naechste_pruefung_datum, '
                  'erstellt_am, aktualisiert_am '
                  'FROM sichtpruefungen WHERE firma_id = @fid'),
              parameters: {'fid': fid},
            );

      return Response.ok(
        jsonEncode({
          // Roadmap M9.1: Client vergleicht diesen Wert mit dem zuletzt
          // gesehenen, um einen Server-Restore auf ein älteres Backup zu
          // erkennen (siehe Migration 008 + SyncService._evaluateRevision).
          'syncRevision': syncRevision,
          'kunden': kunden.map((r) => {
            'uuid': r[0].toString(),
            'name': r[1],
            'strasse': r[2],
            'plz': r[3],
            'ort': r[4],
            'kontaktEmail': r[5],
            'kontaktTelefon': r[6],
            'erstelltAm': (r[7] as DateTime).toUtc().toIso8601String(),
            'aktualisiertAm': (r[8] as DateTime).toUtc().toIso8601String(),
          }).toList(),
          'standorte': standorte.map((r) => {
            'uuid': r[0].toString(),
            'kundeUuid': r[1].toString(),
            'bezeichnung': r[2],
            'strasse': r[3],
            'plz': r[4],
            'ort': r[5],
            'erstelltAm': (r[6] as DateTime).toUtc().toIso8601String(),
            'aktualisiertAm': (r[7] as DateTime).toUtc().toIso8601String(),
          }).toList(),
          'verteiler': verteiler.map((r) => {
            'uuid': r[0].toString(),
            'standortUuid': r[1].toString(),
            'bezeichnung': r[2],
            'bemerkung': r[3],
            'anlagendatenJson': r[4],
            'pruefintervallJahre': r[5],
            'erstelltAm': (r[6] as DateTime).toUtc().toIso8601String(),
            'aktualisiertAm': (r[7] as DateTime).toUtc().toIso8601String(),
          }).toList(),
          'komponenten': komponenten.map((r) => {
            'uuid': r[0].toString(),
            'verteilerUuid': r[1].toString(),
            'parentUuid': r[2]?.toString(),
            'typ': r[3],
            'betriebsmittelkennzeichen': r[4] ?? '',
            'zielbezeichnung': r[5] ?? '',
            'position': r[6],
            'eigenschaftenJson': r[7],
            'erstelltAm': (r[8] as DateTime).toUtc().toIso8601String(),
            'aktualisiertAm': (r[9] as DateTime).toUtc().toIso8601String(),
          }).toList(),
          'messungen': messungen.map((r) => {
            'uuid': r[0].toString(),
            'komponenteUuid': r[1]?.toString(),
            'norm': r[2] ?? 'vde_0100',
            'pruefungDatum': r[3] is DateTime ? (r[3] as DateTime).toIso8601String().split('T')[0] : r[3].toString(),
            'prueferName': r[4],
            'messwertJson': r[5],
            'ergebnis': r[6],
            'bemerkung': r[7],
            'erstelltAm': (r[8] as DateTime).toUtc().toIso8601String(),
            'aktualisiertAm': (r[9] as DateTime).toUtc().toIso8601String(),
          }).toList(),
          'sichtpruefungen': sichtpruefungen.map((r) => {
            'uuid': r[0].toString(),
            'verteilerUuid': r[1].toString(),
            'pruefungDatum': r[2] is DateTime ? (r[2] as DateTime).toIso8601String().split('T')[0] : r[2].toString(),
            'prueferName': r[3],
            'checklisteJson': r[4],
            'maengel': r[5],
            'ergebnis': r[6],
            'naechstePruefungDatum': r[7] is DateTime ? (r[7] as DateTime).toIso8601String().split('T')[0] : r[7]?.toString(),
            'erstelltAm': (r[8] as DateTime).toUtc().toIso8601String(),
            'aktualisiertAm': (r[9] as DateTime).toUtc().toIso8601String(),
          }).toList(),
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

  // POST /api/sync — Bulk-Upsert, unconditional (Server übernimmt immer
  // den zuletzt gepushten Stand, Mandantengrenze bleibt über firma_id
  // geschützt). Format: { "batches": [{ "type": "kunden", "items": [...] }, ...] }
  // Backward compat: { "type": "kunden", "items": [...] } still works.
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
      int synced = 0;

      // Normalize to batch list
      final List<Map<String, dynamic>> batches;
      if (body.containsKey('batches')) {
        batches = (body['batches'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      } else {
        batches = [body];
      }

      for (final batch in batches) {
        final type = batch['type'] as String?;
        final items = batch['items'] as List<dynamic>? ?? [];
        synced += await _syncBatch(firmaId, type, items);
      }

      // Revision auch bei leerem Batch/0 synced Items erhöhen: der Client
      // hat einen Sync-Versuch gemacht, das allein reicht als "diese Firma
      // ist noch aktiv/erreichbar"-Signal und hält die Monotonie-Prüfung
      // robust gegenüber Batches, die nur aus bereits bekannten Items
      // bestehen (kein Fehlerfall, aber synced kann 0 sein).
      final revision = await _bumpRevision(firmaId);

      return Response.ok(
          jsonEncode({'synced': synced, 'syncRevision': revision}),
          headers: {'Content-Type': 'application/json'});
    } catch (e, st) {
      print('sync error: $e\n$st');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<int> _syncBatch(
      String firmaId, String? type, List<dynamic> items) async {
    int count = 0;
    for (final raw in items) {
      final item = raw as Map<String, dynamic>;
      try {
        switch (type) {
          case 'kunden':
            await _upsertKunde(firmaId, item);
          case 'standorte':
            await _upsertStandort(firmaId, item);
          case 'verteiler':
            await _upsertVerteiler(firmaId, item);
          case 'komponenten':
            await _upsertKomponente(firmaId, item);
          case 'messungen':
            await _upsertMessung(firmaId, item);
          case 'sichtpruefungen':
            await _upsertSichtpruefung(firmaId, item);
        }
        count++;
      } catch (e) {
        // FK-Verletzung (z.B. parent noch nicht auf Server) → überspringen
        print('sync $type ${item['uuid']} übersprungen: $e');
      }
    }
    return count;
  }

  Future<void> _upsertKunde(String firmaId, Map<String, dynamic> k) async {
    final ts = k['aktualisiertAm'] as String? ?? DateTime.now().toIso8601String();
    await db.execute(
      Sql.named(
        'INSERT INTO kunden (uuid, firma_id, name, strasse, plz, ort, '
        'kontakt_email, kontakt_telefon, aktualisiert_am) '
        'VALUES (@uuid, @fid, @name, @strasse, @plz, @ort, @email, @tel, @ts) '
        'ON CONFLICT (uuid) DO UPDATE SET '
        'name = EXCLUDED.name, strasse = EXCLUDED.strasse, '
        'plz = EXCLUDED.plz, ort = EXCLUDED.ort, '
        'kontakt_email = EXCLUDED.kontakt_email, '
        'kontakt_telefon = EXCLUDED.kontakt_telefon, '
        'aktualisiert_am = EXCLUDED.aktualisiert_am '
        'WHERE kunden.firma_id = EXCLUDED.firma_id',
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
        'ts': ts,
      },
    );
  }

  Future<void> _upsertStandort(String firmaId, Map<String, dynamic> s) async {
    final ts = s['aktualisiertAm'] as String? ?? DateTime.now().toIso8601String();
    await db.execute(
      Sql.named(
        'INSERT INTO standorte (uuid, firma_id, kunde_uuid, bezeichnung, '
        'strasse, plz, ort, aktualisiert_am) '
        'VALUES (@uuid, @fid, @kuid, @bez, @str, @plz, @ort, @ts) '
        'ON CONFLICT (uuid) DO UPDATE SET '
        'bezeichnung = EXCLUDED.bezeichnung, strasse = EXCLUDED.strasse, '
        'plz = EXCLUDED.plz, ort = EXCLUDED.ort, '
        'aktualisiert_am = EXCLUDED.aktualisiert_am '
        'WHERE standorte.firma_id = EXCLUDED.firma_id',
      ),
      parameters: {
        'uuid': s['uuid'] as String,
        'fid': firmaId,
        'kuid': s['kundeUuid'] as String,
        'bez': s['bezeichnung'] as String,
        'str': s['strasse'],
        'plz': s['plz'],
        'ort': s['ort'],
        'ts': ts,
      },
    );
  }

  Future<void> _upsertVerteiler(
      String firmaId, Map<String, dynamic> v) async {
    final ts = v['aktualisiertAm'] as String? ?? DateTime.now().toIso8601String();
    await db.execute(
      Sql.named(
        'INSERT INTO verteiler (uuid, firma_id, standort_uuid, bezeichnung, '
        'bemerkung, anlagendaten_json, pruefintervall_jahre, aktualisiert_am) '
        'VALUES (@uuid, @fid, @suid, @bez, @bem, @json, @pj, @ts) '
        'ON CONFLICT (uuid) DO UPDATE SET '
        'bezeichnung = EXCLUDED.bezeichnung, bemerkung = EXCLUDED.bemerkung, '
        'anlagendaten_json = EXCLUDED.anlagendaten_json, '
        'pruefintervall_jahre = EXCLUDED.pruefintervall_jahre, '
        'aktualisiert_am = EXCLUDED.aktualisiert_am '
        'WHERE verteiler.firma_id = EXCLUDED.firma_id',
      ),
      parameters: {
        'uuid': v['uuid'] as String,
        'fid': firmaId,
        'suid': v['standortUuid'] as String,
        'bez': v['bezeichnung'] as String,
        'bem': v['bemerkung'],
        'json': v['anlagendatenJson'],
        'pj': (v['pruefintervallJahre'] as num?)?.toInt() ?? 4,
        'ts': ts,
      },
    );
  }

  Future<void> _upsertKomponente(
      String firmaId, Map<String, dynamic> k) async {
    final ts = k['aktualisiertAm'] as String? ?? DateTime.now().toIso8601String();
    final bmk = k['betriebsmittelkennzeichen'] as String? ?? '';
    final ziel = k['zielbezeichnung'] as String? ?? '';
    await db.execute(
      Sql.named(
        'INSERT INTO verteiler_komponenten '
        '(uuid, firma_id, verteiler_uuid, parent_uuid, typ, '
        'betriebsmittelkennzeichen, zielbezeichnung, bezeichnung, '
        'position, eigenschaften_json, aktualisiert_am) '
        'VALUES (@uuid, @fid, @vuid, @puid, @typ, @bmk, @ziel, @bez, '
        '@pos, @json, @ts) '
        'ON CONFLICT (uuid) DO UPDATE SET '
        'typ = EXCLUDED.typ, '
        'betriebsmittelkennzeichen = EXCLUDED.betriebsmittelkennzeichen, '
        'zielbezeichnung = EXCLUDED.zielbezeichnung, '
        'bezeichnung = EXCLUDED.bezeichnung, '
        'position = EXCLUDED.position, '
        'eigenschaften_json = EXCLUDED.eigenschaften_json, '
        'aktualisiert_am = EXCLUDED.aktualisiert_am '
        'WHERE verteiler_komponenten.firma_id = EXCLUDED.firma_id',
      ),
      parameters: {
        'uuid': k['uuid'] as String,
        'fid': firmaId,
        'vuid': k['verteilerUuid'] as String,
        'puid': k['parentUuid'],
        'typ': k['typ'] as String,
        'bmk': bmk,
        'ziel': ziel,
        'bez': ziel.isNotEmpty ? ziel : bmk,
        'pos': (k['position'] as num?)?.toInt() ?? 0,
        'json': k['eigenschaftenJson'],
        'ts': ts,
      },
    );
  }

  Future<void> _upsertMessung(String firmaId, Map<String, dynamic> m) async {
    final komponenteUuid = m['komponenteUuid'] as String?;
    if (komponenteUuid == null) return; // Messungen ohne Komponente nicht synken
    final ts = m['aktualisiertAm'] as String? ?? DateTime.now().toIso8601String();
    await db.execute(
      Sql.named(
        'INSERT INTO messungen '
        '(uuid, firma_id, komponente_uuid, norm, pruefung_datum, '
        'pruefer_name, messwert_json, ergebnis, bemerkung, aktualisiert_am) '
        'VALUES (@uuid, @fid, @kuid, @norm, @datum, @pn, @json, '
        '@erg, @bem, @ts) '
        'ON CONFLICT (uuid) DO UPDATE SET '
        'norm = EXCLUDED.norm, pruefung_datum = EXCLUDED.pruefung_datum, '
        'pruefer_name = EXCLUDED.pruefer_name, '
        'messwert_json = EXCLUDED.messwert_json, '
        'ergebnis = EXCLUDED.ergebnis, bemerkung = EXCLUDED.bemerkung, '
        'aktualisiert_am = EXCLUDED.aktualisiert_am '
        'WHERE messungen.firma_id = EXCLUDED.firma_id',
      ),
      parameters: {
        'uuid': m['uuid'] as String,
        'fid': firmaId,
        'kuid': komponenteUuid,
        'norm': m['norm'] as String? ?? 'vde_0100',
        'datum': m['pruefungDatum'] as String,
        'pn': m['prueferName'],
        'json': m['messwertJson'],
        'erg': m['ergebnis'] as String,
        'bem': m['bemerkung'],
        'ts': ts,
      },
    );
  }

  Future<void> _upsertSichtpruefung(
      String firmaId, Map<String, dynamic> s) async {
    final ts = s['aktualisiertAm'] as String? ?? DateTime.now().toIso8601String();
    await db.execute(
      Sql.named(
        'INSERT INTO sichtpruefungen '
        '(uuid, firma_id, verteiler_uuid, pruefung_datum, pruefer_name, '
        'checkliste_json, maengel, ergebnis, naechste_pruefung_datum, '
        'aktualisiert_am) '
        'VALUES (@uuid, @fid, @vuid, @datum, @pn, @json, @maengel, '
        '@erg, @next, @ts) '
        'ON CONFLICT (uuid) DO UPDATE SET '
        'pruefung_datum = EXCLUDED.pruefung_datum, '
        'pruefer_name = EXCLUDED.pruefer_name, '
        'checkliste_json = EXCLUDED.checkliste_json, '
        'maengel = EXCLUDED.maengel, ergebnis = EXCLUDED.ergebnis, '
        'naechste_pruefung_datum = EXCLUDED.naechste_pruefung_datum, '
        'aktualisiert_am = EXCLUDED.aktualisiert_am '
        'WHERE sichtpruefungen.firma_id = EXCLUDED.firma_id',
      ),
      parameters: {
        'uuid': s['uuid'] as String,
        'fid': firmaId,
        'vuid': s['verteilerUuid'] as String,
        'datum': s['pruefungDatum'] as String,
        'pn': s['prueferName'],
        'json': s['checklisteJson'],
        'maengel': s['maengel'],
        'erg': s['ergebnis'] as String,
        'next': s['naechstePruefungDatum'],
        'ts': ts,
      },
    );
  }
}
