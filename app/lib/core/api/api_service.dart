import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Web: same host (Nginx proxy), Native: aus Einstellungen oder Fallback
  static String get baseUrl {
    if (kIsWeb) return '/api';
    final stored = _cachedServerUrl;
    if (stored != null && stored.isNotEmpty) {
      return '${stored.replaceAll(RegExp(r'/$'), '')}/api';
    }
    return const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:8080/api',
    );
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
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String passwort,
  ) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'passwort': passwort}),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
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
    await http.post(
      Uri.parse('$baseUrl/sync'),
      headers: await _headers(auth: true),
      body: jsonEncode({'type': 'kunden', 'items': kunden}),
    );
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

  static Future<void> deleteTeamBenutzer(String id) async {
    await http.delete(
      Uri.parse('$baseUrl/firma/benutzer/$id'),
      headers: await _headers(auth: true),
    );
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
