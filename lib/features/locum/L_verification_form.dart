import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'L_mainpage.dart';

class LVerificationForm extends StatefulWidget {
  const LVerificationForm({super.key, this.displayName = ''});
  final String displayName;

  @override
  State<LVerificationForm> createState() => _LVerificationFormState();
}

class _LVerificationFormState extends State<LVerificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _documents = <XFile>[];
  bool _uploadStep = false;
  String? _documentError;

  Future<void> _pickDocuments() async {
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Verification documents',
            extensions: ['pdf', 'png', 'jpg', 'jpeg'],
            mimeTypes: ['application/pdf', 'image/png', 'image/jpeg'],
          ),
        ],
      );
      final accepted = <XFile>[];
      for (final file in files) {
        if (await file.length() > 50 * 1024 * 1024) {
          if (mounted) {
            setState(() => _documentError = '${file.name} exceeds 50 MB.');
          }
          continue;
        }
        if (![
          'pdf',
          'png',
          'jpg',
          'jpeg',
        ].contains(file.name.split('.').last.toLowerCase())) {
          continue;
        }
        accepted.add(file);
      }
      if (!mounted) return;
      setState(() {
        _documents.addAll(
          accepted.where(
            (file) => !_documents.any((existing) => existing.path == file.path),
          ),
        );
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _documentError = 'Could not select documents. Please try again.',
        );
      }
    }
  }

  void _submit() {
    if (_documents.isEmpty) {
      setState(
        () => _documentError = 'Choose at least one verification document.',
      );
      return;
    }
    // Local preview only. Backend submission and approval must be connected.
    locumVerificationStatus.value = LocumVerificationStatus.pending;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LMainPage()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Verification preview is pending. Document upload and review are not connected yet.',
        ),
      ),
    );
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
    String? initialValue,
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
          initialValue: initialValue,
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
      leading: BackButton(
        onPressed: () {
          if (_uploadStep) {
            setState(() => _uploadStep = false);
          } else {
            Navigator.of(context).maybePop();
          }
        },
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _uploadStep ? 'Upload Documents' : 'Personal Information',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                        _field('Full Name', initialValue: widget.displayName),
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
                              RegExp(r'^\d{12}$')
                                  .hasMatch((value ?? '').replaceAll('-', ''))
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
                            final date = DateTime.tryParse(value ?? '');
                            return date == null || date.isAfter(DateTime.now())
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
              const Text(
                'Please upload clear and valid documents for verification.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    Text('Choose a file or documents'),
                    Text(
                      'PNG, JPG and PDF up to 50 MB',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
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
                      onPressed: () => setState(() => _documents.remove(file)),
                    ),
                  ),
                ),
              ),
              if (_documentError != null)
                Text(
                  _documentError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
              onPressed: _uploadStep
                  ? _submit
                  : () {
                      if (_formKey.currentState!.validate()) {
                        FocusScope.of(context).unfocus();
                        setState(() => _uploadStep = true);
                      }
                    },
              child: Text(_uploadStep ? 'Verify Account' : 'Next'),
            ),
          ],
        ),
      ),
    ),
  );
}
