import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createBackendHttpClient() {
  const ca = String.fromEnvironment('OPT_DEBUG_CA_BASE64');
  if (ca.isEmpty) return http.Client();
  if (!kDebugMode || !Platform.isAndroid) {
    throw StateError(
      'A development CA is allowed only in Android debug builds.',
    );
  }
  final context = SecurityContext(withTrustedRoots: true);
  context.setTrustedCertificatesBytes(base64Decode(ca));
  return IOClient(HttpClient(context: context));
}
