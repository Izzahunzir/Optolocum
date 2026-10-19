import 'package:flutter/material.dart';

/// Temporary summary until the job posting service provides its full model.
class SavedLocumJob {
  const SavedLocumJob({
    required this.id,
    required this.title,
    this.clinic = '',
  });

  final String id;
  final String title;
  final String clinic;
}

/// Shared by the main-page bookmark buttons and the saved jobs page.
/// Session-only state; replace with account-backed storage when available.
final locumSavedJobs = LocumSavedJobs();

class LocumSavedJobs extends ValueNotifier<List<SavedLocumJob>> {
  LocumSavedJobs() : super(const []);

  bool contains(String id) => value.any((job) => job.id == id);

  void save(SavedLocumJob job) {
    value = List.unmodifiable([
      for (final existing in value)
        if (existing.id != job.id) existing,
      job,
    ]);
  }

  void remove(String id) {
    value = List.unmodifiable(value.where((job) => job.id != id));
  }

  void toggle(SavedLocumJob job) {
    if (contains(job.id)) {
      remove(job.id);
    } else {
      save(job);
    }
  }

  void clear() => value = const [];
}

/// Add to each future main-page job card using its stable posting ID.
class LocumSaveJobButton extends StatelessWidget {
  const LocumSaveJobButton({super.key, required this.job});

  final SavedLocumJob job;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<SavedLocumJob>>(
        valueListenable: locumSavedJobs,
        builder: (context, jobs, _) {
          final saved = jobs.any((item) => item.id == job.id);
          return IconButton(
            tooltip: saved ? 'Remove saved job' : 'Save job',
            isSelected: saved,
            icon: const Icon(Icons.bookmark_border),
            selectedIcon: const Icon(Icons.bookmark),
            color: const Color(0xFF052F2E),
            onPressed: () => locumSavedJobs.toggle(job),
          );
        },
      );
}

class LSavedJob extends StatelessWidget {
  const LSavedJob({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FCFB),
    appBar: AppBar(
      backgroundColor: const Color(0xFF237F7D),
      foregroundColor: Colors.white,
      centerTitle: false,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text(
        'Saved Job',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    ),
    body: ValueListenableBuilder<List<SavedLocumJob>>(
      valueListenable: locumSavedJobs,
      builder: (context, jobs, _) {
        if (jobs.isEmpty) return const SizedBox.expand();
        // Replace these summaries with full posting cards when available.
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: jobs.length,
          separatorBuilder: (_, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final job = jobs[index];
            return Material(
              color: const Color(0xFFEBF6F4),
              elevation: 3,
              borderRadius: BorderRadius.circular(18),
              child: ListTile(
                title: Text(job.title),
                subtitle: job.clinic.isEmpty ? null : Text(job.clinic),
                trailing: LocumSaveJobButton(job: job),
              ),
            );
          },
        );
      },
    ),
  );
}
