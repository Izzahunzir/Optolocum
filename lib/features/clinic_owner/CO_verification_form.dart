import 'package:flutter/material.dart';

class COVerificationForm extends StatefulWidget {
  const COVerificationForm({super.key});

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
      onChanged: (_) {},
      validator: (value) =>
          value == null ? 'Select ${label.toLowerCase()}' : null,
    ),
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Your details are ready. Verification submission is coming soon.',
          ),
        ),
      );
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
                      onPressed: _submit,
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
