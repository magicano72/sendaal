import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Custom exception with a user-friendly message and optional HTTP status
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Central HTTP client for ALL Sendaal API calls.
///
/// - Reads BASE_URL and API_TIMEOUT from .env automatically
/// - Injects Authorization header when a token is set
/// - Handles error parsing uniformly
/// - All screens/repos call this — never use http directly elsewhere
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  // ── Configuration from .env ───────────────────────────────────────────────
  String get baseUrl => dotenv.env['BASE_URL'] ?? 'https://api.sendaal.com';
  String get _baseUrl => baseUrl;
  Duration get _timeout => Duration(
    milliseconds: int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000,
  );

  // ── Auth token (set after login) ──────────────────────────────────────────
  String? _authToken;
  String? _refreshToken;
  DateTime? _tokenExpiresAt;

  void setToken(String token, {String? refreshToken, int? expiresIn}) {
    _authToken = token;
    if (refreshToken != null) {
      _refreshToken = refreshToken;
    }
    if (expiresIn != null) {
      _tokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      print('[ApiClient] Token set, expires at: $_tokenExpiresAt');
    }
  }

  void clearToken() {
    _authToken = null;
    _refreshToken = null;
    _tokenExpiresAt = null;
  }

  bool get hasToken => _authToken != null;
  String? get refreshToken => _refreshToken;

  /// Check if token is expired or about to expire (within 60 seconds)
  bool get isTokenExpired {
    if (_tokenExpiresAt == null) return false;
    final timeUntilExpiry = _tokenExpiresAt!
        .difference(DateTime.now())
        .inSeconds;
    return timeUntilExpiry < 60; // Refresh if less than 60 seconds left
  }

  // ── Default headers ───────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ── URI builder ───────────────────────────────────────────────────────────
  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (queryParams == null || queryParams.isEmpty) return uri;
    return uri.replace(
      queryParameters: {...uri.queryParameters, ...queryParams},
    );
  }

  // ── GET ───────────────────────────────────────────────────────────────────
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    print('[ApiClient] GET request: $_baseUrl$path');
    try {
      final response = await http
          .get(_buildUri(path, queryParams), headers: _headers)
          .timeout(_timeout);
      print('[ApiClient] GET response status: ${response.statusCode}');
      return _parseResponse(response);
    } on SocketException {
      throw const ApiException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    }
  }

  // ── POST ──────────────────────────────────────────────────────────────────
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    print('[ApiClient] POST request: $_baseUrl$path');
    print('[ApiClient] POST body: $body');
    try {
      final response = await http
          .post(
            _buildUri(path),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      print('[ApiClient] POST response status: ${response.statusCode}');
      print('[ApiClient] POST response body: ${response.body}');
      return _parseResponse(response);
    } on SocketException {
      throw const ApiException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    }
  }

  // ── PATCH ─────────────────────────────────────────────────────────────────
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .patch(
            _buildUri(path),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      throw const ApiException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<dynamic> delete(String path) async {
    try {
      final response = await http
          .delete(_buildUri(path), headers: _headers)
          .timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      throw const ApiException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    }
  }

  // ── MULTIPART (for file uploads) ──────────────────────────────────────────
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    Map<String, String>? files, // filename -> filepath
  }) async {
    print('[ApiClient] MULTIPART POST request: $_baseUrl$path');
    try {
      final request = http.MultipartRequest('POST', _buildUri(path));

      // Add headers (without Content-Type, let http package set it)
      _headers.forEach((key, value) {
        if (key != 'Content-Type') {
          request.headers[key] = value;
        }
      });

      // Add form fields
      request.fields.addAll(fields);

      // Add files
      if (files != null) {
        for (var filename in files.keys) {
          final filepath = files[filename]!;
          request.files.add(
            await http.MultipartFile.fromPath(filename, filepath),
          );
        }
      }

      final response = await request.send().timeout(_timeout);
      final responseBody = await response.stream.bytesToString();

      print('[ApiClient] MULTIPART response status: ${response.statusCode}');
      print('[ApiClient] MULTIPART response body: $responseBody');

      // Parse JSON response
      dynamic body;
      try {
        body = jsonDecode(responseBody);
      } catch (_) {
        body = responseBody;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      }

      // Handle error
      String message =
          _extractErrorMessage(body) ??
          'An unexpected error occurred (HTTP ${response.statusCode})';
      throw ApiException(message, statusCode: response.statusCode);
    } on SocketException {
      throw const ApiException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    }
  }

  // ── Response Parser ───────────────────────────────────────────────────────
  dynamic _parseResponse(http.Response response) {
    final statusCode = response.statusCode;
    print('[ApiClient] Parsing response with status: $statusCode');

    // 204 No Content — valid success with empty body
    if (statusCode == 204) {
      print('[ApiClient] 204 No Content response');
      return null;
    }

    // Attempt to decode JSON
    dynamic body;
    try {
      body = jsonDecode(response.body);
      print('[ApiClient] Response body decoded: $body');
    } catch (_) {
      body = response.body;
      print('[ApiClient] Response body (not JSON): $body');
    }

    if (statusCode >= 200 && statusCode < 300) {
      print('[ApiClient] Success response');
      return body;
    }

    // Extract Directus-style error message if available
    String message =
        _extractErrorMessage(body) ??
        'An unexpected error occurred (HTTP $statusCode)';
    print('[ApiClient] Error message: $message');

    throw ApiException(message, statusCode: statusCode);
  }

  String? _extractErrorMessage(dynamic body) {
    if (body is Map) {
      // Directus error format: { errors: [{ message: '...' }] }
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.first['message']?.toString();
      }
      return body['message']?.toString();
    }
    return null;
  }
}
