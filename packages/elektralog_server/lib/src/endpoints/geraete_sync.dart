import 'package:postgres/postgres.dart';

/// Ein Datensatz, den der Server beim Sync bewusst nicht übernimmt
/// (fehlende Pflichtangabe, fremde ID). Landet mit Grund in der
/// Sync-Antwort unter `abgelehnt`, statt still übersprungen zu werden.
class SyncAbgelehnt implements Exception {
  SyncAbgelehnt(this.grund);
  final String grund;
  @override
  String toString() => grund;
}

const schutzklassen = {'I', 'II', 'III'};

/// Räume und Geräte (Roadmap Geräteprüfung M2) im Sync: Validierung,
/// Upsert und Pull. Mandantengrenze: Jede referenzierte ID muss zur Firma
/// des Tokens gehören und zueinander passen (Raum im Standort, Standort
/// beim Kunden) — sonst Ablehnung.
class GeraeteSync {
  GeraeteSync(this.db);
  final Session db;

  static String? _text(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _pflicht(Map<String, dynamic> m, String key, String name) =>
      _text(m, key) ?? (throw SyncAbgelehnt('$name fehlt'));

  Future<void> _standortDerFirma(String firmaId, String standortUuid) async {
    final rows = await db.execute(
      Sql.named('SELECT 1 FROM standorte WHERE uuid = @s AND firma_id = @fid'),
      parameters: {'s': standortUuid, 'fid': firmaId},
    );
    if (rows.isEmpty) throw SyncAbgelehnt('Standort unbekannt');
  }

  /// Bezeichnung, Standort-UUID aus dem Raum — für Pflichtprüfung und
  /// Mandantengrenze ausgelagert, damit Raum- und Geräte-Upsert dieselben
  /// Regeln teilen.
  Map<String, Object?> pruefeRaum(Map<String, dynamic> r) => {
        'uuid': _pflicht(r, 'uuid', 'UUID'),
        'standort': _pflicht(r, 'standortUuid', 'Standort'),
        'bez': _pflicht(r, 'bezeichnung', 'Bezeichnung'),
        'bem': _text(r, 'bemerkung'),
      };

  Future<Map<String, Object?>> pruefeRaumDerFirma(String firmaId, Map<String, dynamic> r) async {
    final p = pruefeRaum(r);
    await _standortDerFirma(firmaId, p['standort'] as String);
    final bestehend = await db.execute(
      Sql.named('SELECT firma_id, standort_uuid FROM raeume WHERE uuid = @u'),
      parameters: {'u': p['uuid']},
    );
    if (bestehend.isNotEmpty) {
      if (bestehend.first[0].toString() != firmaId) throw SyncAbgelehnt('Raum unbekannt');
      if (bestehend.first[1].toString() != p['standort']) {
        throw SyncAbgelehnt('Raum kann nicht in einen anderen Standort verschoben werden');
      }
    }
    return p;
  }

  Future<void> upsertRaum(String firmaId, Map<String, dynamic> r) async {
    final p = await pruefeRaumDerFirma(firmaId, r);
    await db.execute(
      Sql.named(
        'INSERT INTO raeume (uuid, firma_id, standort_uuid, bezeichnung, bemerkung, erstellt_am, aktualisiert_am) '
        'VALUES (@uuid, @fid, @standort, @bez, @bem, COALESCE(@erstellt, NOW()), COALESCE(@ts, NOW())) '
        'ON CONFLICT (uuid) DO UPDATE SET bezeichnung = EXCLUDED.bezeichnung, '
        'bemerkung = EXCLUDED.bemerkung, aktualisiert_am = EXCLUDED.aktualisiert_am '
        'WHERE raeume.firma_id = EXCLUDED.firma_id',
      ),
      parameters: {
        ...p,
        'fid': firmaId,
        'erstellt': TypedValue(Type.timestampTz, _zeit(r['erstelltAm'])),
        'ts': TypedValue(Type.timestampTz, _zeit(r['aktualisiertAm'])),
      },
    );
  }

  Map<String, Object?> pruefeGeraet(Map<String, dynamic> g) {
    final schutzklasse = _text(g, 'schutzklasse');
    if (schutzklasse != null && !schutzklassen.contains(schutzklasse)) {
      throw SyncAbgelehnt('Schutzklasse muss I, II oder III sein');
    }
    final aktiv = g['aktiv'] as bool? ?? true;
    final grund = _text(g, 'inaktivGrund');
    if (!aktiv && grund == null) throw SyncAbgelehnt('Inaktives Gerät braucht einen Grund');
    final intervall = g['pruefintervallMonate'];
    if (intervall != null && (intervall is! int || intervall < 1 || intervall > 24)) {
      throw SyncAbgelehnt('Prüfintervall muss 1–24 ganze Monate sein');
    }
    final letzte = _text(g, 'letztePruefungDatum');
    return {
      'uuid': _pflicht(g, 'uuid', 'UUID'),
      'kunde': _pflicht(g, 'kundeUuid', 'Kunde'),
      'standort': _pflicht(g, 'standortUuid', 'Standort'),
      'raum': _pflicht(g, 'raumUuid', 'Raum'),
      'bez': _pflicht(g, 'bezeichnung', 'Bezeichnung'),
      'hersteller': _text(g, 'hersteller'),
      'typ': _text(g, 'typ'),
      'sn': _text(g, 'seriennummer'),
      'inv': _text(g, 'inventarnummer'),
      'schutzart': _text(g, 'schutzart'),
      'sk': schutzklasse,
      'aktiv': aktiv,
      'grund': aktiv ? null : grund,
      'intervall': intervall,
      'begruendung': _text(g, 'intervallBegruendung'),
      'letzte': letzte == null ? null : TypedValue(Type.date, _tag(letzte)),
      'ersatz': g['letztePruefungErsatzwert'] as bool? ?? false,
      'historie': _text(g, 'statusHistorieJson'),
      'bem': _text(g, 'bemerkung'),
    };
  }

  /// Prüft, dass Raum, Standort und Kunde der Firma gehören und
  /// zusammenpassen. Liefert die Parameter für den Upsert.
  Future<Map<String, Object?>> pruefeGeraetDerFirma(String firmaId, Map<String, dynamic> g) async {
    final p = pruefeGeraet(g);
    final rows = await db.execute(
      Sql.named(
        'SELECT 1 FROM raeume r JOIN standorte s ON s.uuid = r.standort_uuid '
        'WHERE r.uuid = @raum AND r.firma_id = @fid AND s.firma_id = @fid '
        'AND s.uuid = @standort AND s.kunde_uuid = @kunde',
      ),
      parameters: {'raum': p['raum'], 'standort': p['standort'], 'kunde': p['kunde'], 'fid': firmaId},
    );
    if (rows.isEmpty) throw SyncAbgelehnt('Kunde, Standort und Raum passen nicht zusammen oder sind unbekannt');
    final fremd = await db.execute(
      Sql.named('SELECT 1 FROM geraete WHERE uuid = @u AND firma_id <> @fid'),
      parameters: {'u': p['uuid'], 'fid': firmaId},
    );
    if (fremd.isNotEmpty) throw SyncAbgelehnt('Gerät unbekannt');
    return p;
  }

  Future<void> upsertGeraet(String firmaId, Map<String, dynamic> g) async {
    final p = await pruefeGeraetDerFirma(firmaId, g);
    await db.execute(
      Sql.named(
        'INSERT INTO geraete (uuid, firma_id, kunde_uuid, standort_uuid, raum_uuid, bezeichnung, '
        'hersteller, typ, seriennummer, inventarnummer, schutzart, schutzklasse, aktiv, inaktiv_grund, '
        'pruefintervall_monate, intervall_begruendung, letzte_pruefung_datum, letzte_pruefung_ersatzwert, '
        'status_historie_json, bemerkung, erstellt_am, aktualisiert_am) '
        'VALUES (@uuid, @fid, @kunde, @standort, @raum, @bez, @hersteller, @typ, @sn, @inv, @schutzart, '
        '@sk, @aktiv, @grund, @intervall, @begruendung, @letzte, @ersatz, @historie, @bem, '
        'COALESCE(@erstellt, NOW()), COALESCE(@ts, NOW())) '
        'ON CONFLICT (uuid) DO UPDATE SET kunde_uuid = EXCLUDED.kunde_uuid, '
        'standort_uuid = EXCLUDED.standort_uuid, raum_uuid = EXCLUDED.raum_uuid, '
        'bezeichnung = EXCLUDED.bezeichnung, hersteller = EXCLUDED.hersteller, typ = EXCLUDED.typ, '
        'seriennummer = EXCLUDED.seriennummer, inventarnummer = EXCLUDED.inventarnummer, '
        'schutzart = EXCLUDED.schutzart, schutzklasse = EXCLUDED.schutzklasse, aktiv = EXCLUDED.aktiv, '
        'inaktiv_grund = EXCLUDED.inaktiv_grund, pruefintervall_monate = EXCLUDED.pruefintervall_monate, '
        'intervall_begruendung = EXCLUDED.intervall_begruendung, '
        'letzte_pruefung_datum = EXCLUDED.letzte_pruefung_datum, '
        'letzte_pruefung_ersatzwert = EXCLUDED.letzte_pruefung_ersatzwert, '
        'status_historie_json = EXCLUDED.status_historie_json, bemerkung = EXCLUDED.bemerkung, '
        'aktualisiert_am = EXCLUDED.aktualisiert_am '
        'WHERE geraete.firma_id = EXCLUDED.firma_id',
      ),
      parameters: {
        ...p,
        'fid': firmaId,
        'erstellt': TypedValue(Type.timestampTz, _zeit(g['erstelltAm'])),
        'ts': TypedValue(Type.timestampTz, _zeit(g['aktualisiertAm'])),
      },
    );
  }

  /// Kalendertag ohne Zeitzonenverschiebung (`2026-03-31` bleibt der 31.).
  static DateTime _tag(String s) {
    final d = DateTime.tryParse(s.split('T').first) ?? (throw SyncAbgelehnt('Ungültiges Datum: $s'));
    return DateTime.utc(d.year, d.month, d.day);
  }

  static DateTime? _zeit(Object? v) => v is String ? DateTime.tryParse(v)?.toUtc() : null;

  static String _iso(Object? v) => (v as DateTime).toUtc().toIso8601String();

  static Map<String, dynamic> raumJson(ResultRow r) {
    final m = r.toColumnMap();
    return {
      'uuid': m['uuid'].toString(),
      'standortUuid': m['standort_uuid'].toString(),
      'bezeichnung': m['bezeichnung'],
      'bemerkung': m['bemerkung'],
      'erstelltAm': _iso(m['erstellt_am']),
      'aktualisiertAm': _iso(m['aktualisiert_am']),
    };
  }

  static Map<String, dynamic> geraetJson(ResultRow r) {
    final m = r.toColumnMap();
    final letzte = m['letzte_pruefung_datum'] as DateTime?;
    return {
      'uuid': m['uuid'].toString(),
      'kundeUuid': m['kunde_uuid'].toString(),
      'standortUuid': m['standort_uuid'].toString(),
      'raumUuid': m['raum_uuid'].toString(),
      'bezeichnung': m['bezeichnung'],
      'hersteller': m['hersteller'],
      'typ': m['typ'],
      'seriennummer': m['seriennummer'],
      'inventarnummer': m['inventarnummer'],
      'schutzart': m['schutzart'],
      'schutzklasse': m['schutzklasse'],
      'aktiv': m['aktiv'],
      'inaktivGrund': m['inaktiv_grund'],
      'pruefintervallMonate': m['pruefintervall_monate'],
      'intervallBegruendung': m['intervall_begruendung'],
      'letztePruefungDatum': letzte == null ? null : _datum(letzte),
      'letztePruefungErsatzwert': m['letzte_pruefung_ersatzwert'],
      'statusHistorieJson': m['status_historie_json'],
      'bemerkung': m['bemerkung'],
      'erstelltAm': _iso(m['erstellt_am']),
      'aktualisiertAm': _iso(m['aktualisiert_am']),
    };
  }

  static String _datum(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Räume immer vollständig (Grunddaten zum Auswählen), Geräte nur für
  /// die angeforderten Standorte/Räume. [alle] = älterer Client ohne
  /// Auswahl-Parameter.
  Future<Map<String, List<Map<String, dynamic>>>> pull(
    String firmaId, {
    required bool alle,
    required List<String> standorte,
    required List<String> raeume,
  }) async {
    final raumRows = await db.execute(
      Sql.named('SELECT * FROM raeume WHERE firma_id = @fid ORDER BY bezeichnung'),
      parameters: {'fid': firmaId},
    );
    final geraetRows = alle
        ? await db.execute(
            Sql.named('SELECT * FROM geraete WHERE firma_id = @fid'),
            parameters: {'fid': firmaId},
          )
        : await db.execute(
            Sql.named(
              'SELECT * FROM geraete WHERE firma_id = @fid '
              'AND (standort_uuid = ANY(@s) OR raum_uuid = ANY(@r))',
            ),
            parameters: {
              'fid': firmaId,
              's': TypedValue(Type.uuidArray, standorte),
              'r': TypedValue(Type.uuidArray, raeume),
            },
          );
    return {
      'raeume': [for (final r in raumRows) raumJson(r)],
      'geraete': [for (final r in geraetRows) geraetJson(r)],
    };
  }
}
