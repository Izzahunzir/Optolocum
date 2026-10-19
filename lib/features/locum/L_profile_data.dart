import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

/// Session-only profile data. Connect this to the signed-in account service
/// when backend storage and document uploads are available.
class LocumProfileData {
  LocumProfileData({
    required Map<String, String> fields,
    required List<XFile> documents,
  }) : fields = Map.unmodifiable(fields),
       documents = List.unmodifiable(documents);

  final Map<String, String> fields;
  final List<XFile> documents;
}

final locumProfileData = ValueNotifier<LocumProfileData?>(null);
