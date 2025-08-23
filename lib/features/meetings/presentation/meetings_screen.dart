import 'package:agrifinity/features/meetings/presentation/meeting_guide_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/meetings_repository.dart';
import '../../../core/context/current_context.dart';
import 'meeting_summary_dialog.dart';
import 'confirm_dialog.dart';
import 'viewmodels/meetings_viewmodel.dart';

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MeetingsViewModel(MeetingsRepository()),
      child: const _MeetingsBody(),
    );
  }
}

class _MeetingsBody extends StatefulWidget {
  const _MeetingsBody();

  @override
  State<_MeetingsBody> createState() => _MeetingsBodyState();
}

class _MeetingsBodyState extends State<_MeetingsBody> {
  @override
  void initState() {
    super.initState();
    final appCtx = context.read<CurrentContext>();
    final cycleId = appCtx.cycleId ?? 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingsViewModel>().load(cycleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MeetingsViewModel>();
    final active = vm.activeMeeting;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Meetings',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              final appCtx = context.read<CurrentContext>();
              final cycleId = appCtx.cycleId ?? 1;
              vm.load(cycleId);
            },
          ),
        ],
      ),
      body:
          vm.busy
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  if (vm.error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        vm.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (!vm.busy && vm.meetings.isEmpty)
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          final appCtx = context.read<CurrentContext>();
                          final cycleId = appCtx.cycleId ?? 1;
                          await vm.load(cycleId);
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No meetings found',
                                    style: GoogleFonts.redHatDisplay(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Pull down to refresh.',
                                    style: GoogleFonts.redHatDisplay(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (active != null)
                    Card(
                      color: Colors.yellow[100],
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Meeting #${active.id} is ACTIVE',
                                        style: GoogleFonts.redHatDisplay(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Remember to end the meeting after all records are captured.',
                                        style: GoogleFonts.redHatDisplay(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    textStyle: GoogleFonts.redHatDisplay(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => MeetingGuidePage(
                                              meetingId: active.id,
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Text('Resume'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    textStyle: GoogleFonts.redHatDisplay(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () async {
                                    final summary = await showDialog<String>(
                                      context: context,
                                      builder:
                                          (context) => MeetingSummaryDialog(
                                            onSave: (val) {},
                                          ),
                                    );
                                    if (summary != null &&
                                        summary.trim().isNotEmpty) {
                                      await vm.endMeeting(
                                        active.id,
                                        notes: summary.trim(),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Meeting ended'),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('End Meeting'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (vm.meetings.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: vm.meetings.length,
                        itemBuilder: (context, i) {
                          final m = vm.meetings[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  m.active == true
                                      ? Icons.play_circle_fill
                                      : Icons.check_circle,
                                  color:
                                      m.status == "completed"
                                          ? Colors.green
                                          : (m.meetingDate != null
                                              ? Colors.green
                                              : Colors.grey),
                                ),
                                title: Text(
                                  'Meeting #${m.id}',
                                  style: GoogleFonts.redHatDisplay(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Scheduled: ${m.scheduledAt}',
                                      style: GoogleFonts.redHatDisplay(),
                                    ),
                                    Text(
                                      m.status ?? 'Status: Upcoming',
                                      style: GoogleFonts.redHatDisplay(
                                        color:
                                            m.meetingDate != null
                                                ? Colors.green
                                                : Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (m.closingNotes != null &&
                                        m.closingNotes!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          'Summary: ${m.closingNotes}',
                                          style: GoogleFonts.redHatDisplay(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  if (m.active == true) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => MeetingGuidePage(
                                              meetingId: m.id,
                                            ),
                                      ),
                                    );
                                  }
                                },
                                trailing:
                                    (m.status == "completed")
                                        ? null
                                        : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            textStyle:
                                                GoogleFonts.redHatDisplay(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          onPressed: () async {
                                            if (m.active == false) {
                                              final confirm = await showDialog<
                                                bool
                                              >(
                                                context: context,
                                                builder:
                                                    (context) => ConfirmDialog(
                                                      title: 'Start Meeting',
                                                      message:
                                                          'Are you sure you want to start this meeting?',
                                                      onConfirm: (val) {},
                                                    ),
                                              );
                                              if (confirm == true) {
                                                await vm.startMeeting(m.id);
                                                // ignore: use_build_context_synchronously
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) => MeetingGuidePage(
                                                          meetingId: m.id,
                                                        ),
                                                  ),
                                                );
                                              }
                                            } else {
                                              final summary = await showDialog<
                                                String
                                              >(
                                                context: context,
                                                builder:
                                                    (context) =>
                                                        MeetingSummaryDialog(
                                                          onSave: (val) {},
                                                        ),
                                              );
                                              if (summary != null &&
                                                  summary.trim().isNotEmpty) {
                                                await vm.endMeeting(
                                                  m.id,
                                                  notes: summary.trim(),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Meeting ended',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: Text(
                                            m.active == true ? 'End' : 'Start',
                                          ),
                                        ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
    );
  }
}
