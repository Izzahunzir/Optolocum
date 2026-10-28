import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'L_applyJobDialog.dart';

class LJobDetails extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> job;

  const LJobDetails({super.key, required this.jobId, required this.job});

  @override
  Widget build(BuildContext context) {
    final rawDate = job['jobDate'];
    final date = rawDate is Timestamp ? rawDate.toDate() : null;

    final formattedDate = date == null
        ? 'Not specified'
        : '${const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1]}, '
              '${date.day} ${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][date.month - 1]} ${date.year}';

    String formatTime(dynamic value) {
      final text = value?.toString() ?? '-';
      final parts = text.split(':');
      if (parts.length != 2) return text;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return text;
      return '${hour % 12 == 0 ? 12 : hour % 12}:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
    }

    final payRate = job['payRate'] ?? 0;

    final payUnit = switch (job['payRateUnit']) {
      'per_hour' => 'hour',
      'per_day' => 'day',
      'per_shift' => 'shift',
      _ => 'session',
    };

    Widget detailRow(IconData icon, String title, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF17213D), size: 25),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF17213D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF758581),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFB),
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: const Color(0xFF248783),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF6F4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['role'] ?? 'Optometrist',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (job['rating'] is num) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFAD00),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${job['rating']}${job['reviewCount'] is num ? ' (${job['reviewCount']} reviews)' : ''}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    job['placeName'] ?? 'Unknown Clinic',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FCFB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        detailRow(
                          Icons.calendar_month_outlined,
                          'Date',
                          formattedDate,
                        ),
                        detailRow(
                          Icons.access_time,
                          'Time',
                          '${formatTime(job['startTime'])} - ${formatTime(job['endTime'])}',
                        ),
                        detailRow(
                          Icons.location_on_outlined,
                          'Location',
                          job['location'] ?? 'Not specified',
                        ),
                        detailRow(
                          Icons.payments_outlined,
                          'Rate Salary',
                          'RM $payRate / $payUnit',
                        ),
                        if (job['experience'] != null)
                          detailRow(
                            Icons.work_outline,
                            'Experience',
                            job['experience'].toString(),
                          ),
                        detailRow(
                          Icons.person_outline,
                          'Practice Owner',
                          job['contactPerson'] ?? 'Not specified',
                        ),
                        detailRow(
                          Icons.phone_outlined,
                          'Contact Number',
                          job['contactNumber'] ?? 'Not specified',
                        ),
                        detailRow(
                          Icons.description_outlined,
                          'Job Description',
                          job['jobDescription'] ?? 'No description provided.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        showApplyJobDialog(
                          context: context,
                          jobId: jobId,
                          jobTitle: job['role'] ?? 'Optometrist',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF248783),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF248783),
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Apply Now',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
}
