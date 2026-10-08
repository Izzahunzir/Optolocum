import 'package:flutter/foundation.dart';

enum COVerificationStatus { unverified, pending, verified }

/// Update from the account service's response, and reset on logout or account
/// changes. Form validation and submission must never mark an account verified.
final coVerificationStatus = ValueNotifier<COVerificationStatus>(
  COVerificationStatus.unverified,
);
