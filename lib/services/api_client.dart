import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'token_service.dart';

/// Thrown when the server returns 401 — caller should redirect to login.
class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Session expired. Please log in again.']);
  @override
  String toString() => message;
}

/// Thrown for any non-2xx response that is not 401.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Central HTTP client.
/// Reads the base URL from the dart-define `API_BASE_URL`
/// (pass via `flutter run --dart-define=API_BASE_URL=https://your-backend.com`).
/// Falls back to localhost for development.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://aqia-backend.onrender.com',
  );

  String get baseUrl => _baseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        ...TokenService.instance.authHeader,
      };

  /// GET request. Returns decoded JSON body.
  Future<dynamic> get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.get(uri, headers: _headers)
        .timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }

  /// POST request with JSON body. Returns decoded JSON body.
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 60));
    return _handleResponse(response);
  }

  /// POST multipart (for audio file upload to /api/transcribe).
  Future<dynamic> postMultipart(
    String path, {
    required File file,
    required String fieldName,
    required String filename,
    required String mimeType,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(TokenService.instance.authHeader);

    if (fields != null) request.fields.addAll(fields);

    request.files.add(await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      // ignore: deprecated_member_use
      filename: filename,
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  /// POST multipart from bytes (for audio recorded in memory).
  Future<dynamic> postMultipartBytes(
    String path, {
    required List<int> bytes,
    required String fieldName,
    required String filename,
    required String mimeType,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(TokenService.instance.authHeader);

    if (fields != null) request.fields.addAll(fields);

    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: filename,
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  /// GET raw bytes (for TTS audio).
  Future<List<int>> getBytes(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 401) throw const AuthException();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
    return response.bodyBytes;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) throw const AuthException();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = response.body;
      try {
        final json = jsonDecode(response.body);
        detail = json['detail']?.toString() ?? detail;
      } catch (_) {}
      throw ApiException(response.statusCode, detail);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }
}
