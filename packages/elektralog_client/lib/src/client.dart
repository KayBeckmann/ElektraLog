import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lightweight HTTP client for the ElektraLog backend API.
class ElektraLogClient {
  ElektraLogClient({required this.baseUrl});

  final String baseUrl;
  String? _token;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final resp = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<dynamic> get(String path) async {
    final resp = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return jsonDecode(resp.body);
  }

  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    final resp = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
  }
}
