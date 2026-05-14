import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

Middleware corsMiddleware() => (handler) => (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await handler(request);
      return response.change(headers: _corsHeaders);
    };

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

Map<String, dynamic>? verifyJwt(Request request) {
  final auth = request.headers['authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  final token = auth.substring(7);
  try {
    final secret =
        Platform.environment['JWT_SECRET'] ?? 'changeme_jwt_secret';
    final jwt = JWT.verify(token, SecretKey(secret));
    return jwt.payload as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
