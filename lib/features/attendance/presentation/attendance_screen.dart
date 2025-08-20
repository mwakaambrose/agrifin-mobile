import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../data/attendance_repository.dart';
import 'attendance_viewmodel.dart';
import '../../members/data/members_repository.dart';
import '../../../core/context/current_context.dart';

class AttendanceScreen extends StatelessWidget {
  final int meetingId;
  const AttendanceScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => AttendanceViewModel(AttendanceRepository())..load(meetingId),
      child: _AttendanceBody(meetingId: meetingId),
    );
  }
}

class _AttendanceBody extends StatefulWidget {
  final int meetingId;
  const _AttendanceBody({required this.meetingId});

  @override
  State<_AttendanceBody> createState() => _AttendanceBodyState();
}

class _AttendanceBodyState extends State<_AttendanceBody> {
  final _membersRepo = MembersRepository();
  bool _loadingMembers = true;
  String? _membersError;
  List<MemberLite> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _membersError = null;
    });
    try {
      final cycleId = context.read<CurrentContext>().cycleId ?? 1;
      final data = await _membersRepo.listByCycle(cycleId);
      if (mounted) setState(() => _members = data);
    } catch (e) {
      if (mounted) setState(() => _membersError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceViewModel>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
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
        title: Text(
          'Mark Attendance',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      body:
          vm.loading && _loadingMembers
              ? const Center(child: CircularProgressIndicator())
              : vm.error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              )
              : _membersError != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _membersError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _loadMembers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  await vm.load(widget.meetingId);
                  await _loadMembers();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _members.length,
                  itemBuilder: (context, i) {
                    final m = _members[i];
                    final rec = vm.records.firstWhere(
                      (r) => r.cycleMemberId == m.id,
                      orElse:
                          () => AttendanceRecordDto(
                            id: -1,
                            meetingId: widget.meetingId,
                            cycleMemberId: m.id,
                            status: '-',
                          ),
                    );
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text(
                          m.name,
                          style: GoogleFonts.redHatDisplay(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Status: ${rec.status}',
                          style: GoogleFonts.redHatDisplay(),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Mark Present',
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed: () async {
                                await vm.mark(
                                  meetingId: widget.meetingId,
                                  memberId: m.id,
                                  status: 'present',
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Marked Present: ${m.name}'),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'Mark Absent',
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                await vm.mark(
                                  meetingId: widget.meetingId,
                                  memberId: m.id,
                                  status: 'absent',
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Marked Absent: ${m.name}'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {
            // Return to Meeting Guide
            context.pop();
          },
          child: const Text('Complete Attendance'),
        ),
      ),
    );
  }
}
