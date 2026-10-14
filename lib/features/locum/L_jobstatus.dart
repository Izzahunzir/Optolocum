import 'package:flutter/material.dart';

enum LocumJobStatus { hired, pending, rejected, completed }

/// Update this list from the application service after a successful application.
final locumJobApplications = ValueNotifier<List<LocumJobApplication>>([]);

class LocumJobApplication {
  const LocumJobApplication({
    required this.id,
    required this.title,
    required this.clinic,
    required this.address,
    required this.date,
    required this.hours,
    required this.rate,
    required this.owner,
    required this.phone,
    this.status = LocumJobStatus.pending,
    this.imageUrl,
    this.notes = '',
  });

  final String id, title, clinic, address, date, hours, rate, owner, phone;
  final String? imageUrl;
  final String notes;
  final LocumJobStatus status;
}

class LJobStatus extends StatelessWidget {
  const LJobStatus({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        const TabBar(
          labelColor: Color(0xFF237F7D),
          unselectedLabelColor: Color(0xFF237F7D),
          indicatorColor: Color(0xFF237F7D),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: 'Applied'),
            Tab(text: 'Completed'),
          ],
        ),
        Expanded(
          child: ValueListenableBuilder<List<LocumJobApplication>>(
            valueListenable: locumJobApplications,
            builder: (context, jobs, _) => TabBarView(
              children: [
                _ApplicationList(
                  jobs: jobs
                      .where((job) => job.status != LocumJobStatus.completed)
                      .toList(),
                ),
                _ApplicationList(
                  jobs: jobs
                      .where((job) => job.status == LocumJobStatus.completed)
                      .toList(),
                  completed: true,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ApplicationList extends StatelessWidget {
  const _ApplicationList({required this.jobs, this.completed = false});
  final List<LocumJobApplication> jobs;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                completed ? Icons.task_alt : Icons.work_outline,
                size: 44,
                color: const Color(0xFF237F7D),
              ),
              const SizedBox(height: 12),
              Text(
                completed ? 'No completed jobs yet' : 'No applications yet',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                completed ? 'Your completed jobs will appear here.' : 'Once you apply for a job, you can track its status here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      itemCount: jobs.length,
      separatorBuilder: (_, index) => const SizedBox(height: 18),
      itemBuilder: (context, index) => _ApplicationCard(job: jobs[index]),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.job});
  final LocumJobApplication job;

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF243C40)),
        const SizedBox(width: 7),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11))),
      ],
    ),
  );

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(job.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _line(Icons.storefront_outlined, job.clinic),
              _line(Icons.location_on_outlined, job.address),
              _line(Icons.calendar_month_outlined, job.date),
              _line(Icons.schedule, job.hours),
              _line(Icons.payments_outlined, job.rate),
              _line(Icons.person_outline, job.owner),
              _line(Icons.phone_outlined, job.phone),
              _line(Icons.assignment_outlined, 'Status: ${_label(job.status)}'),
              if (job.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(job.notes),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _label(LocumJobStatus status) => switch (status) {
    LocumJobStatus.hired => 'Hired',
    LocumJobStatus.pending => 'Pending',
    LocumJobStatus.rejected => 'Rejected',
    LocumJobStatus.completed => 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (job.status) {
      LocumJobStatus.hired => (
        const Color(0xFF397DCD),
        const Color(0xFFDCECFF),
      ),
      LocumJobStatus.pending => (
        const Color(0xFF987000),
        const Color(0xFFFFF0C5),
      ),
      LocumJobStatus.rejected => (
        const Color(0xFFBF4141),
        const Color(0xFFFFDDDD),
      ),
      LocumJobStatus.completed => (
        const Color(0xFF237F7D),
        const Color(0xFFDDF2EE),
      ),
    };
    final placeholder = Container(
      color: const Color(0xFFD5E8E5),
      child: const Icon(Icons.storefront_outlined, color: Color(0xFF237F7D)),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF6F4),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 3,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  width: 62,
                  height: 54,
                  child: job.imageUrl == null
                      ? placeholder
                      : Image.network(
                          job.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) => placeholder,
                        ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.clinic,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(job.address, style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _label(job.status),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _line(Icons.calendar_month_outlined, job.date)),
              Expanded(child: _line(Icons.schedule, job.hours)),
              Expanded(child: _line(Icons.payments_outlined, job.rate)),
            ],
          ),
          _line(Icons.person_outline, job.owner),
          _line(Icons.phone_outlined, job.phone),
          Center(
            child: TextButton(
              onPressed: () => _showDetails(context),
              child: const Text(
                'View Details',
                style: TextStyle(
                  color: Color(0xFF237F7D),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
