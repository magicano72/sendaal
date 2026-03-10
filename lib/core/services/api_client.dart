import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  late final String baseUrl;
  late final int timeoutDuration;
  static const String _defaultBaseUrl =
      'https://sendaal-directus.csiwm3.easypanel.host/';
  static const int _defaultTimeout = 900000; // 30 seconds in milliseconds

  String? _token;

  ApiClient() {
    baseUrl = dotenv.env['BASE_URL'] ?? _defaultBaseUrl;
    timeoutDuration =
        int.tryParse(dotenv.env['API_TIMEOUT'] ?? '') ?? _defaultTimeout;
  }

  /// Set authentication token for future requests
  void setToken(String token) {
    _token = token;
  }

  /// Clear authentication token
  void clearToken() {
    _token = null;
  }

  /// Build headers with optional authorization
  Map<String, String> _buildHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  /// Build full URL
  String _buildUrl(String endpoint) {
    if (endpoint.startsWith('http')) {
      return endpoint;
    }
    return '$baseUrl$endpoint';
  }

  /// Perform GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse(_buildUrl(endpoint));
      final uriWithParams = queryParams != null
          ? uri.replace(queryParameters: queryParams)
          : uri;

      final response = await http
          .get(uriWithParams, headers: _buildHeaders(includeAuth: includeAuth))
          .timeout(
            Duration(milliseconds: timeoutDuration),
            onTimeout: () => throw Exception('Request timeout'),
          );

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Perform POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_buildUrl(endpoint)),
            headers: _buildHeaders(includeAuth: includeAuth),
            body: jsonEncode(body),
          )
          .timeout(
            Duration(milliseconds: timeoutDuration),
            onTimeout: () => throw Exception('Request timeout'),
          );

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Perform PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse(_buildUrl(endpoint)),
            headers: _buildHeaders(includeAuth: includeAuth),
            body: jsonEncode(body),
          )
          .timeout(
            Duration(milliseconds: timeoutDuration),
            onTimeout: () => throw Exception('Request timeout'),
          );

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Perform DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(_buildUrl(endpoint)),
            headers: _buildHeaders(includeAuth: includeAuth),
          )
          .timeout(
            Duration(milliseconds: timeoutDuration),
            onTimeout: () => throw Exception('Request timeout'),
          );

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      } else if (response.statusCode == 401) {
        clearToken();
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden - You do not have permission');
      } else if (response.statusCode == 404) {
        throw Exception('Resource not found');
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests - Please try again later');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error - Please try again later');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'API Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle errors
  Exception _handleError(dynamic error) {
    if (error is Exception) {
      return error;
    }
    return Exception('An unexpected error occurred: $error');
  }
}
