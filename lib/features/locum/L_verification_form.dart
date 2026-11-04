import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import '../../services/locum_profile_service.dart';
import '../../services/verification_submission.dart';

import 'L_mainpage.dart';
import 'L_profile_data.dart';

class LVerificationForm extends StatefulWidget {
  const LVerificationForm({
    super.key,
    this.displayName = '',
    this.isEditing = false,
    this.submissions = const DisabledVerificationSubmissions(),
    this.profileService,
    this.pickDocument,
  });
  final String displayName;

  // false: first-time verification; true: update from the Account tab.
  final bool isEditing;
  final VerificationSubmissionClient submissions;
  final LocumProfileService? profileService;
  final Future<XFile?> Function()? pickDocument;

  @override
  State<LVerificationForm> createState() => _LVerificationFormState();
}

class _LVerificationFormState extends State<LVerificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _documents = <XFile>[];
  bool _uploadStep = false;
  String? _documentError;
  late final Map<String, TextEditingController> _controllers;
  late final _service = widget.profileService ?? LocumProfileService.instance;
  VerificationSubmission? _attempt;
  StreamSubscription<dynamic>? _authSubscription;
  String? _uid;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  bool _accountChanged = false;

  @override
  void initState() {
    super.initState();
    _uid = _service.currentUid;
    _controllers = {
      for (final label in [
        'Full Name',
        'Email',
        'NRIC',
        'Phone Number',
        'Gender',
        'Date of Birth',
        'Highest Education',
        'Course',
      ])
        label: TextEditingController(
          text: (label == 'Full Name' ? widget.displayName : ''),
        ),
    };
    _authSubscription = _service.authStateChanges.listen((user) {
      if (user?.uid != _uid && mounted) {
        for (final controller in _controllers.values) {
          controller.clear();
        }
        setState(() {
          _accountChanged = true;
          _documents.clear();
          _loadError = 'Your account changed. Please reopen this form.';
        });
      }
    });
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final uid = _uid;
      if (uid == null) throw StateError('Please sign in first.');
      final profile = await _service.load(uid);
      if (!mounted || _accountChanged || _service.currentUid != uid) return;
      if (profile != null) {
        for (final entry in _controllers.entries) {
          entry.value.text = profile.fields[entry.key] ?? '';
        }
        _documents
          ..clear()
          ..addAll(profile.documents);
      }
    } catch (_) {
      if (mounted && !_accountChanged) {
        _loadError = 'Unable to load profile. Check your connection and retry.';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDocuments() async {
    try {
      final file =
          await (widget.pickDocument?.call() ??
              openFile(
                acceptedTypeGroups: [
                  const XTypeGroup(
                    label: 'Verification documents',
                    extensions: ['pdf', 'png', 'jpg', 'jpeg'],
                    mimeTypes: ['application/pdf', 'image/png', 'image/jpeg'],
                  ),
                ],
              ));
      if (file == null) return;
      await VerificationDocument.fromFile(file);
      if (!mounted || _accountChanged || _service.currentUid != _uid) return;
      setState(() {
        _documentError = null;
        _documents
          ..clear()
          ..add(file);
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _documentError = error is FormatException
              ? error.message
              : 'Could not select document. Please try again.',
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_saving || _loading || _loadError != null || _accountChanged) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _uploadStep = false);
      return;
    }
    final uid = _uid;
    if (uid == null || _service.currentUid != uid) return;
    if (_documents.length != 1) {
      setState(
        () => _documentError = 'Choose exactly one PDF, JPG, JPEG, or PNG.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final profile = LocumProfileData(
        uid: uid,
        verificationStatus: 'pending',
        fields: {
          for (final entry in _controllers.entries)
            entry.key: entry.value.text.trim(),
        },
        documents: _documents,
      );
      final candidate = VerificationSubmission(
        uid: uid,
        accountType: VerificationAccountType.locum,
        fields: profile.toFirestore().cast<String, String>()
          ..remove('verificationStatus'),
        document: await VerificationDocument.fromFile(_documents.single),
      );
      if (_attempt?.fingerprint != candidate.fingerprint) _attempt = candidate;
      final submissionsDisabled =
          widget.submissions is DisabledVerificationSubmissions;
      if (submissionsDisabled) {
        // Preserve the existing profile-only workflow until deployment approval.
        await _service.save(profile);
      } else {
        await widget.submissions.submit(
          _attempt!,
          saveProfile: () => _service.save(profile),
        );
      }
      if (!mounted || _accountChanged || _service.currentUid != uid) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            submissionsDisabled
                ? 'Profile saved. Your document has not been uploaded or submitted for verification.'
                : 'Your details and document have been submitted for review.',
          ),
        ),
      );
      if (widget.isEditing) {
        // EDIT MODE: return to the existing profile, keeping its navigation.
        Navigator.of(context).pop();
      } else {
        // INITIAL MODE: finish onboarding by opening the main page.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const LMainPage()),
        );
      }
    } catch (error) {
      if (!mounted || _accountChanged) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : error is FormatException
                ? error.message
                : 'Unable to submit verification. Your progress is retained; please retry.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration() => const InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  Widget _field(
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF237F7D),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: _controllers[label],
          decoration: _decoration(),
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          validator:
              validator ??
              (value) => (value ?? '').trim().isEmpty
                  ? 'Enter ${label.toLowerCase()}'
                  : null,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FCFB),
    appBar: AppBar(
      backgroundColor: const Color(0xFF237F7D),
      foregroundColor: Colors.white,
      title: const Text(
        'Account Verification',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
        onPressed: _saving
            ? null
            : () {
                if (_uploadStep) {
                  setState(() => _uploadStep = false);
                } else {
                  Navigator.of(context).maybePop();
                }
              },
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _loadError != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                if (!_accountChanged)
                  TextButton(
                    onPressed: _loadProfile,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          )
        : AbsorbPointer(
            absorbing: _saving,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _uploadStep
                            ? 'Document Preview'
                            : 'Personal Information',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Offstage(
                        offstage: _uploadStep,
                        child: Form(
                          key: _formKey,
                          child: Card(
                            color: const Color(0xFFECF6F5),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _field('Full Name'),
                                  _field(
                                    'Email',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) =>
                                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                            .hasMatch((value ?? '').trim())
                                        ? null
                                        : 'Enter a valid email',
                                  ),
                                  _field(
                                    'NRIC',
                                    keyboardType: TextInputType.number,
                                    validator: (value) =>
                                        RegExp(r'^\d{12}$').hasMatch(
                                          (value ?? '').replaceAll('-', ''),
                                        )
                                        ? null
                                        : 'Enter a 12-digit NRIC',
                                  ),
                                  _field(
                                    'Phone Number',
                                    keyboardType: TextInputType.phone,
                                    validator: (value) =>
                                        RegExp(r'^\+?\d{7,15}$').hasMatch(
                                          (value ?? '').replaceAll(
                                            RegExp(r'[\s()-]'),
                                            '',
                                          ),
                                        )
                                        ? null
                                        : 'Enter a valid phone number',
                                  ),
                                  _field('Gender'),
                                  _field(
                                    'Date of Birth',
                                    keyboardType: TextInputType.datetime,
                                    validator: (value) {
                                      final date = DateTime.tryParse(
                                        value ?? '',
                                      );
                                      return date == null ||
                                              date.isAfter(DateTime.now())
                                          ? 'Enter a valid past date (YYYY-MM-DD)'
                                          : null;
                                    },
                                  ),
                                  _field('Highest Education'),
                                  _field('Course'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_uploadStep) ...[
                        Text(
                          widget.submissions is DisabledVerificationSubmissions
                              ? 'Choose one document for private review. Submission is currently unavailable until verification is enabled.'
                              : 'Choose one document to submit privately for Admin review.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: _pickDocuments,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.cloud_upload,
                                size: 54,
                                color: Color(0xFFDDDFDF),
                              ),
                              Text('Choose one document'),
                              Text(
                                'PNG, JPG, JPEG or PDF up to 50 MB',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._documents.map(
                          (file) => Card(
                            color: const Color(0xFFEEF2F1),
                            child: ListTile(
                              leading: Icon(
                                file.name.toLowerCase().endsWith('.pdf')
                                    ? Icons.picture_as_pdf
                                    : Icons.image,
                                color: Colors.red,
                              ),
                              title: Text(
                                file.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                              trailing: IconButton(
                                tooltip: 'Remove document',
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    setState(() => _documents.remove(file)),
                              ),
                            ),
                          ),
                        ),
                        if (_documentError != null)
                          Text(
                            _documentError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF237F7D),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _saving
                            ? null
                            : _uploadStep
                            ? _submit
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  FocusScope.of(context).unfocus();
                                  setState(() => _uploadStep = true);
                                }
                              },
                        // The shared upload step has a different final action in edit mode.
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _uploadStep
                                    ? (widget.isEditing
                                          ? 'Update'
                                          : 'Save Profile')
                                    : 'Next',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
  );
}
