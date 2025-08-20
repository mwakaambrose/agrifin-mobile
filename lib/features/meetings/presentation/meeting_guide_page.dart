import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/context/current_context.dart';
import '../../meetings/data/api/meetings_api_repository.dart';

class MeetingGuidePage extends StatefulWidget {
  final int meetingId;
  const MeetingGuidePage({required this.meetingId});

  @override
  State<MeetingGuidePage> createState() => _MeetingGuidePageState();
}

class _MeetingGuidePageState extends State<MeetingGuidePage> {
  int _step = 0;
  bool _savingStep = false;
  final List<String> _steps = [
    'Take Attendance',
    'Record Loans',
    'Record Savings',
    'Social Fund',
    'Fines',
  ];

  String _slugForStep(int index) {
    switch (index) {
      case 0:
        return 'attendance';
      case 1:
        return 'loans';
      case 2:
        return 'savings';
      case 3:
        return 'social';
      case 4:
        return 'fines';
      default:
        return 'attendance';
    }
  }

  int _indexFromSlug(String? slug) {
    switch ((slug ?? '').toLowerCase()) {
      case 'attendance':
        return 0;
      case 'loans':
        return 1;
      case 'savings':
        return 2;
      case 'social':
        return 3;
      case 'fines':
        return 4;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    // Try resume from server current_step so guide opens at exact step
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cycleId = context.read<CurrentContext>().cycleId;
      if (cycleId == null) return;
      try {
        final api = MeetingsApiRepository();
        final list = await api.list(cycleId: cycleId);
        // Find this meeting and resume its current_step if available
        var found = list.where((x) => x.id == widget.meetingId);
        if (found.isNotEmpty && mounted) {
          final m = found.first;
          setState(() {
            _step = _indexFromSlug(m.currentStep);
          });
        }
      } catch (_) {
        // ignore errors; user can still proceed manually
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Meeting Guide',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Step ${_step + 1} of ${_steps.length}',
              style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                // Navigate to the actual feature screen for the current step
                // Also set active meeting context so feature screens can use it
                context.read<CurrentContext>().setActiveMeeting(
                  widget.meetingId,
                );
                switch (_step) {
                  case 0: // Take Attendance
                    context.push('/attendance?meetingId=${widget.meetingId}');
                    break;
                  case 1: // Record Loans
                    context.push('/loans');
                    break;
                  case 2: // Record Savings
                    context.push('/savings');
                    break;
                  case 3: // Social Fund
                    context.push('/social');
                    break;
                  case 4: // Fines
                    context.push('/fines');
                    break;
                }
              },
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        _step == 0
                            ? Icons.groups
                            : _step == 1
                            ? Icons.account_balance
                            : _step == 2
                            ? Icons.savings
                            : _step == 3
                            ? Icons.volunteer_activism
                            : Icons.gavel,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _steps[_step],
                        style: GoogleFonts.redHatDisplay(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _step == 0
                            ? 'Mark attendance for all members.'
                            : _step == 1
                            ? 'Record all loan transactions.'
                            : _step == 2
                            ? 'Record all savings contributions.'
                            : _step == 3
                            ? 'Record social fund contributions.'
                            : 'Record fines for members.',
                        style: GoogleFonts.redHatDisplay(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_step > 0)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.redHatDisplay(),
                    ),
                    onPressed: () => setState(() => _step--),
                    child: Text('Back'),
                  ),
                if (_step < _steps.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.redHatDisplay(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed:
                        _savingStep
                            ? null
                            : () async {
                              final nextIndex = _step + 1;
                              final nextLabel = _steps[nextIndex];
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text(
                                        'Proceed to next step?',
                                        style: GoogleFonts.redHatDisplay(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        'Move to "$nextLabel" and save progress?',
                                        style: GoogleFonts.redHatDisplay(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.redHatDisplay(),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            foregroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            textStyle:
                                                GoogleFonts.redHatDisplay(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('Continue'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirmed != true) return;
                              final cycleId =
                                  context.read<CurrentContext>().cycleId;
                              if (cycleId == null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cycle not available.'),
                                    ),
                                  );
                                }
                                return;
                              }
                              setState(() => _savingStep = true);
                              try {
                                await MeetingsApiRepository().updateStep(
                                  cycleId: cycleId,
                                  meetingId: widget.meetingId,
                                  currentStep: _slugForStep(nextIndex),
                                );
                                if (!mounted) return;
                                setState(() {
                                  _step = nextIndex;
                                });
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to save step. Please try again.',
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted)
                                  setState(() => _savingStep = false);
                              }
                            },
                    child: Text('Next'),
                  ),
                if (_step == _steps.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.redHatDisplay(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Finish'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
