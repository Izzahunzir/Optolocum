import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:optolocum/services/real_backend_client.dart';

void main() {
  RealBackendConfig config() => RealBackendConfig(
    baseUrl: 'https://localhost:8787',
    projectId: 'optolocum-f314e',
    emulatorEnabled: false,
  );

  test('rejects insecure, mixed and malformed configurations', () {
    for (final url in [
      'http://localhost:8787',
      'https://user@localhost:8787',
      'https://localhost:8787/path',
      'https://localhost:8787?x=1',
    ]) {
      expect(
        () => RealBackendConfig(
          baseUrl: url,
          projectId: 'optolocum-f314e',
          emulatorEnabled: false,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => RealBackendConfig(
        baseUrl: 'https://localhost:8787',
        projectId: 'optolocum-f314e',
        emulatorEnabled: true,
      ),
      throwsArgumentError,
    );
    expect(
      () => RealBackendConfig(
        baseUrl: 'https://localhost:8787',
        projectId: 'demo-test',
        emulatorEnabled: false,
      ),
      throwsArgumentError,
    );
  });

  test('sends authenticated document bytes to the documented route', () async {
    final client = RealBackendClient(
      config(),
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://localhost:8787/api/applicant/upload/${'a' * 32}',
        );
        expect(request.headers['authorization'], 'Bearer token');
        expect(request.headers['content-type'], 'application/pdf');
        expect(request.bodyBytes, [1, 2]);
        return http.Response(jsonEncode({'data': {}}), 200);
      }),
    );
    await client.upload(
      'a' * 32,
      Uint8List.fromList([1, 2]),
      'application/pdf',
      token: 'token',
    );
  });

  test(
    'reports blocked and expired sessions without server messages',
    () async {
      for (final status in [401, 403, 409, 503]) {
        final client = RealBackendClient(
          config(),
          client: MockClient(
            (_) async =>
                http.Response('{"error":{"message":"sensitive"}}', status),
          ),
        );
        await expectLater(
          client.postJson('/api/applicant/draft', {}, token: 'token'),
          throwsA(
            isA<BackendException>()
                .having((e) => e.statusCode, 'status', status)
                .having(
                  (e) => e.message.contains('sensitive'),
                  'leaks server message',
                  false,
                ),
          ),
        );
      }
    },
  );

  test('reports unavailable backend', () async {
    final client = RealBackendClient(
      config(),
      client: MockClient(
        (_) async => throw Exception('private transport details'),
      ),
    );
    await expectLater(
      client.postJson('/api/enrollment', {}),
      throwsA(
        isA<BackendException>().having(
          (e) => e.message,
          'message',
          contains('unavailable'),
        ),
      ),
    );
  });
}
