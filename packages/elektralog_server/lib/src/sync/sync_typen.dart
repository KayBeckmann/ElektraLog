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

/// Beschreibung eines synchronisierten Datensatztyps: Tabelle, Abbildung
/// Zeile → JSON (gleiches Format wie die App-Modelle), Validierung samt
/// Mandantengrenze der Elterndatensätze und die zu schreibenden Spalten.
class SyncTyp {
  const SyncTyp({
    required this.name,
    required this.tabelle,
    required this.zuJson,
    required this.werte,
    required this.updateSpalten,
    this.eltern = const [],
    this.zusatzPruefung,
    this.beimAnlegen,
    this.vorAenderung,
  });

  /// Name im Sync-Protokoll (`type`), z. B. `kunden`.
  final String name;
  final String tabelle;
  final Map<String, dynamic> Function(Map<String, dynamic> zeile) zuJson;

  /// Spalte → Wert für INSERT (ohne firma_id/version). Wirft
  /// [SyncAbgelehnt] bei fehlenden Pflichtangaben.
  final Map<String, Object?> Function(Map<String, dynamic> item) werte;

  /// Spalten, die bei einem Update überschrieben werden. Eltern-Spalten,
  /// die sich nie ändern dürfen (z. B. Standort eines Verteilers), fehlen.
  final List<String> updateSpalten;

  /// (Spalte, Elterntabelle): referenzierte Datensätze müssen der Firma
  /// gehören. `null`-Werte (z. B. Wurzelkomponente) sind erlaubt.
  final List<(String, String)> eltern;

  /// Typ-spezifische Prüfung mit DB-Zugriff (z. B. Raum ↔ Standort).
  final Future<void> Function(Session tx, String firmaId, Map<String, Object?> werte)? zusatzPruefung;

  /// Nur für neue Datensätze (z. B. keine neue Prüfung für inaktive Geräte).
  final Future<void> Function(Session tx, String firmaId, Map<String, Object?> werte)? beimAnlegen;

  /// Darf die vorhandene [zeile] überhaupt geändert werden?
  final void Function(Map<String, dynamic> zeile, Map<String, Object?> werte)? vorAenderung;

  Future<void> pruefen(Session tx, String firmaId, Map<String, Object?> w) async {
    for (final (spalte, elternTabelle) in eltern) {
      final id = w[spalte];
      if (id == null) continue;
      final rows = await tx.execute(
        Sql.named('SELECT 1 FROM $elternTabelle WHERE uuid = @id AND firma_id = @fid'),
        parameters: {'id': id, 'fid': firmaId},
      );
      if (rows.isEmpty) throw SyncAbgelehnt('Übergeordneter Datensatz ($spalte) unbekannt');
    }
    await zusatzPruefung?.call(tx, firmaId, w);
  }

  /// Upsert mit Versionssprung. Firmenfremde Zeilen werden nie berührt.
  Future<void> schreiben(Session tx, String firmaId, Map<String, Object?> w) async {
    final spalten = w.keys.toList();
    await tx.execute(
      Sql.named(
        'INSERT INTO $tabelle (${spalten.join(', ')}, firma_id, version) '
        'VALUES (${spalten.map((s) => '@$s').join(', ')}, @firma_id, 1) '
        'ON CONFLICT (uuid) DO UPDATE SET '
        '${updateSpalten.map((s) => '$s = EXCLUDED.$s').join(', ')}, '
        'version = $tabelle.version + 1 '
        'WHERE $tabelle.firma_id = EXCLUDED.firma_id',
      ),
      parameters: {...w, 'firma_id': firmaId},
    );
  }
}

// ── Hilfen für Werte ──────────────────────────────────────────────────────────

String? _text(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

String _pflicht(Map<String, dynamic> m, String key, String name) =>
    _text(m, key) ?? (throw SyncAbgelehnt('$name fehlt'));

/// Kalendertag ohne Zeitzonenverschiebung (`2026-03-31` bleibt der 31.).
TypedValue _tag(String? s) {
  if (s == null) return TypedValue(Type.date, null);
  final d = DateTime.tryParse(s.split('T').first) ?? (throw SyncAbgelehnt('Ungültiges Datum: $s'));
  return TypedValue(Type.date, DateTime.utc(d.year, d.month, d.day));
}

/// Zeitstempel des Clients; ohne Angabe „jetzt“.
TypedValue _zeit(Object? v) =>
    TypedValue(Type.timestampTz, (v is String ? DateTime.tryParse(v)?.toUtc() : null) ?? DateTime.now().toUtc());

String _iso(Object? v) => (v as DateTime).toUtc().toIso8601String();

String? _datum(Object? v) {
  if (v is! DateTime) return null;
  return '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
}

Map<String, Object?> _zeiten(Map<String, dynamic> item) => {
      'erstellt_am': _zeit(item['erstelltAm']),
      'aktualisiert_am': _zeit(item['aktualisiertAm']),
    };

Map<String, dynamic> _zeitenJson(Map<String, dynamic> z) => {
      'erstelltAm': _iso(z['erstellt_am']),
      'aktualisiertAm': _iso(z['aktualisiert_am']),
    };

// ── Typen ─────────────────────────────────────────────────────────────────────

final kundenTyp = SyncTyp(
  name: 'kunden',
  tabelle: 'kunden',
  werte: (k) => {
    'uuid': _pflicht(k, 'uuid', 'UUID'),
    'name': _pflicht(k, 'name', 'Name'),
    'strasse': k['strasse'],
    'plz': k['plz'],
    'ort': k['ort'],
    'kontakt_email': k['kontaktEmail'],
    'kontakt_telefon': k['kontaktTelefon'],
    ..._zeiten(k),
  },
  updateSpalten: ['name', 'strasse', 'plz', 'ort', 'kontakt_email', 'kontakt_telefon', 'aktualisiert_am'],
  zuJson: (z) => {
    'uuid': z['uuid'].toString(),
    'name': z['name'],
    'strasse': z['strasse'],
    'plz': z['plz'],
    'ort': z['ort'],
    'kontaktEmail': z['kontakt_email'],
    'kontaktTelefon': z['kontakt_telefon'],
    ..._zeitenJson(z),
  },
);

final standorteTyp = SyncTyp(
  name: 'standorte',
  tabelle: 'standorte',
  eltern: [('kunde_uuid', 'kunden')],
  werte: (s) => {
    'uuid': _pflicht(s, 'uuid', 'UUID'),
    'kunde_uuid': _pflicht(s, 'kundeUuid', 'Kunde'),
    'bezeichnung': _pflicht(s, 'bezeichnung', 'Bezeichnung'),
    'strasse': s['strasse'],
    'plz': s['plz'],
    'ort': s['ort'],
    ..._zeiten(s),
  },
  updateSpalten: ['bezeichnung', 'strasse', 'plz', 'ort', 'aktualisiert_am'],
  zuJson: (z) => {
    'uuid': z['uuid'].toString(),
    'kundeUuid': z['kunde_uuid'].toString(),
    'bezeichnung': z['bezeichnung'],
    'strasse': z['strasse'],
    'plz': z['plz'],
    'ort': z['ort'],
    ..._zeitenJson(z),
  },
);

final verteilerTyp = SyncTyp(
  name: 'verteiler',
  tabelle: 'verteiler',
  eltern: [('standort_uuid', 'standorte')],
  werte: (v) => {
    'uuid': _pflicht(v, 'uuid', 'UUID'),
    'standort_uuid': _pflicht(v, 'standortUuid', 'Standort'),
    'bezeichnung': _pflicht(v, 'bezeichnung', 'Bezeichnung'),
    'bemerkung': v['bemerkung'],
    'anlagendaten_json': v['anlagendatenJson'],
    'pruefintervall_jahre': (v['pruefintervallJahre'] as num?)?.toInt() ?? 4,
    ..._zeiten(v),
  },
  updateSpalten: ['bezeichnung', 'bemerkung', 'anlagendaten_json', 'pruefintervall_jahre', 'aktualisiert_am'],
  zuJson: (z) => {
    'uuid': z['uuid'].toString(),
    'standortUuid': z['standort_uuid'].toString(),
    'bezeichnung': z['bezeichnung'],
    'bemerkung': z['bemerkung'],
    'anlagendatenJson': z['anlagendaten_json'],
    'pruefintervallJahre': z['pruefintervall_jahre'],
    ..._zeitenJson(z),
  },
);

final komponentenTyp = SyncTyp(
  name: 'komponenten',
  tabelle: 'verteiler_komponenten',
  eltern: [('verteiler_uuid', 'verteiler'), ('parent_uuid', 'verteiler_komponenten')],
  werte: (k) {
    final bmk = k['betriebsmittelkennzeichen'] as String? ?? '';
    final ziel = k['zielbezeichnung'] as String? ?? '';
    return {
      'uuid': _pflicht(k, 'uuid', 'UUID'),
      'verteiler_uuid': _pflicht(k, 'verteilerUuid', 'Verteiler'),
      'parent_uuid': _text(k, 'parentUuid'),
      'typ': _pflicht(k, 'typ', 'Typ'),
      'betriebsmittelkennzeichen': bmk,
      'zielbezeichnung': ziel,
      'bezeichnung': ziel.isNotEmpty ? ziel : bmk,
      'position': (k['position'] as num?)?.toInt() ?? 0,
      'eigenschaften_json': k['eigenschaftenJson'],
      ..._zeiten(k),
    };
  },
  updateSpalten: [
    'parent_uuid',
    'typ',
    'betriebsmittelkennzeichen',
    'zielbezeichnung',
    'bezeichnung',
    'position',
    'eigenschaften_json',
    'aktualisiert_am',
  ],
  zuJson: (z) => {
    'uuid': z['uuid'].toString(),
    'verteilerUuid': z['verteiler_uuid'].toString(),
    'parentUuid': z['parent_uuid']?.toString(),
    'typ': z['typ'],
    'betriebsmittelkennzeichen': z['betriebsmittelkennzeichen'] ?? '',
    'zielbezeichnung': z['zielbezeichnung'] ?? '',
    'position': z['position'],
    'eigenschaftenJson': z['eigenschaften_json'],
    ..._zeitenJson(z),
  },
);

final messungenTyp = SyncTyp(
  name: 'messungen',
  tabelle: 'messungen',
  eltern: [('komponente_uuid', 'verteiler_komponenten')],
  werte: (m) => {
    'uuid': _pflicht(m, 'uuid', 'UUID'),
    'komponente_uuid': _pflicht(m, 'komponenteUuid', 'Komponente'),
    'norm': m['norm'] as String? ?? 'vde_0100',
    'pruefung_datum': _tag(_pflicht(m, 'pruefungDatum', 'Prüfdatum')),
    'pruefer_name': m['prueferName'],
    'messwert_json': m['messwertJson'],
    'ergebnis': _pflicht(m, 'ergebnis', 'Ergebnis'),
    'bemerkung': m['bemerkung'],
    ..._zeiten(m),
  },
  updateSpalten: ['norm', 'pruefung_datum', 'pruefer_name', 'messwert_json', 'ergebnis', 'bemerkung', 'aktualisiert_am'],
  zuJson: (z) => {
    'uuid': z['uuid'].toString(),
    'komponenteUuid': z['komponente_uuid']?.toString(),
    'norm': z['norm'] ?? 'vde_0100',
    'pruefungDatum': _datum(z['pruefung_datum']),
    'prueferName': z['pruefer_name'],
    'messwertJson': z['messwert_json'],
    'ergebnis': z['ergebnis'],
    'bemerkung': z['bemerkung'],
    ..._zeitenJson(z),
  },
);

final sichtpruefungenTyp = SyncTyp(
  name: 'sichtpruefungen',
  tabelle: 'sichtpruefungen',
  eltern: [('verteiler_uuid', 'verteiler')],
  werte: (s) => {
    'uuid': _pflicht(s, 'uuid', 'UUID'),
    'verteiler_uuid': _pflicht(s, 'verteilerUuid', 'Verteiler'),
    'pruefung_datum': _tag(_pflicht(s, 'pruefungDatum', 'Prüfdatum')),
    'pruefer_name': s['prueferName'],
    'checkliste_json': s['checklisteJson'],
    'maengel': s['maengel'],
    'ergebnis': _pflicht(s, 'ergebnis', 'Ergebnis'),
    'naechste_pruefung_datum': _tag(_text(s, 'naechstePruefungDatum')),
    ..._zeiten(s),
  },
  updateSpalten: [
    'pruefung_datum',
    'pruefer_name',
    'checkliste_json',
    'maengel',
    'ergebnis',
    'naechste_pruefung_datum',
    'aktualisiert_am',
  ],
  zuJson: (z) => {
    'uuid': z['uuid'].toString(),
    'verteilerUuid': z['verteiler_uuid'].toString(),
    'pruefungDatum': _datum(z['pruefung_datum']),
    'prueferName': z['pruefer_name'],
    'checklisteJson': z['checkliste_json'],
    'maengel': z['maengel'],
    'ergebnis': z['ergebnis'],
    'naechstePruefungDatum': _datum(z['naechste_pruefung_datum']),
    ..._zeitenJson(z),
  },
);

final raeumeTyp = SyncTyp(
  name: 'raeume',
  tabelle: 'raeume',
  eltern: [('standort_uuid', 'standorte')],
  werte: (r) => {
    'uuid': _pflicht(r, 'uuid', 'UUID'),
    'standort_uuid': _pflicht(r, 'standortUuid', 'Standort'),
    'bezeichnung': _pflicht(r, 'bezeichnung', 'Bezeichnung'),
    'bemerkung': _text(r, 'bemerkung'),
    ..._zeiten(r),
  },
  updateSpalten: ['bezeichnung', 'bemerkung', 'aktualisiert_am'],
  zusatzPruefung: (tx, fid, w) async {
    final rows = await tx.execute(
      Sql.named('SELECT standort_uuid FROM raeume WHERE uuid = @u AND firma_id = @fid'),
      parameters: {'u': w['uuid'], 'fid': fid},
    );
    if (rows.isNotEmpty && rows.first[0].toString() != w['standort_uuid']) {
      throw SyncAbgelehnt('Raum kann nicht in einen anderen Standort verschoben werden');
    }
  },
  zuJson: (z) => {
    'uuid': z['uuid'].toString(),
    'standortUuid': z['standort_uuid'].toString(),
    'bezeichnung': z['bezeichnung'],
    'bemerkung': z['bemerkung'],
    ..._zeitenJson(z),
  },
);

/// Spalten der Gerätezuordnung — Änderung nur mit Bestätigung (M3).
const ortSpalten = ['kunde_uuid', 'standort_uuid', 'raum_uuid'];

final geraeteTyp = SyncTyp(
  name: 'geraete',
  tabelle: 'geraete',
  werte: (g) {
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
    return {
      'uuid': _pflicht(g, 'uuid', 'UUID'),
      'kunde_uuid': _pflicht(g, 'kundeUuid', 'Kunde'),
      'standort_uuid': _pflicht(g, 'standortUuid', 'Standort'),
      'raum_uuid': _pflicht(g, 'raumUuid', 'Raum'),
      'bezeichnung': _pflicht(g, 'bezeichnung', 'Bezeichnung'),
      'hersteller': _text(g, 'hersteller'),
      'typ': _text(g, 'typ'),
      'seriennummer': _text(g, 'seriennummer'),
      'inventarnummer': _text(g, 'inventarnummer'),
      'schutzart': _text(g, 'schutzart'),
      'schutzklasse': schutzklasse,
      'aktiv': aktiv,
      'inaktiv_grund': aktiv ? null : grund,
      'pruefintervall_monate': intervall,
      'intervall_begruendung': _text(g, 'intervallBegruendung'),
      'letzte_pruefung_datum': _tag(_text(g, 'letztePruefungDatum')),
      'letzte_pruefung_ersatzwert': g['letztePruefungErsatzwert'] as bool? ?? false,
      'status_historie_json': _text(g, 'statusHistorieJson'),
      'bemerkung': _text(g, 'bemerkung'),
      ..._zeiten(g),
    };
  },
  updateSpalten: [
    ...ortSpalten,
    'bezeichnung',
    'hersteller',
    'typ',
    'seriennummer',
    'inventarnummer',
    'schutzart',
    'schutzklasse',
    'aktiv',
    'inaktiv_grund',
    'pruefintervall_monate',
    'intervall_begruendung',
    'letzte_pruefung_datum',
    'letzte_pruefung_ersatzwert',
    'status_historie_json',
    'bemerkung',
    'aktualisiert_am',
  ],
  zusatzPruefung: (tx, fid, w) async {
    final rows = await tx.execute(
      Sql.named(
        'SELECT 1 FROM raeume r JOIN standorte s ON s.uuid = r.standort_uuid '
        'WHERE r.uuid = @raum AND r.firma_id = @fid AND s.firma_id = @fid '
        'AND s.uuid = @standort AND s.kunde_uuid = @kunde',
      ),
      parameters: {'raum': w['raum_uuid'], 'standort': w['standort_uuid'], 'kunde': w['kunde_uuid'], 'fid': fid},
    );
    if (rows.isEmpty) throw SyncAbgelehnt('Kunde, Standort und Raum passen nicht zusammen oder sind unbekannt');
  },
  zuJson: (z) => {
    'uuid': z['uuid'].toString(),
    'kundeUuid': z['kunde_uuid'].toString(),
    'standortUuid': z['standort_uuid'].toString(),
    'raumUuid': z['raum_uuid'].toString(),
    'bezeichnung': z['bezeichnung'],
    'hersteller': z['hersteller'],
    'typ': z['typ'],
    'seriennummer': z['seriennummer'],
    'inventarnummer': z['inventarnummer'],
    'schutzart': z['schutzart'],
    'schutzklasse': z['schutzklasse'],
    'aktiv': z['aktiv'],
    'inaktivGrund': z['inaktiv_grund'],
    'pruefintervallMonate': z['pruefintervall_monate'],
    'intervallBegruendung': z['intervall_begruendung'],
    'letztePruefungDatum': _datum(z['letzte_pruefung_datum']),
    'letztePruefungErsatzwert': z['letzte_pruefung_ersatzwert'],
    'statusHistorieJson': z['status_historie_json'],
    'bemerkung': z['bemerkung'],
    ..._zeitenJson(z),
  },
);

const pruefStatus = {'entwurf', 'abgeschlossen'};
const pruefErgebnisse = {'bestanden', 'nicht_bestanden'};

final geraetepruefungenTyp = SyncTyp(
  name: 'geraetepruefungen',
  tabelle: 'geraetepruefungen',
  eltern: [('geraet_uuid', 'geraete')],
  werte: (p) {
    final status = _pflicht(p, 'status', 'Status');
    if (!pruefStatus.contains(status)) throw SyncAbgelehnt('Unbekannter Status');
    final ergebnis = _text(p, 'ergebnis');
    if (ergebnis != null && !pruefErgebnisse.contains(ergebnis)) throw SyncAbgelehnt('Unbekanntes Ergebnis');
    final punkte = _pflicht(p, 'punkteJson', 'Prüfpunkte');
    if (status == 'abgeschlossen') {
      if (ergebnis == null) throw SyncAbgelehnt('Abgeschlossene Prüfung braucht ein Ergebnis');
      if (_text(p, 'prueferName') == null) throw SyncAbgelehnt('Abgeschlossene Prüfung braucht einen Prüfer');
      // Ein nicht in Ordnung bewerteter Punkt kann nie „bestanden“ sein.
      if (ergebnis == 'bestanden' && RegExp(r'"bewertung"\s*:\s*"nio"').hasMatch(punkte)) {
        throw SyncAbgelehnt('Bestanden trotz Punkt „nicht in Ordnung“');
      }
    }
    final schutzklasse = _text(p, 'schutzklasse');
    if (schutzklasse != null && !schutzklassen.contains(schutzklasse)) {
      throw SyncAbgelehnt('Schutzklasse muss I, II oder III sein');
    }
    final intervall = p['intervallMonate'];
    if (intervall != null && (intervall is! int || intervall < 1 || intervall > 24)) {
      throw SyncAbgelehnt('Prüfintervall muss 1–24 ganze Monate sein');
    }
    return {
      'uuid': _pflicht(p, 'uuid', 'UUID'),
      'geraet_uuid': _pflicht(p, 'geraetUuid', 'Gerät'),
      'pruefart': _pflicht(p, 'pruefart', 'Prüfart'),
      'pruefart_text': _pflicht(p, 'pruefartText', 'Prüfart-Bezeichnung'),
      'anlass': _text(p, 'anlass'),
      'pruefung_datum': _tag(_pflicht(p, 'pruefungDatum', 'Prüfdatum')),
      'pruefer_name': _text(p, 'prueferName'),
      'messgeraet': _text(p, 'messgeraet'),
      'regel_version': _pflicht(p, 'regelVersion', 'Regelversion'),
      'schutzklasse': schutzklasse,
      'status': status,
      'ergebnis': ergebnis,
      'punkte_json': punkte,
      'maengel': _text(p, 'maengel'),
      'bemerkung': _text(p, 'bemerkung'),
      'ort_snapshot_json': _text(p, 'ortSnapshotJson'),
      'intervall_monate': intervall,
      'naechste_pruefung': _tag(_text(p, 'naechstePruefung')),
      'ersetzt_uuid': _text(p, 'ersetztUuid'),
      'abgeschlossen_am': TypedValue(
        Type.timestampTz,
        status == 'abgeschlossen' ? (DateTime.tryParse('${p['abgeschlossenAm']}')?.toUtc() ?? DateTime.now().toUtc()) : null,
      ),
      ..._zeiten(p),
    };
  },
  updateSpalten: [
    'pruefart',
    'pruefart_text',
    'anlass',
    'pruefung_datum',
    'pruefer_name',
    'messgeraet',
    'regel_version',
    'schutzklasse',
    'status',
    'ergebnis',
    'punkte_json',
    'maengel',
    'bemerkung',
    'ort_snapshot_json',
    'intervall_monate',
    'naechste_pruefung',
    'ersetzt_uuid',
    'abgeschlossen_am',
    'aktualisiert_am',
  ],
  beimAnlegen: (tx, fid, w) async {
    final rows = await tx.execute(
      Sql.named('SELECT aktiv FROM geraete WHERE uuid = @g AND firma_id = @fid'),
      parameters: {'g': w['geraet_uuid'], 'fid': fid},
    );
    if (rows.isNotEmpty && rows.first[0] == false) {
      throw SyncAbgelehnt('Inaktives Gerät: keine neue Prüfung');
    }
  },
  vorAenderung: (zeile, w) {
    if (zeile['status'] == 'abgeschlossen') {
      throw SyncAbgelehnt('Abgeschlossene Prüfung ist unveränderlich — Korrektur als neue Prüfung anlegen');
    }
    if (zeile['geraet_uuid'].toString() != w['geraet_uuid']) {
      throw SyncAbgelehnt('Prüfung kann keinem anderen Gerät zugeordnet werden');
    }
  },
  zuJson: (z) => {
    'uuid': z['uuid'].toString(),
    'geraetUuid': z['geraet_uuid'].toString(),
    'pruefart': z['pruefart'],
    'pruefartText': z['pruefart_text'],
    'anlass': z['anlass'],
    'pruefungDatum': _datum(z['pruefung_datum']),
    'prueferName': z['pruefer_name'],
    'messgeraet': z['messgeraet'],
    'regelVersion': z['regel_version'],
    'schutzklasse': z['schutzklasse'],
    'status': z['status'],
    'ergebnis': z['ergebnis'],
    'punkteJson': z['punkte_json'],
    'maengel': z['maengel'],
    'bemerkung': z['bemerkung'],
    'ortSnapshotJson': z['ort_snapshot_json'],
    'intervallMonate': z['intervall_monate'],
    'naechstePruefung': _datum(z['naechste_pruefung']),
    'ersetztUuid': z['ersetzt_uuid']?.toString(),
    'abgeschlossenAm': z['abgeschlossen_am'] == null ? null : _iso(z['abgeschlossen_am']),
    ..._zeitenJson(z),
  },
);

/// Alle Typen in Push-Reihenfolge (Eltern vor Kindern).
final syncTypen = <String, SyncTyp>{
  for (final t in [
    kundenTyp,
    standorteTyp,
    verteilerTyp,
    komponentenTyp,
    messungenTyp,
    sichtpruefungenTyp,
    raeumeTyp,
    geraeteTyp,
    geraetepruefungenTyp,
  ])
    t.name: t,
};
