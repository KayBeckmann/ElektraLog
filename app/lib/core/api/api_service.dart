import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Web: same host (Nginx proxy), Native: configurable via --dart-define
  static String get baseUrl {
    if (kIsWeb) return '/api';
    return const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:8080/api',
    );
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
}
