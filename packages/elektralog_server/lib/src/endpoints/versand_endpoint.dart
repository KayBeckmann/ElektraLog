import 'dart:convert';
import 'dart:typed_data';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../mail/mail_versand.dart';
import '../middleware/auth_middleware.dart';
import '../sync/sync_typen.dart' show emailGueltig;

/// SMTP-Zugang der Firma und Versand archivierter Protokolle per E-Mail
/// (Roadmap-Nachtrag 20./21.11.2026).
///
/// GET    /api/firma/smtp           — Zugang ohne Passwort (Firmenadmin)
/// PUT    /api/firma/smtp           — Zugang speichern (Firmenadmin)
/// DELETE /api/firma/smtp           — Zugang entfernen (Firmenadmin)
/// POST   /api/firma/smtp/test      — Testmail mit gespeichertem Zugang
/// GET    /api/protokolle/:id/versand — Empfängervorschlag + Verlauf
/// POST   /api/protokolle/:id/versand — archiviertes PDF versenden
///
/// Verschickt wird immer genau das archivierte PDF; der Client bestätigt
/// über `pdfHash`, welche Fassung er angezeigt hat. Eine wiederholte
/// Anfrage mit derselben `anfrageId` (z. B. nach Timeout) verschickt
/// nichts erneut, sondern liefert den bekannten Stand.
class VersandEndpoint {
  VersandEndpoint(this.db, this.mail, this.geheimnis);
  final Pool db;
  final MailVersand mail;
  final SmtpGeheimnis geheimnis;

  static const _tlsModi = {'ssl', 'starttls', 'keine'};

  static Response _json(int status, Object body) =>
      Response(status, body: jsonEncode(body), headers: {'Content-Type': 'application/json'});

  /// Firmenadmin laut Datenbank statt laut bis zu 30 Tage altem Token
  /// (wie beim Umschalten der Module).
  Future<Response?> _nurFirmenadmin(Map<String, dynamic>? claims) async {
    if (claims == null) return _json(401, {'error': 'Nicht authentifiziert'});
    final rows = await db.execute(
      Sql.named(
        'SELECT 1 FROM benutzer b '
        'JOIN benutzer_rollen br ON br.benutzer_id = b.id '
        'JOIN rollen r ON r.id = br.rollen_id '
        "WHERE b.id = @bid AND b.firma_id = @fid AND b.status = 'aktiv' "
        'AND r.firma_id = @fid AND r.ist_vorlage = true',
      ),
      parameters: {'bid': claims['sub'], 'fid': claims['firmaId']},
    );
    if (rows.isEmpty) return _json(403, {'error': 'Nur der Firmenadmin kann den SMTP-Zugang verwalten'});
    return null;
  }

  // ── SMTP-Zugang ─────────────────────────────────────────────────────────────

  Future<Response> getSmtp(Request request) async {
    final claims = verifyJwt(request);
    final verboten = await _nurFirmenadmin(claims);
    if (verboten != null) return verboten;
    final rows = await db.execute(
      Sql.named('SELECT host, port, tls_modus, absender_email, absender_name, benutzer, '
          'passwort_verschluesselt IS NOT NULL FROM firmen_smtp WHERE firma_id = @fid'),
      parameters: {'fid': claims!['firmaId']},
    );
    if (rows.isEmpty) return _json(200, {'konfiguriert': false});
    final r = rows.first;
    return _json(200, {
      'konfiguriert': true,
      'host': r[0],
      'port': r[1],
      'tlsModus': r[2],
      'absenderEmail': r[3],
      'absenderName': r[4],
      'benutzer': r[5],
      // Das Passwort selbst verlässt den Server nie.
      'passwortGesetzt': r[6],
    });
  }

  // Body: host, port, tlsModus, absenderEmail, absenderName?, benutzer?,
  // passwort? (fehlt = unverändert, null/leer = entfernen)
  Future<Response> putSmtp(Request request) async {
    final claims = verifyJwt(request);
    final verboten = await _nurFirmenadmin(claims);
    if (verboten != null) return verboten;
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return _json(400, {'error': 'Ungültiger JSON-Body'});
    }
    String? text(String k) {
      final v = body[k];
      if (v is! String || v.trim().isEmpty) return null;
      return v.trim();
    }

    final host = text('host');
    final port = body['port'];
    final tls = text('tlsModus');
    final absender = text('absenderEmail');
    if (host == null) return _json(400, {'error': 'SMTP-Server fehlt'});
    if (port is! int || port < 1 || port > 65535) return _json(400, {'error': 'Port muss zwischen 1 und 65535 liegen'});
    if (!_tlsModi.contains(tls)) return _json(400, {'error': 'TLS-Modus muss ssl, starttls oder keine sein'});
    if (absender == null || !emailGueltig(absender)) return _json(400, {'error': 'Absender-E-Mail ungültig'});

    final passwortAendern = body.containsKey('passwort');
    final passwort = text('passwort');
    await db.execute(
      Sql.named(
        'INSERT INTO firmen_smtp (firma_id, host, port, tls_modus, absender_email, absender_name, benutzer, '
        'passwort_verschluesselt) VALUES (@fid, @host, @port, @tls, @abs, @name, @ben, @pw) '
        'ON CONFLICT (firma_id) DO UPDATE SET host = EXCLUDED.host, port = EXCLUDED.port, '
        'tls_modus = EXCLUDED.tls_modus, absender_email = EXCLUDED.absender_email, '
        'absender_name = EXCLUDED.absender_name, benutzer = EXCLUDED.benutzer, '
        '${passwortAendern ? 'passwort_verschluesselt = EXCLUDED.passwort_verschluesselt, ' : ''}'
        'aktualisiert_am = NOW()',
      ),
      parameters: {
        'fid': claims!['firmaId'],
        'host': host,
        'port': port,
        'tls': tls,
        'abs': absender,
        'name': text('absenderName'),
        'ben': text('benutzer'),
        'pw': passwort == null ? null : geheimnis.verschluesseln(passwort),
      },
    );
    return getSmtp(request);
  }

  Future<Response> deleteSmtp(Request request) async {
    final claims = verifyJwt(request);
    final verboten = await _nurFirmenadmin(claims);
    if (verboten != null) return verboten;
    await db.execute(Sql.named('DELETE FROM firmen_smtp WHERE firma_id = @fid'),
        parameters: {'fid': claims!['firmaId']});
    return _json(200, {'konfiguriert': false});
  }

  // Body: { "empfaenger": "..." }
  Future<Response> testSmtp(Request request) async {
    final claims = verifyJwt(request);
    final verboten = await _nurFirmenadmin(claims);
    if (verboten != null) return verboten;
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return _json(400, {'error': 'Ungültiger JSON-Body'});
    }
    final an = (body['empfaenger'] as String?)?.trim() ?? '';
    if (!emailGueltig(an)) return _json(400, {'error': 'Empfänger-E-Mail ungültig'});
    final zugang = await _zugang(claims!['firmaId'] as String);
    if (zugang case Response fehler) return fehler;
    try {
      await mail.senden(
        zugang as SmtpZugang,
        MailNachricht(
          an: an,
          betreff: 'ElektraLog — Testnachricht',
          text: 'Diese Testnachricht bestätigt, dass ElektraLog Prüfprotokolle über '
              '${zugang.host} versenden kann.',
        ),
      );
    } on MailVersandFehler catch (e) {
      return _json(502, {'error': e.meldung});
    }
    return _json(200, {'ok': true});
  }

  /// Entschlüsselter Zugang der Firma oder eine Fehlerantwort.
  Future<Object> _zugang(String firmaId) async {
    final rows = await db.execute(
      Sql.named('SELECT host, port, tls_modus, absender_email, absender_name, benutzer, passwort_verschluesselt '
          'FROM firmen_smtp WHERE firma_id = @fid'),
      parameters: {'fid': firmaId},
    );
    if (rows.isEmpty) return _json(409, {'error': 'Für diese Firma ist kein SMTP-Server eingerichtet'});
    final r = rows.first;
    String? passwort;
    if (r[6] case final String gespeichert) {
      passwort = geheimnis.entschluesseln(gespeichert);
      if (passwort == null) {
        return _json(409, {
          'error': 'Das gespeicherte SMTP-Passwort ist nicht mehr lesbar (Serverschlüssel geändert) — '
              'bitte in den Firmeneinstellungen neu eingeben',
        });
      }
    }
    return SmtpZugang(
      host: r[0] as String,
      port: r[1] as int,
      tlsModus: r[2] as String,
      absenderEmail: r[3] as String,
      absenderName: r[4] as String?,
      benutzer: r[5] as String?,
      passwort: passwort,
    );
  }

  // ── Protokollversand ───────────────────────────────────────────────────────

  /// Standort des Protokolls über seinen Bezug (Verteiler, Standort, Raum
  /// oder Gerät); ältere Protokolle ohne Bezug haben keinen.
  static const _protokollSql = '''
    SELECT p.id, p.art, p.verteiler_bezeichnung, p.standort_bezeichnung, p.kunden_bezeichnung,
           p.protokoll_datum, p.pdf_hash, p.firma_name,
           s.uuid, s.bezeichnung, s.kontakt_person, s.kontakt_email, s.kontakt_telefon,
           k.uuid, k.name, k.ansprechpartner, k.kontakt_email
    FROM protokolle p
    LEFT JOIN standorte s ON s.firma_id = p.firma_id AND s.uuid = COALESCE(
      (SELECT v.standort_uuid FROM verteiler v WHERE v.uuid = p.bezug_uuid AND v.firma_id = p.firma_id),
      (SELECT st.uuid FROM standorte st WHERE st.uuid = p.bezug_uuid AND st.firma_id = p.firma_id),
      (SELECT r.standort_uuid FROM raeume r WHERE r.uuid = p.bezug_uuid AND r.firma_id = p.firma_id),
      (SELECT g.standort_uuid FROM geraete g WHERE g.uuid = p.bezug_uuid AND g.firma_id = p.firma_id))
    LEFT JOIN kunden k ON k.firma_id = p.firma_id AND k.uuid = s.kunde_uuid
    WHERE p.id = @id AND p.firma_id = @fid''';

  Future<ResultRow?> _protokoll(String id, String firmaId) async {
    final rows = await db.execute(Sql.named(_protokollSql), parameters: {'id': id, 'fid': firmaId});
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> _verlauf(String protokollId, String firmaId) async {
    final rows = await db.execute(
      Sql.named('SELECT v.id, v.empfaenger, v.cc, v.status, v.fehler, v.erstellt_am, v.abgeschlossen_am, b.name '
          'FROM protokoll_versand v LEFT JOIN benutzer b ON b.id = v.benutzer_id '
          'WHERE v.protokoll_id = @pid AND v.firma_id = @fid ORDER BY v.erstellt_am DESC'),
      parameters: {'pid': protokollId, 'fid': firmaId},
    );
    return [for (final r in rows) _versandJson(r)];
  }

  static Map<String, dynamic> _versandJson(ResultRow r) => {
        'id': r[0].toString(),
        'empfaenger': r[1],
        'cc': r[2],
        'status': r[3],
        'fehler': r[4],
        'erstelltAm': (r[5] as DateTime).toUtc().toIso8601String(),
        'abgeschlossenAm': (r[6] as DateTime?)?.toUtc().toIso8601String(),
        'benutzer': r[7],
      };

  static String _datum(DateTime d) {
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}.${l.year}';
  }

  /// Gleicher Dateiname wie beim PDF-Download.
  static String _dateiname(ResultRow p) {
    final bezeichnung = (p[2] as String?)?.replaceAll(' ', '_') ?? 'Protokoll';
    return 'Protokoll_${bezeichnung}_${p[5].toString().substring(0, 10)}.pdf';
  }

  Future<Response> info(Request request, String id) async {
    final claims = verifyJwt(request);
    if (claims == null) return _json(401, {'error': 'Nicht authentifiziert'});
    if (!Uuid.isValidUUID(fromString: id)) return _json(400, {'error': 'Ungültige UUID'});
    final firmaId = claims['firmaId'] as String;
    final p = await _protokoll(id, firmaId);
    if (p == null) return _json(404, {'error': 'Nicht gefunden'});
    final smtp = await db.execute(Sql.named('SELECT 1 FROM firmen_smtp WHERE firma_id = @fid'),
        parameters: {'fid': firmaId});
    return _json(200, {
      'smtpKonfiguriert': smtp.isNotEmpty,
      'pdfHash': p[6],
      'dateiname': _dateiname(p),
      'standort': p[8] == null
          ? null
          : {
              'uuid': p[8].toString(),
              'bezeichnung': p[9],
              'kontaktPerson': p[10],
              'kontaktEmail': p[11],
              'kontaktTelefon': p[12],
            },
      'kunde': p[13] == null
          ? null
          : {'uuid': p[13].toString(), 'name': p[14], 'ansprechpartner': p[15], 'kontaktEmail': p[16]},
      'verlauf': await _verlauf(id, firmaId),
    });
  }

  // Body: { "anfrageId", "empfaenger", "cc"?: [...], "pdfHash" }
  Future<Response> senden(Request request, String id) async {
    final claims = verifyJwt(request);
    if (claims == null) return _json(401, {'error': 'Nicht authentifiziert'});
    if (!Uuid.isValidUUID(fromString: id)) return _json(400, {'error': 'Ungültige UUID'});
    final firmaId = claims['firmaId'] as String;
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return _json(400, {'error': 'Ungültiger JSON-Body'});
    }

    final anfrageId = body['anfrageId'];
    if (anfrageId is! String || !Uuid.isValidUUID(fromString: anfrageId)) {
      return _json(400, {'error': 'anfrageId (UUID) fehlt'});
    }
    final an = (body['empfaenger'] as String?)?.trim() ?? '';
    if (!emailGueltig(an)) return _json(400, {'error': 'Empfänger-E-Mail fehlt oder ist ungültig'});
    final ccRoh = body['cc'] ?? const [];
    if (ccRoh is! List) return _json(400, {'error': 'cc muss eine Liste sein'});
    final cc = [for (final c in ccRoh) c.toString().trim()]..removeWhere((c) => c.isEmpty);
    final ungueltig = cc.where((c) => !emailGueltig(c)).toList();
    if (ungueltig.isNotEmpty) return _json(400, {'error': 'CC-Adresse ungültig: ${ungueltig.join(', ')}'});
    if (cc.length > 10) return _json(400, {'error': 'Höchstens 10 CC-Empfänger'});

    // Wiederholte Anfrage: nichts erneut senden.
    final bekannt = await db.execute(
      Sql.named('SELECT v.id, v.empfaenger, v.cc, v.status, v.fehler, v.erstellt_am, v.abgeschlossen_am, b.name '
          'FROM protokoll_versand v LEFT JOIN benutzer b ON b.id = v.benutzer_id '
          'WHERE v.firma_id = @fid AND v.anfrage_id = @aid'),
      parameters: {'fid': firmaId, 'aid': anfrageId},
    );
    if (bekannt.isNotEmpty) return _json(200, {..._versandJson(bekannt.first), 'wiederholt': true});

    final p = await _protokoll(id, firmaId);
    if (p == null) return _json(404, {'error': 'Nicht gefunden'});
    if (body['pdfHash'] != p[6]) {
      return _json(409, {'error': 'Die angezeigte PDF-Fassung entspricht nicht dem Archiv — bitte neu laden'});
    }
    final zugang = await _zugang(firmaId);
    if (zugang case Response fehler) return fehler;

    final eingefuegt = await db.execute(
      Sql.named('INSERT INTO protokoll_versand (firma_id, protokoll_id, anfrage_id, empfaenger, cc, pdf_hash, '
          "status, benutzer_id) VALUES (@fid, @pid, @aid, @an, @cc, @hash, 'laeuft', @bid) "
          'ON CONFLICT (firma_id, anfrage_id) DO NOTHING RETURNING id'),
      parameters: {
        'fid': firmaId,
        'pid': id,
        'aid': anfrageId,
        'an': an,
        'cc': TypedValue(Type.textArray, cc),
        'hash': p[6],
        'bid': claims['sub'],
      },
    );
    // Parallel dieselbe Anfrage: die andere verschickt.
    if (eingefuegt.isEmpty) return _json(409, {'error': 'Dieser Versand läuft bereits'});
    final versandId = eingefuegt.first[0].toString();

    final pdf = await db.execute(Sql.named('SELECT pdf_data FROM protokolle WHERE id = @id AND firma_id = @fid'),
        parameters: {'id': id, 'fid': firmaId});
    final raw = pdf.first[0];
    final bytes = raw is Uint8List ? raw : Uint8List.fromList(raw as List<int>);
    final datum = _datum(p[5] as DateTime);
    final ort = (p[9] ?? p[3]) as String?;
    final art = p[1] == 'geraete' ? 'Geräteprüfung' : 'Anlagenprüfung';

    String? fehler;
    try {
      await mail.senden(
        zugang as SmtpZugang,
        MailNachricht(
          an: an,
          cc: cc,
          betreff: 'Prüfprotokoll $art${ort == null ? '' : ' — $ort'} vom $datum',
          text: 'Guten Tag,\n\n'
              'im Anhang erhalten Sie das Protokoll der $art vom $datum'
              '${ort == null ? '' : ' für den Standort $ort'}.\n\n'
              'Mit freundlichen Grüßen\n'
              '${p[7] ?? ''}',
          anhaenge: [MailAnhang(_dateiname(p), bytes)],
        ),
      );
    } on MailVersandFehler catch (e) {
      fehler = e.meldung;
    } catch (e) {
      fehler = 'Unerwarteter Fehler beim Versand';
      print('versand.senden error: ${e.runtimeType}');
    }

    final rows = await db.execute(
      Sql.named('UPDATE protokoll_versand SET status = @st, fehler = @f, abgeschlossen_am = NOW() '
          'WHERE id = @id RETURNING id, empfaenger, cc, status, fehler, erstellt_am, abgeschlossen_am, '
          '(SELECT name FROM benutzer WHERE id = benutzer_id)'),
      parameters: {'id': versandId, 'st': fehler == null ? 'gesendet' : 'fehler', 'f': fehler},
    );
    final ergebnis = _versandJson(rows.first);
    return fehler == null ? _json(200, ergebnis) : _json(502, {...ergebnis, 'error': fehler});
  }
}

