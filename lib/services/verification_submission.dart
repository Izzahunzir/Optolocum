import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';

enum VerificationAccountType { locum, practiceOwner }

/// Applicant-supplied evidence, never an account role or approval decision.
class VerificationDocument {
  VerificationDocument._(this.name, this.contentType, this.bytes)
    : sha256Hex = sha256.convert(bytes).toString();

  static const maxBytes = 50 * 1024 * 1024;
  final String name;
  final String contentType;
  final Uint8List bytes;
  final String sha256Hex;

  static Future<VerificationDocument> fromFile(XFile file) async {
    final length = await file.length();
    if (length == 0 || length > maxBytes) {
      throw const FormatException('Choose a nonempty document up to 50 MB.');
    }
    return fromBytes(file.name, await file.readAsBytes());
  }

  static VerificationDocument fromBytes(String name, Uint8List bytes) {
    final extension = name.split('.').last.toLowerCase();
    final mime = switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => throw const FormatException('Choose one PDF, JPG, JPEG, or PNG.'),
    };
    if (bytes.isEmpty ||
        bytes.length > maxBytes ||
        name.length > 255 ||
        name.contains('/') ||
        name.contains('\\')) {
      throw const FormatException('Invalid document name or size.');
    }
    bool starts(List<int> signature) =>
        bytes.length >= signature.length &&
        List.generate(
          signature.length,
          (i) => bytes[i] == signature[i],
        ).every((value) => value);
    final valid = switch (mime) {
      'application/pdf' => starts([37, 80, 68, 70, 45]),
      'image/png' => starts([137, 80, 78, 71, 13, 10, 26, 10]),
      _ => starts([255, 216, 255]),
    };
    if (!valid) {
      throw const FormatException('Document contents do not match its type.');
    }
    return VerificationDocument._(
      name,
      mime,
      Uint8List.fromList(bytes).asUnmodifiableView(),
    );
  }
}

class VerificationSubmission {
  VerificationSubmission({
    required this.uid,
    required this.accountType,
    required Map<String, String> fields,
    this.document,
    String? id,
  }) : fields = Map.unmodifiable(fields),
       id = id ?? _newId() {
    if (!RegExp(r'^[^/]{1,128}$').hasMatch(uid) ||
        !RegExp(r'^[a-f0-9]{40}$').hasMatch(this.id)) {
      throw const FormatException('Invalid submission identity.');
    }
    final expected = accountType == VerificationAccountType.locum
        ? locumKeys
        : practiceKeys;
    if (fields.length != expected.length ||
        !expected.every(fields.containsKey) ||
        fields.values.any((v) => v.trim().isEmpty || v.length > 2000)) {
      throw const FormatException('Complete all verification fields.');
    }
    if ((accountType == VerificationAccountType.locum) != (document != null)) {
      throw const FormatException('Locums must supply exactly one document.');
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(
      fields[accountType == VerificationAccountType.locum
          ? 'email'
          : 'companyEmail']!,
    )) {
      throw const FormatException('Enter a valid email.');
    }
    final phone =
        fields[accountType == VerificationAccountType.locum
                ? 'phoneNumber'
                : 'contactNumber']!
            .replaceAll(RegExp(r'[\s()-]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) {
      throw const FormatException('Enter a valid contact number.');
    }
    if (accountType == VerificationAccountType.locum) {
      if (!RegExp(r'^[0-9]{12}$')
          .hasMatch(fields['nric']!.replaceAll('-', ''))) {
        throw const FormatException('Enter a 12-digit NRIC.');
      }
      final date = DateTime.tryParse(fields['dateOfBirth']!);
      if (date == null ||
          date.isAfter(DateTime.now()) ||
          date.toIso8601String().substring(0, 10) != fields['dateOfBirth']) {
        throw const FormatException('Enter a valid past date (YYYY-MM-DD).');
      }
    } else if (!practiceTypes.contains(fields['practiceType']) ||
        !practiceStates.contains(fields['state'])) {
      throw const FormatException('Select a valid practice type and state.');
    }
  }

  static const locumKeys = [
    'fullName',
    'email',
    'nric',
    'phoneNumber',
    'gender',
    'dateOfBirth',
    'highestEducation',
    'course',
  ];
  static const practiceKeys = [
    'practiceType',
    'clinicName',
    'registrationNumber',
    'address',
    'state',
    'contactNumber',
    'companyEmail',
  ];
  static const practiceTypes = [
    'Hospital',
    'Private Optical Clinic',
    'Retail Optical Store',
    'University/Training Institution',
  ];
  static const practiceStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
  ];
  final String uid, id;
  final VerificationAccountType accountType;
  final Map<String, String> fields;
  final VerificationDocument? document;
  String get kind =>
      accountType == VerificationAccountType.locum ? 'locum' : 'practice_owner';
  String get documentPath => 'verification_documents/$uid/$id/document';
  String get fingerprint {
    final keys = fields.keys.toList()..sort();
    return sha256
        .convert(
          utf8.encode(
            jsonEncode([
              uid,
              kind,
              {for (final key in keys) key: fields[key]},
              document?.sha256Hex,
              document?.name,
            ]),
          ),
        )
        .toString();
  }

  Map<String, dynamic> get payload => {
    'uid': uid,
    'accountType': kind,
    'schemaVersion': 1,
    'fields': fields,
    'fingerprint': fingerprint,
    if (document case final doc?)
      'document': {
        'path': documentPath,
        'name': doc.name,
        'contentType': doc.contentType,
        'size': doc.bytes.length,
        'sha256': doc.sha256Hex,
      },
  };

  static String _newId() {
    final random = Random.secure();
    return List.generate(
      20,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

abstract interface class VerificationSubmissionClient {
  Future<void> submit(
    VerificationSubmission submission, {
    Future<void> Function()? saveProfile,
  });
}

/// Phase 1 deliberately has no production-enabling build flag.
class DisabledVerificationSubmissions implements VerificationSubmissionClient {
  const DisabledVerificationSubmissions();
  static const message =
      'Verification submission is not enabled yet. Please try again once submissions are available.';
  @override
  Future<void> submit(
    VerificationSubmission submission, {
    Future<void> Function()? saveProfile,
  }) async {
    throw StateError(message);
  }
}
