import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/verification_submission.dart';

class COVerificationForm extends StatefulWidget {
  const COVerificationForm({
    super.key,
    this.submissions = const DisabledVerificationSubmissions(),
    this.currentUid,
  });
  final VerificationSubmissionClient submissions;
  final String? Function()? currentUid;

  static const practiceTypes = [
    'Hospital',
    'Private Optical Clinic',
    'Retail Optical Store',
    'University/Training Institution',
  ];
  static const states = [
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

  @override
  State<COVerificationForm> createState() => _COVerificationFormState();
}

class _COVerificationFormState extends State<COVerificationForm> {
  static const _blue = Color(0xFF3B4E89);
  final _formKey = GlobalKey<FormState>();
  final _values = <String, String>{};
  bool _saving = false;
  VerificationSubmission? _attempt;
  String? _initialUid;

  String? _currentUid() => widget.currentUid != null
      ? widget.currentUid!()
      : FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (widget.submissions is! DisabledVerificationSubmissions) {
      _initialUid = _currentUid();
    }
  }

  static const _keys = {
    'Type of Practice': 'practiceType',
    'Clinic Name': 'clinicName',
    'Clinic Registration Number/ CSSM/ Business Registration':
        'registrationNumber',
    'Clinic Address': 'address',
    'State': 'state',
    'Clinic Contact Number': 'contactNumber',
    'Email (Company)': 'companyEmail',
  };

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
    filled: true,
    fillColor: Colors.white,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide.none,
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: _blue),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    isDense: true,
  );

  Widget _label(String label, Widget field) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF263C80)),
        ),
        const SizedBox(height: 7),
        field,
      ],
    ),
  );

  Widget _field(
    String label,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    Iterable<String>? autofillHints,
  }) => _label(
    label,
    TextFormField(
      onSaved: (value) => _values[_keys[label]!] = (value ?? '').trim(),
      enabled: !_saving,
      decoration: _decoration(hint),
      style: const TextStyle(fontSize: 14),
      keyboardType: keyboardType,
      maxLines: maxLines,
      autofillHints: autofillHints,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      validator:
          validator ??
          (value) => (value ?? '').trim().isEmpty
              ? 'Enter ${label.toLowerCase()}'
              : null,
    ),
  );

  Widget _dropdown(String label, List<String> items, String key) => _label(
    label,
    DropdownButtonFormField<String>(
      key: Key(key),
      decoration: _decoration('Select'),
      hint: const Text(
        'Select',
        style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
      ),
      isExpanded: true,
      menuMaxHeight: 320,
      dropdownColor: Colors.white,
      selectedItemBuilder: (context) => items
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          )
          .toList(),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: _saving ? null : (_) {},
      onSaved: (value) => _values[_keys[label]!] = value ?? '',
      validator: (value) =>
          value == null ? 'Select ${label.toLowerCase()}' : null,
    ),
  );

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      // Do not even initialize Firebase when the production gate is closed.
      if (widget.submissions is DisabledVerificationSubmissions) {
        throw StateError(DisabledVerificationSubmissions.message);
      }
      final uid = _currentUid();
      if (uid == null) throw StateError('Please sign in before submitting.');
      if (uid != _initialUid) {
        throw StateError('Your account changed. Please reopen the form.');
      }
      final candidate = VerificationSubmission(
        uid: uid,
        accountType: VerificationAccountType.practiceOwner,
        fields: _values,
      );
      if (_attempt?.fingerprint != candidate.fingerprint) _attempt = candidate;
      await widget.submissions.submit(_attempt!);
      if (!mounted) return;
      if (_currentUid() != uid) {
        throw StateError('Your account changed. Please reopen the form.');
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Your practice details have been submitted for review.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : error is FormatException
                  ? error.message
                  : 'Unable to submit practice details. Please retry.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2FAFE),
    appBar: AppBar(
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Account Verification',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEDF6),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Company Information',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Verify your clinic’s identity by filling out the\ninformation below',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 22),
                          _dropdown(
                            'Type of Practice',
                            COVerificationForm.practiceTypes,
                            'practice-type',
                          ),
                          _field(
                            'Clinic Name',
                            'Optometrist',
                            autofillHints: const [
                              AutofillHints.organizationName,
                            ],
                          ),
                          _field(
                            'Clinic Registration Number/ CSSM/ Business Registration',
                            'e.g., 202401012345 or KKM/CKAPS/12345',
                          ),
                          _field(
                            'Clinic Address',
                            'e.g. Lot G-22, Ground Floor, Suria KLCC, 50088 Kuala Lumpur',
                            keyboardType: TextInputType.multiline,
                            maxLines: 3,
                            autofillHints: const [
                              AutofillHints.fullStreetAddress,
                            ],
                          ),
                          _dropdown(
                            'State',
                            COVerificationForm.states,
                            'malaysian-state',
                          ),
                          _field(
                            'Clinic Contact Number',
                            'e.g., 0123456789 or 0312345678',
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            validator: (value) =>
                                RegExp(r'^\+?[0-9]{7,15}$').hasMatch(
                                  (value ?? '').replaceAll(
                                    RegExp(r'[\s()-]'),
                                    '',
                                  ),
                                )
                                ? null
                                : 'Enter a valid contact number',
                          ),
                          _field(
                            'Email (Company)',
                            'e.g., clinicname@gmail.com',
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: (value) =>
                                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch((value ?? '').trim())
                                ? null
                                : 'Enter a valid company email',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Verify Account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
