import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import 'sync_typen.dart';

/// Versionierter Sync (Roadmap Geräteprüfung M3).
///
/// Protokoll pro Datensatz im Push:
/// - `_basisVersion`: Serverversion, auf der die lokale Änderung beruht
///   (`null` = der Client kennt keine Serverfassung). Weicht sie von der
///   aktuellen Serverversion ab, wird **nichts** überschrieben; die Antwort
///   enthält einen Konflikt mit der Serverfassung, den der Nutzer auflöst.
/// - `_zuordnungBestaetigt`: Bei Geräten muss eine Änderung von Kunde,
///   Standort oder Raum ausdrücklich bestätigt sein, sonst Konflikt der
///   Art `zuordnung`. Bestätigte Wechsel landen in `zuordnung_audit`.
/// - Fehlt `_basisVersion` ganz, ist es ein älterer Client: dann gilt der
///   neuere Zeitstempel (`aktualisiertAm`), damit alte App-Versionen
///   weder blockiert werden noch neuere Stände mit alten überschreiben.
class SyncEngine {
  SyncEngine(this.db);
  final Pool db;

  Future<Map<String, dynamic>> push(String firmaId, String? benutzerId, List<Map<String, dynamic>> batches) async {
    final ergebnisse = <Map<String, dynamic>>[];
    final konflikte = <Map<String, dynamic>>[];
    final abgelehnt = <Map<String, String>>[];

    for (final batch in batches) {
      final name = batch['type'] as String?;
      final typ = syncTypen[name];
      if (typ == null) continue;
      for (final raw in batch['items'] as List? ?? const []) {
        final item = (raw as Map).cast<String, dynamic>();
        final uuid = '${item['uuid']}';
        try {
          if (!Uuid.isValidUUID(fromString: uuid)) throw SyncAbgelehnt('Ungültige UUID');
          final r = await db.runTx((tx) => _item(tx, typ, firmaId, benutzerId, item));
          (r['konflikt'] == true ? konflikte : ergebnisse).add(r..remove('konflikt'));
        } on SyncAbgelehnt catch (e) {
          abgelehnt.add({'type': typ.name, 'uuid': uuid, 'grund': e.grund});
        } on ServerException catch (e) {
          // 23503 = Fremdschlüssel: Elterndatensatz fehlt (noch).
          abgelehnt.add({
            'type': typ.name,
            'uuid': uuid,
            'grund': e.code == '23503' ? 'Übergeordneter Datensatz fehlt' : 'Datenbankfehler',
          });
          if (e.code != '23503') print('sync ${typ.name} $uuid: $e');
        }
      }
    }
    return {'ergebnisse': ergebnisse, 'konflikte': konflikte, 'abgelehnt': abgelehnt};
  }

  Future<Map<String, dynamic>> _item(
    TxSession tx,
    SyncTyp typ,
    String firmaId,
    String? benutzerId,
    Map<String, dynamic> item,
  ) async {
    final w = typ.werte(item);
    await typ.pruefen(tx, firmaId, w);

    final rows = await tx.execute(
      Sql.named('SELECT * FROM ${typ.tabelle} WHERE uuid = @u FOR UPDATE'),
      parameters: {'u': w['uuid']},
    );
    Map<String, dynamic> ok(int version) => {'type': typ.name, 'uuid': w['uuid'], 'version': version};

    if (rows.isEmpty) {
      await typ.beimAnlegen?.call(tx, firmaId, w);
      await typ.schreiben(tx, firmaId, w);
      return ok(1);
    }
    final zeile = rows.first.toColumnMap();
    if (zeile['firma_id'].toString() != firmaId) throw SyncAbgelehnt('Datensatz unbekannt');
    // Unveränderte Wiederholung (z. B. erneuter Push nach Verbindungsabbruch)
    // ist kein Änderungsversuch.
    if (item['_basisVersion'] == (zeile['version'] as num).toInt() && _gleich(typ, zeile, w)) {
      return ok((zeile['version'] as num).toInt());
    }
    typ.vorAenderung?.call(zeile, w);
    final serverVersion = (zeile['version'] as num).toInt();

    if (!item.containsKey('_basisVersion')) {
      final neu = ((w['aktualisiert_am'] as TypedValue).value as DateTime);
      final alt = (zeile['aktualisiert_am'] as DateTime).toUtc();
      if (!neu.isAfter(alt)) return ok(serverVersion);
      await typ.schreiben(tx, firmaId, w);
      return ok(serverVersion + 1);
    }

    Map<String, dynamic> konflikt(String art) => {
          'konflikt': true,
          'type': typ.name,
          'uuid': w['uuid'],
          'art': art,
          'version': serverVersion,
          'server': {...typ.zuJson(zeile), 'version': serverVersion},
        };

    final basis = (item['_basisVersion'] as num?)?.toInt();
    if (basis != serverVersion) return konflikt('konflikt');

    final ortGeaendert = typ == geraeteTyp && ortSpalten.any((s) => zeile[s].toString() != w[s]);
    if (ortGeaendert) {
      if (item['_zuordnungBestaetigt'] != true) return konflikt('zuordnung');
      await tx.execute(
        Sql.named(
          'INSERT INTO zuordnung_audit (firma_id, geraet_uuid, alt_kunde_uuid, alt_standort_uuid, '
          'alt_raum_uuid, neu_kunde_uuid, neu_standort_uuid, neu_raum_uuid, benutzer_id) '
          'VALUES (@fid, @g, @ak, @as, @ar, @nk, @ns, @nr, @b)',
        ),
        parameters: {
          'fid': firmaId,
          'g': w['uuid'],
          'ak': zeile['kunde_uuid'].toString(),
          'as': zeile['standort_uuid'].toString(),
          'ar': zeile['raum_uuid'].toString(),
          'nk': w['kunde_uuid'],
          'ns': w['standort_uuid'],
          'nr': w['raum_uuid'],
          'b': benutzerId,
        },
      );
    }
    await typ.schreiben(tx, firmaId, w);
    return ok(serverVersion + 1);
  }

  /// Inhalt gleich (ohne Zeitstempel)? Vergleich über die JSON-Abbildung,
  /// damit Datums-/UUID-Typen keine Rolle spielen.
  bool _gleich(SyncTyp typ, Map<String, dynamic> zeile, Map<String, Object?> w) {
    final neu = <String, dynamic>{...zeile};
    for (final e in w.entries) {
      final v = e.value;
      neu[e.key] = v is TypedValue ? v.value : v;
    }
    Map<String, dynamic> ohneZeit(Map<String, dynamic> m) =>
        typ.zuJson(m)..removeWhere((k, _) => k == 'aktualisiertAm' || k == 'erstelltAm' || k == 'abgeschlossenAm');
    String text(Map<String, dynamic> m) => ohneZeit(m).entries.map((e) => '${e.key}=${e.value}').join('|');
    return text(zeile) == text(neu);
  }

  /// Pull mit Versionen. Kunden, Standorte, Verteiler (Basisdaten) und
  /// Räume immer vollständig; Verteiler-Aufbau und Geräte nur für die
  /// Auswahl, sofern [auswahl] gesetzt ist (`null` = älterer Client, alles).
  /// Ein ausgewählter Kunde deckt Aufbau und Geräte aller seiner Standorte ab.
  Future<Map<String, List<Map<String, dynamic>>>> pull(String firmaId, SyncAuswahl? auswahl) async {
    Future<List<Map<String, dynamic>>> lade(SyncTyp typ, {String filter = '', Map<String, Object?> p = const {}}) async {
      final rows = await db.execute(
        Sql.named('SELECT * FROM ${typ.tabelle} t WHERE t.firma_id = @fid $filter'),
        parameters: {'fid': firmaId, ...p},
      );
      return [
        for (final r in rows)
          {
            ...typ.zuJson(r.toColumnMap()),
            'version': (r.toColumnMap()['version'] as num).toInt(),
          },
      ];
    }

    // Standorte ausgewählter Kunden zählen für Anlagen und Geräte mit.
    var kundenStandorte = const <String>[];
    if (auswahl != null && auswahl.kunden.isNotEmpty) {
      final rows = await db.execute(
        Sql.named('SELECT uuid FROM standorte WHERE firma_id = @fid AND kunde_uuid = ANY(@k)'),
        parameters: {'fid': firmaId, 'k': TypedValue(Type.uuidArray, auswahl.kunden)},
      );
      kundenStandorte = [for (final r in rows) r[0].toString()];
    }
    final standorte = [...?auswahl?.standorte, ...kundenStandorte];

    List<String> verteiler = const [];
    if (auswahl != null && (standorte.isNotEmpty || auswahl.verteiler.isNotEmpty)) {
      final rows = await db.execute(
        Sql.named('SELECT uuid FROM verteiler WHERE firma_id = @fid AND (uuid = ANY(@v) OR standort_uuid = ANY(@s))'),
        parameters: {
          'fid': firmaId,
          'v': TypedValue(Type.uuidArray, auswahl.verteiler),
          's': TypedValue(Type.uuidArray, standorte),
        },
      );
      verteiler = [for (final r in rows) r[0].toString()];
    }
    final vFilter = {'v': TypedValue(Type.uuidArray, verteiler)};
    final gFilter = {
      'gs': TypedValue(Type.uuidArray, [...?auswahl?.geraeteStandorte, ...kundenStandorte]),
      'r': TypedValue(Type.uuidArray, auswahl?.raeume ?? const <String>[]),
    };

    return {
      'kunden': await lade(kundenTyp),
      'standorte': await lade(standorteTyp),
      'verteiler': await lade(verteilerTyp),
      'komponenten': auswahl == null
          ? await lade(komponentenTyp)
          : await lade(komponentenTyp, filter: 'AND t.verteiler_uuid = ANY(@v)', p: vFilter),
      'messungen': auswahl == null
          ? await lade(messungenTyp)
          : await lade(
              messungenTyp,
              filter: 'AND t.komponente_uuid IN '
                  '(SELECT uuid FROM verteiler_komponenten WHERE verteiler_uuid = ANY(@v))',
              p: vFilter,
            ),
      'sichtpruefungen': auswahl == null
          ? await lade(sichtpruefungenTyp)
          : await lade(sichtpruefungenTyp, filter: 'AND t.verteiler_uuid = ANY(@v)', p: vFilter),
      'raeume': await lade(raeumeTyp),
      'geraete': auswahl == null
          ? await lade(geraeteTyp)
          : await lade(geraeteTyp, filter: 'AND (t.standort_uuid = ANY(@gs) OR t.raum_uuid = ANY(@r))', p: gFilter),
      'geraetepruefungen': auswahl == null
          ? await lade(geraetepruefungenTyp)
          : await lade(
              geraetepruefungenTyp,
              filter: 'AND t.geraet_uuid IN '
                  '(SELECT uuid FROM geraete WHERE standort_uuid = ANY(@gs) OR raum_uuid = ANY(@r))',
              p: gFilter,
            ),
    };
  }
}

/// Lokale Auswahl eines Arbeitsgeräts (M9.7 + Geräteprüfung M2).
class SyncAuswahl {
  const SyncAuswahl({
    this.kunden = const [],
    this.standorte = const [],
    this.verteiler = const [],
    this.geraeteStandorte = const [],
    this.raeume = const [],
  });

  /// Ganze Kunden: alle Standorte samt Anlagen und Geräten.
  final List<String> kunden;
  final List<String> standorte;
  final List<String> verteiler;
  final List<String> geraeteStandorte;
  final List<String> raeume;
}
