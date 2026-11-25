import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Explicit configuration for the real-project local backend.
class RealBackendConfig {
  RealBackendConfig({
    required String baseUrl,
    required String projectId,
    required bool emulatorEnabled,
  }) : baseUri = Uri.parse(baseUrl) {
    if (projectId != 'optolocum-f314e' ||
        emulatorEnabled ||
        baseUri.scheme != 'https' ||
        baseUri.host.isEmpty ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery ||
        baseUri.hasFragment ||
        (baseUri.path.isNotEmpty && baseUri.path != '/')) {
      throw ArgumentError('Invalid real backend configuration.');
    }
  }
  final Uri baseUri;
}

class BackendException implements Exception {
  const BackendException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

/// The injected HTTP client must retain normal certificate and hostname checks.
class RealBackendClient {
  RealBackendClient(
    this.config, {
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();
  final RealBackendConfig config;
  final http.Client _client;
  final Duration timeout;

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) => _send(path, utf8.encode(jsonEncode(body)), 'application/json', token);

  Future<Map<String, dynamic>> upload(
    String requestId,
    Uint8List bytes,
    String contentType, {
    required String token,
  }) {
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(requestId) ||
        !const [
          'application/pdf',
          'image/png',
          'image/jpeg',
        ].contains(contentType) ||
        bytes.isEmpty ||
        bytes.length > 50 * 1024 * 1024) {
      throw ArgumentError('Invalid document upload.');
    }
    return _send('/api/applicant/upload/$requestId', bytes, contentType, token);
  }

  Future<Map<String, dynamic>> _send(
    String path,
    List<int> body,
    String contentType,
    String? token,
  ) async {
    if (!path.startsWith('/api/') ||
        path.startsWith('//') ||
        (token != null && token.trim().isEmpty)) {
      throw ArgumentError('Invalid backend request.');
    }
    final uri = config.baseUri.resolve(path);
    http.Response response;
    try {
      final request = http.Request('POST', uri)
        ..followRedirects = false
        ..headers.addAll({
          'content-type': contentType,
          if (token != null) 'authorization': 'Bearer $token',
        })
        ..bodyBytes = body;
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } catch (_) {
      throw const BackendException(
        'Backend unavailable. Retry with the same details.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = switch (response.statusCode) {
        400 => 'Check the submitted details and try again.',
        401 => 'Your session has expired. Please sign in again.',
        403 => 'This account cannot perform this action. Contact support.',
        404 =>
          'The request was not found or this service is not available yet.',
        409 =>
          'This request conflicts with an existing attempt. Contact support.',
        413 => 'The document is too large.',
        503 =>
          'The backend is temporarily unavailable or submissions are blocked.',
        _ => 'The backend could not complete the request. Please retry.',
      };
      throw BackendException(message, statusCode: response.statusCode);
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    throw const BackendException(
      'The backend response could not be confirmed. Retry with the same details.',
    );
  }

  void close() => _client.close();
}
