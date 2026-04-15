import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../core/services/connectivity_service.dart';

/// Custom exception with a user-friendly message and optional HTTP status
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
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
  final ConnectivityService _connectivityService = ConnectivityService();

  // ── Configuration from .env ───────────────────────────────────────────────
  String get baseUrl => dotenv.env['BASE_URL'] ?? 'https://api.sendaal.com';
  String get _baseUrl => baseUrl;
  Duration get _timeout => Duration(
    milliseconds: int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000,
  );

  Future<void> _ensureOnline() async {
    final hasInternet = await _connectivityService.hasInternetConnection();
    if (!hasInternet) {
      throw const ApiException(
        'No internet connection. Please check your network.',
      );
    }
  }

  // ── Auth token (set after login) ──────────────────────────────────────────
  String? _authToken;
  String? _refreshToken;
  DateTime? _tokenExpiresAt;
  bool _isRefreshing = false;
  Future<void> Function({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  })? _sessionPersistenceCallback;

  void setToken(
    String token, {
    String? refreshToken,
    int? expiresInMs,
    DateTime? expiresAt,
  }) {
    _authToken = token;
    if (refreshToken != null) {
      _refreshToken = refreshToken;
    }
    if (expiresAt != null) {
      _tokenExpiresAt = expiresAt.toLocal();
    } else if (expiresInMs != null) {
      _tokenExpiresAt = DateTime.now().add(Duration(milliseconds: expiresInMs));
      print('[ApiClient] Token set, expires at: $_tokenExpiresAt');
    }
  }

  void configureSessionPersistence(
    Future<void> Function({
      required String accessToken,
      required String refreshToken,
      DateTime? expiresAt,
    }) callback,
  ) {
    _sessionPersistenceCallback = callback;
  }

  void clearToken() {
    _authToken = null;
    _refreshToken = null;
    _tokenExpiresAt = null;
  }

  bool get hasToken => _authToken != null;
  String? get refreshToken => _refreshToken;

  /// Check if token is expired or about to expire (within 5 minutes)
  bool get isTokenExpired {
    if (_tokenExpiresAt == null) return false;
    return DateTime.now().isAfter(
      _tokenExpiresAt!.subtract(const Duration(minutes: 5)),
    );
  }

  // ── Default headers ───────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  /// Headers for endpoints that should be callable without a user token.
  /// Optionally adds a static token from .env (PUBLIC_STATIC_TOKEN or PUBLIC_TOKEN).
  Map<String, String> get _publicHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final staticToken = dotenv.env['PHONE_VALIDATOR_TOKEN'] ??
        dotenv.env['PUBLIC_STATIC_TOKEN'] ??
        dotenv.env['PUBLIC_TOKEN'];
    if (staticToken != null && staticToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $staticToken';
    }
    return headers;
  }

  // ── URI builder ───────────────────────────────────────────────────────────
  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (queryParams == null || queryParams.isEmpty) return uri;
    return uri.replace(
      queryParameters: {...uri.queryParameters, ...queryParams},
    );
  }

  Future<void> _refreshIfExpired() async {
    if (!isTokenExpired || _refreshToken == null) return;
    await _tryRefreshToken();
  }

  Future<bool> _tryRefreshToken() async {
    if (_refreshToken == null) return false;

    // If a refresh is already running, wait for it to complete.
    if (_isRefreshing) {
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _authToken != null;
    }

    _isRefreshing = true;
    try {
      final response = await http
          .post(
            _buildUri('/auth/refresh'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'refresh_token': _refreshToken,
              'mode': 'json',
            }),
          )
          .timeout(_timeout);

      final body = _parseResponse(response);
      final data = body is Map ? body['data'] as Map<String, dynamic>? : null;
      if (data == null || data['access_token'] == null) {
        clearToken();
        throw const ApiException(
          'Session expired. Please log in again.',
          statusCode: 401,
        );
      }

      setToken(
        data['access_token'].toString(),
        refreshToken: data['refresh_token']?.toString() ?? _refreshToken,
        expiresInMs: data['expires'] is int
            ? data['expires'] as int
            : int.tryParse('${data['expires']}'),
      );
      if (_authToken != null && _refreshToken != null) {
        await _sessionPersistenceCallback?.call(
          accessToken: _authToken!,
          refreshToken: _refreshToken!,
          expiresAt: _tokenExpiresAt,
        );
      }
      return true;
    } catch (e) {
      clearToken();
      if (e is ApiException) rethrow;
      throw const ApiException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    } finally {
      _isRefreshing = false;
    }
  }

  bool _looksLikeTokenExpired(String body) {
    final lower = body.toLowerCase();
    if (lower.contains('token expired')) return true;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message']?.toString().toLowerCase();
        if (message != null && message.contains('token expired')) return true;
        final errors = decoded['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          final msg = first['message']?.toString().toLowerCase();
          final code =
              first['extensions']?['code']?.toString().toLowerCase();
          if (msg != null && msg.contains('token expired')) return true;
          if (code != null && code.contains('token_expired')) return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<dynamic> _sendWithRefreshRetry(
    Future<http.Response> Function() send,
  ) async {
    await _ensureOnline();
    // Pre-emptively refresh if we know the token is expiring.
    await _refreshIfExpired();

    http.Response response = await send();

    // Retry once on explicit token-expired responses.
    if (response.statusCode == 401 &&
        _refreshToken != null &&
        _looksLikeTokenExpired(response.body)) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        response = await send();
      }
    }

    return _parseResponse(response);
  }

  // ── GET ───────────────────────────────────────────────────────────────────
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    print('[ApiClient] GET request: $_baseUrl$path');
    try {
      return await _sendWithRefreshRetry(
        () => http
            .get(_buildUri(path, queryParams), headers: _headers)
            .timeout(_timeout),
      );
    } on SocketException {
      throw const ApiException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    }
  }

  /// GET without user auth; uses optional static token if provided.
  Future<dynamic> getPublic(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    print('[ApiClient] PUBLIC GET request: $_baseUrl$path');
    try {
      await _ensureOnline();
      if (!_publicHeaders.containsKey('Authorization')) {
        print(
          '[ApiClient] Warning: no PUBLIC_STATIC_TOKEN/PUBLIC_TOKEN/PHONE_VALIDATOR_TOKEN set; request may be rejected.',
        );
      }
      final response = await http
          .get(_buildUri(path, queryParams), headers: _publicHeaders)
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

  // ── POST ──────────────────────────────────────────────────────────────────
  /// POST – accepts either a map or a list (for bulk inserts)
  Future<dynamic> post(String path, {dynamic body}) async {
    print('[ApiClient] POST request: $_baseUrl$path');
    print('[ApiClient] POST body: $body');
    try {
      return await _sendWithRefreshRetry(
        () => http
            .post(
              _buildUri(path),
              headers: _headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(_timeout),
      );
    } on SocketException {
      throw const ApiException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    }
  }

  /// POST without user auth; uses optional static token if provided.
  Future<dynamic> postPublic(String path, {dynamic body}) async {
    print('[ApiClient] PUBLIC POST request: $_baseUrl$path');
    print('[ApiClient] POST body: $body');
    try {
      await _ensureOnline();
      if (!_publicHeaders.containsKey('Authorization')) {
        print(
          '[ApiClient] Warning: no PUBLIC_STATIC_TOKEN/PUBLIC_TOKEN/PHONE_VALIDATOR_TOKEN set; request may be rejected.',
        );
      }
      final response = await http
          .post(
            _buildUri(path),
            headers: _publicHeaders,
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

  // ── PATCH ─────────────────────────────────────────────────────────────────
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      return await _sendWithRefreshRetry(
        () => http
            .patch(
              _buildUri(path),
              headers: _headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(_timeout),
      );
    } on SocketException {
      throw const ApiException(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<dynamic> delete(
    String path, {
    Map<String, String>? queryParams,
    dynamic body,
  }) async {
    try {
      return await _sendWithRefreshRetry(
        () => http
            .delete(
              _buildUri(path, queryParams),
              headers: _headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(_timeout),
      );
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
      await _ensureOnline();
      await _refreshIfExpired();

      Future<({int statusCode, String body})> sendRequest() async {
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

        final streamed = await request.send().timeout(_timeout);
        final responseBody = await streamed.stream.bytesToString();

        print('[ApiClient] MULTIPART response status: ${streamed.statusCode}');
        print('[ApiClient] MULTIPART response body: $responseBody');
        return (statusCode: streamed.statusCode, body: responseBody);
      }

      var result = await sendRequest();

      if (result.statusCode == 401 &&
          _refreshToken != null &&
          _looksLikeTokenExpired(result.body)) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          result = await sendRequest();
        }
      }

      final responseBody = result.body;

      // Parse JSON response
      dynamic body;
      try {
        body = jsonDecode(responseBody);
      } catch (_) {
        body = responseBody;
      }

      if (result.statusCode >= 200 && result.statusCode < 300) {
        return body;
      }

      // Handle error
      String message =
          _extractErrorMessage(body) ??
          'An unexpected error occurred (HTTP ${result.statusCode})';
      throw ApiException(message, statusCode: result.statusCode);
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
