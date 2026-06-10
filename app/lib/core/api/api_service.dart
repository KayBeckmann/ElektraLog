import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Wird geworfen, wenn der Server nicht mit JSON antwortet (z.B. HTML-Fehlerseite
/// eines Reverse-Proxys bei falscher Server-URL) oder einen Fehlerstatus liefert.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiService {
  // Web: same host (Nginx proxy), Native: aus Einstellungen oder Fallback
  static String get baseUrl {
    if (kIsWeb) return '/api';
    final stored = _cachedServerUrl;
    if (stored != null && stored.isNotEmpty) {
      return '${stored.replaceAll(RegExp(r'/$'), '')}/api';
    }
    // dart-define-Wert normalisieren: /api anhängen falls nicht vorhanden
    final env = const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:8080',
    );
    final base = env.replaceAll(RegExp(r'/$'), '');
    return base.endsWith('/api') ? base : '$base/api';
  }

  /// Wird vom EinstellungenProvider befüllt, sobald die Prefs geladen sind.
  static String? _cachedServerUrl;

  static void setServerUrl(String? url) {
    _cachedServerUrl = url;
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Dekodiert eine JSON-Objekt-Antwort und prüft vorher den Content-Type.
  /// Antwortet der Server mit HTML (z.B. SPA-Fallback eines Reverse-Proxys
  /// bei falscher Server-URL) oder ungültigem JSON, wird eine
  /// [ApiException] mit verständlicher Fehlermeldung geworfen statt einer
  /// rohen FormatException.
  static Map<String, dynamic> _decodeJsonObject(http.Response resp) {
    final contentType = resp.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw ApiException(
        resp.statusCode,
        'Server antwortet nicht mit JSON (HTTP ${resp.statusCode}). '
        'Server-URL in den Einstellungen prüfen.',
      );
    }
    try {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(
        resp.statusCode,
        'Ungültige Server-Antwort (HTTP ${resp.statusCode}). '
        'Server-URL in den Einstellungen prüfen.',
      );
    }
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // Auth
  static Future<Map<String, dynamic>> register(
    String email,
    String passwort,
    String name,
    String firmenname,
  ) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        'passwort': passwort,
        'name': name,
        'firmenname': firmenname,
      }),
    );
    return _decodeJsonObject(resp);
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String passwort,
  ) async {
    await _ensureServerUrl();
    if (_cachedServerUrl == null || _cachedServerUrl!.isEmpty) {
      return {'error': 'Keine Server-URL konfiguriert. Bitte in den Einstellungen hinterlegen.'};
    }
    final resp = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'passwort': passwort}),
    );
    return _decodeJsonObject(resp);
  }

  static Future<void> _ensureServerUrl() async {
    if (_cachedServerUrl != null && _cachedServerUrl!.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('einstellungen.serverUrl');
    if (url != null && url.isNotEmpty) _cachedServerUrl = url;
  }

  // Kunden
  static Future<List<dynamic>> getKunden() async {
    final resp = await http.get(
      Uri.parse('$baseUrl/kunden'),
      headers: await _headers(auth: true),
    );
    return jsonDecode(resp.body) as List<dynamic>;
  }

  static Future<void> syncKunden(
      List<Map<String, dynamic>> kunden) async {
    await syncAll([
      {'type': 'kunden', 'items': kunden}
    ]);
  }

  /// Zieht alle Rohdaten vom Backend (GET /api/sync).
  static Future<Map<String, dynamic>> pullAll() async {
    final resp = await http.get(
      Uri.parse('$baseUrl/sync'),
      headers: await _headers(auth: true),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('pullAll HTTP ${resp.statusCode}');
  }

  /// Schiebt alle Entity-Typen in einem Request zum Backend.
  /// Format: [{ "type": "kunden", "items": [...] }, ...]
  static Future<void> syncAll(List<Map<String, dynamic>> batches) async {
    await http.post(
      Uri.parse('$baseUrl/sync'),
      headers: await _headers(auth: true),
      body: jsonEncode({'batches': batches}),
    );
  }

  /// Gibt die direkte PDF-Download-URL für ein Protokoll zurück.
  static String protokollPdfUrl(String id) => '$baseUrl/protokolle/$id/pdf';

  /// Lädt die PDF-Bytes eines Prüfprotokolls mit Auth-Header.
  /// Gibt null zurück bei Fehler (z.B. 401 ohne gültiges Token).
  static Future<Uint8List?> getProtokollPdf(String id) async {
    final resp = await http.get(
      Uri.parse(protokollPdfUrl(id)),
      headers: await _headers(auth: true),
    );
    if (resp.statusCode == 200) return resp.bodyBytes;
    return null;
  }

  /// Lädt ein Prüfprotokoll (PDF + Metadaten) in das Backend hoch.
  /// Gibt die Backend-UUID zurück oder null bei Fehler.
  /// Nicht-blockierend — Fehler werden geloggt, nicht geworfen.
  static Future<String?> uploadProtokoll({
    required Uint8List pdfBytes,
    required String verteilerBezeichnung,
    String? standortBezeichnung,
    String? kundenBezeichnung,
    String? prueferName,
    String? firmaName,
    required DateTime protokollDatum,
    String? messdatenJson,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return null; // Nicht eingeloggt → kein Upload

      final pdfHash = sha256.convert(pdfBytes).toString();
      final pdfBase64 = base64Encode(pdfBytes);

      final resp = await http
          .post(
            Uri.parse('$baseUrl/protokolle'),
            headers: await _headers(auth: true),
            body: jsonEncode({
              'verteilerBezeichnung': verteilerBezeichnung,
              'standortBezeichnung': standortBezeichnung,
              'kundenBezeichnung': kundenBezeichnung,
              'prueferName': prueferName,
              'firmaName': firmaName,
              'protokollDatum': protokollDatum.toIso8601String(),
              'messdatenJson': messdatenJson,
              'pdfBase64': pdfBase64,
              'pdfHash': pdfHash,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        return body['id'] as String?;
      }
      debugPrint('Protokoll-Upload: HTTP ${resp.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Protokoll-Upload fehlgeschlagen (offline?): $e');
      return null;
    }
  }

  // Team / Firmeneigene Benutzerverwaltung
  static Future<List<Map<String, dynamic>>> getTeamBenutzer() async {
    final resp = await http.get(
      Uri.parse('$baseUrl/firma/benutzer'),
      headers: await _headers(auth: true),
    );
    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
  }

  static Future<Map<String, dynamic>> createTeamBenutzer({
    required String email,
    required String passwort,
    required String name,
  }) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/firma/benutzer'),
      headers: await _headers(auth: true),
      body: jsonEncode({'email': email, 'passwort': passwort, 'name': name}),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateTeamBenutzer(
    String id, {
    String? name,
    String? email,
    String? passwort,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (passwort != null && passwort.isNotEmpty) body['passwort'] = passwort;
    final resp = await http.patch(
      Uri.parse('$baseUrl/firma/benutzer/$id'),
      headers: await _headers(auth: true),
      body: jsonEncode(body),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateTeamBenutzerStatus(
    String id,
    String status,
  ) async {
    final resp = await http.patch(
      Uri.parse('$baseUrl/firma/benutzer/$id/status'),
      headers: await _headers(auth: true),
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateTeamBenutzerRolle(
    String id,
    bool istAdmin,
  ) async {
    final resp = await http.patch(
      Uri.parse('$baseUrl/firma/benutzer/$id/rolle'),
      headers: await _headers(auth: true),
      body: jsonEncode({'istAdmin': istAdmin}),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<void> deleteTeamBenutzer(String id) async {
    await http.delete(
      Uri.parse('$baseUrl/firma/benutzer/$id'),
      headers: await _headers(auth: true),
    );
  }

  /// Ändert das eigene Passwort (kein Admin nötig).
  /// Wirft Exception wenn das alte Passwort falsch ist oder Server-Fehler.
  static Future<void> changeOwnPassword({
    required String altesPasswort,
    required String neuesPasswort,
  }) async {
    final resp = await http.patch(
      Uri.parse('$baseUrl/auth/me/passwort'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'altesPasswort': altesPasswort,
        'neuesPasswort': neuesPasswort,
      }),
    );
    if (resp.statusCode != 200) {
      final msg = (jsonDecode(resp.body) as Map<String, dynamic>)['error']
              as String? ??
          'Passwort konnte nicht geändert werden';
      throw Exception(msg);
    }
  }

  /// Gibt die Protokoll-Liste der eigenen Firma zurück.
  static Future<List<Map<String, dynamic>>> getProtokolle() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/protokolle'),
        headers: await _headers(auth: true),
      );
      if (resp.statusCode == 200) {
        return (jsonDecode(resp.body) as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
