import 'package:flutter/material.dart';

import 'dart:async';

import 'CO_navigation.dart';
import 'CO_mainpage.dart';
import 'CO_profile.dart';

/// Session-only posting data. Replace with account-scoped persistence later.
class COJobPosting {
  const COJobPosting({
    required this.placeName,
    required this.location,
    required this.role,
    required this.date,
    required this.start,
    required this.end,
    required this.pay,
    required this.payUnit,
    required this.description,
    required this.contactPerson,
    required this.contactNumber,
    this.imageUrl,
    this.applicantCount = 0,
  });
  final String placeName,
      location,
      role,
      payUnit,
      description,
      contactPerson,
      contactNumber;
  final DateTime date;
  final TimeOfDay start, end;
  final double pay;
  final String? imageUrl;
  final int applicantCount;
}

final coJobPostings = ValueNotifier<List<COJobPosting>>(const []);

class COPostingJob extends StatefulWidget {
  const COPostingJob({super.key});

  @override
  State<COPostingJob> createState() => _COPostingJobState();
}

class _COPostingJobState extends State<COPostingJob> {
  bool _justPosted = false;
  Timer? _successTimer;

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  Future<void> _create(BuildContext context) async {
    final posting = await showDialog<COJobPosting>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PostingForm(),
    );
    if (posting == null || !context.mounted) return;
    coJobPostings.value = List.unmodifiable([...coJobPostings.value, posting]);
    setState(() => _justPosted = true);
    _successTimer?.cancel();
    _successTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _justPosted = false);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2FAFE),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text(
        'Job Posting',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF3B4E92),
      foregroundColor: Colors.white,
    ),
    body: ValueListenableBuilder<List<COJobPosting>>(
      valueListenable: coJobPostings,
      builder: (context, jobs, _) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 640,
                minHeight: (constraints.maxHeight - 44).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_justPosted)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEFFDE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check,
                              color: Color(0xFF239D32),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Job Added Successfully!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF237F3A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Text(
                    'My Jobs Postings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage your locum job postings',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.description,
                                  color: Color(0xFF9B89ED),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  '${jobs.length}',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                            const Text(
                              'Active Postings',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (jobs.isEmpty) ...[
                    const SizedBox(height: 64),
                    const Center(
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: Stack(
                          children: [
                            Icon(
                              Icons.description_rounded,
                              size: 106,
                              color: Color(0xFF9B89ED),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 4,
                              child: Icon(
                                Icons.search,
                                size: 46,
                                color: Color(0xFF263C80),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'You haven’t posted any locum jobs yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Find qualified optometrists and staff by\ncreating your first job posting',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                  ] else ...[
                    const SizedBox(height: 22),
                    const Text(
                      'Active Postings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...jobs.map((job) => COPostedJobCard(job: job)),
                    const SizedBox(height: 20),
                  ],
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _create(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF263C80),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Job Posting'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: CONavigation(
      postingSelected: true,
      onPosting: () => _create(context),
      onHome: () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const COMainPage()),
        (route) => route.isFirst,
      ),
      onProfile: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const COProfile()),
      ),
    ),
  );
}

class COPostedJobCard extends StatelessWidget {
  const COPostedJobCard({super.key, required this.job});
  final COJobPosting job;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF172441);
    Widget detail(
      IconData icon,
      String text, {
      String? caption,
      bool bold = true,
    }) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26, color: ink),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              if (caption != null)
                Text(caption, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
    final minutes =
        job.end.hour * 60 +
        job.end.minute -
        job.start.hour * 60 -
        job.start.minute;
    final hours = minutes / 60;
    final duration = hours == hours.roundToDouble()
        ? hours.toInt().toString()
        : hours.toStringAsFixed(1);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF263C80),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_outlined, size: 25, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '${job.applicantCount} locum applied',
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFDDF0FF),
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 92,
                    height: 72,
                    child: job.imageUrl == null
                        ? const ColoredBox(
                            color: Color(0xFFC5DFEE),
                            child: Icon(
                              Icons.storefront_outlined,
                              size: 38,
                              color: Color(0xFF3B4E92),
                            ),
                          )
                        : Image.network(
                            job.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) =>
                                const Icon(Icons.storefront_outlined, size: 38),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.role,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      detail(Icons.business_outlined, job.placeName),
                      const SizedBox(height: 6),
                      detail(
                        Icons.location_on_outlined,
                        job.location,
                        bold: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 10,
                  child: detail(
                    Icons.calendar_today_outlined,
                    MaterialLocalizations.of(context)
                        .formatMediumDate(job.date),
                    caption: '(One day)',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 13,
                  child: detail(
                    Icons.access_time,
                    '${job.start.format(context)} - ${job.end.format(context)}',
                    caption: '($duration hrs)',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 10,
                  child: detail(
                    Icons.account_balance_wallet_outlined,
                    'RM ${job.pay.toStringAsFixed(2)} ${job.payUnit.toLowerCase()}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            detail(Icons.person_outline, job.contactPerson, bold: false),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 340 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      detail(
                        Icons.phone_outlined,
                        job.contactNumber,
                        bold: false,
                      ),
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerRight, child: badge),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: detail(
                        Icons.phone_outlined,
                        job.contactNumber,
                        bold: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    badge,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PostingForm extends StatefulWidget {
  const _PostingForm();
  @override
  State<_PostingForm> createState() => _PostingFormState();
}

class _PostingFormState extends State<_PostingForm> {
  final _key = GlobalKey<FormState>();
  final _values = <String, String>{};
  final _dateText = TextEditingController();
  final _startText = TextEditingController();
  final _endText = TextEditingController();
  DateTime? _date;
  TimeOfDay? _start, _end;
  String _unit = 'Per hour';

  @override
  void dispose() {
    _dateText.dispose();
    _startText.dispose();
    _endText.dispose();
    super.dispose();
  }

  InputDecoration decoration({IconData? icon, String? prefix}) =>
      InputDecoration(
        isDense: true,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      );
  Widget label(String text, Widget input) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 7),
        input,
      ],
    ),
  );
  Widget field(
    String name, {
    IconData? icon,
    int lines = 1,
    TextInputType? type,
  }) => label(
    name,
    TextFormField(
      decoration: decoration(
        icon: icon,
        prefix: name == 'Pay Rate' ? 'RM ' : null,
      ),
      maxLines: lines,
      keyboardType: type,
      onSaved: (value) => _values[name] = value!.trim(),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) return 'Required';
        if (name == 'Pay Rate') {
          final amount = double.tryParse(value!.trim());
          if (amount == null || !amount.isFinite || amount <= 0)
            return 'Enter a positive rate';
        }
        if (name == 'Contact Number' &&
            !RegExp(r'^\+?[0-9]{7,15}$')
                .hasMatch(value!.replaceAll(RegExp(r'[\s()-]'), '')))
          return 'Enter a valid number';
        return null;
      },
    ),
  );
  Widget section(String title) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF263C80),
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Future<void> pickDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null && mounted)
      setState(() {
        _date = selected;
        _dateText.text = MaterialLocalizations.of(context)
            .formatMediumDate(selected);
      });
  }

  Future<void> pickTime(bool start) async {
    final selected = await showTimePicker(
      context: context,
      initialTime:
          (start ? _start : _end) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (selected != null && mounted)
      setState(() {
        if (start) {
          _start = selected;
          _startText.text = selected.format(context);
        } else {
          _end = selected;
          _endText.text = selected.format(context);
        }
      });
  }

  void submit() {
    if (!_key.currentState!.validate()) return;
    _key.currentState!.save();
    Navigator.pop(
      context,
      COJobPosting(
        placeName: _values['Place Name']!,
        location: _values['Location']!,
        role: _values['Role']!,
        date: _date!,
        start: _start!,
        end: _end!,
        pay: double.parse(_values['Pay Rate']!),
        payUnit: _unit,
        description: _values['Basic Job Description']!,
        contactPerson: _values['Contact Person']!,
        contactNumber: _values['Contact Number']!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create Job Posting',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close job form',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Fill in the details below to post your locum job',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              section('1. Company Information'),
              field('Place Name'),
              field('Location', icon: Icons.location_on_outlined),
              section('2. Job Details'),
              field('Role'),
              label(
                'Date',
                TextFormField(
                  controller: _dateText,
                  readOnly: true,
                  onTap: pickDate,
                  decoration: decoration(icon: Icons.calendar_today_outlined),
                  validator: (_) => _date == null ? 'Select a date' : null,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: label(
                      'Start Time',
                      TextFormField(
                        controller: _startText,
                        readOnly: true,
                        onTap: () => pickTime(true),
                        decoration: decoration(icon: Icons.access_time),
                        validator: (_) =>
                            _start == null ? 'Select start time' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: label(
                      'End Time',
                      TextFormField(
                        controller: _endText,
                        readOnly: true,
                        onTap: () => pickTime(false),
                        decoration: decoration(icon: Icons.access_time),
                        validator: (_) {
                          if (_end == null) return 'Select end time';
                          if (_start != null &&
                              _end!.hour * 60 + _end!.minute <=
                                  _start!.hour * 60 + _start!.minute)
                            return 'Must be after start';
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: field(
                      'Pay Rate',
                      type: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: label(
                      'Rate Unit',
                      DropdownButtonFormField<String>(
                        initialValue: _unit,
                        isExpanded: true,
                        decoration: decoration(),
                        items: const ['Per hour', 'Per day', 'Per shift']
                            .map(
                              (unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(
                                  unit,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => _unit = value!,
                      ),
                    ),
                  ),
                ],
              ),
              section('3. Job Description'),
              field(
                'Basic Job Description',
                lines: 4,
                type: TextInputType.multiline,
              ),
              section('4. Contact'),
              field('Contact Person', icon: Icons.person_outline),
              field(
                'Contact Number',
                icon: Icons.phone_outlined,
                type: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF263C80),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Post Job'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
