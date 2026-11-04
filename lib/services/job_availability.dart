import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A stale page must never assume a job is still available.
class JobAvailability extends StatefulWidget {
  const JobAvailability({
    super.key,
    required this.jobId,
    required this.builder,
    this.statusStream,
  });
  final String jobId;
  final Stream<String>? statusStream;
  final Widget Function(BuildContext, bool available, bool deleted) builder;
  @override
  State<JobAvailability> createState() => _JobAvailabilityState();
}

class _JobAvailabilityState extends State<JobAvailability> {
  late Stream<String> stream = _watch();
  Stream<String> _watch() {
    if (widget.statusStream != null) return widget.statusStream!;
    try {
      return FirebaseFirestore.instance
          .collection('job_postings')
          .doc(widget.jobId)
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) => snapshot.metadata.isFromCache
                ? 'unknown'
                : snapshot.data()?['status']?.toString() ?? 'unknown',
          );
    } catch (_) {
      return Stream.value('unknown');
    }
  }

  @override
  void didUpdateWidget(covariant JobAvailability oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobId != widget.jobId ||
        oldWidget.statusStream != widget.statusStream) {
      stream = _watch();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<String>(
    stream: stream,
    builder: (context, snapshot) => widget.builder(
      context,
      snapshot.connectionState != ConnectionState.waiting &&
          snapshot.connectionState != ConnectionState.none &&
          !snapshot.hasError &&
          snapshot.data == 'available',
      !snapshot.hasError && snapshot.data == 'deleted',
    ),
  );
}
