import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../data/fines_models.dart';
import '../data/fines_repository.dart';
import 'viewmodels/fines_viewmodel.dart';
import '../../../core/context/current_context.dart';
import '../../members/presentation/member_picker.dart';

class FinesScreen extends StatelessWidget {
  const FinesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinesViewModel(FinesRepository()),
      child: const _FinesBody(),
    );
  }
}

class _FinesBody extends StatefulWidget {
  const _FinesBody();

  @override
  State<_FinesBody> createState() => _FinesBodyState();
}

class _FinesBodyState extends State<_FinesBody> {
  int? _previousCycleId;
  int? _previousMeetingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appCtx = context.watch<CurrentContext>();
    final cycleId = appCtx.cycleId;
    final meetingId = appCtx.activeMeetingId;

    if (cycleId != null &&
        meetingId != null &&
        (cycleId != _previousCycleId || meetingId != _previousMeetingId)) {
      _previousCycleId = cycleId;
      _previousMeetingId = meetingId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<FinesViewModel>().ensureLoaded(cycleId, meetingId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinesViewModel>();
    final appCtx = context.watch<CurrentContext>();
    final cycleId = appCtx.cycleId;
    final meetingId = appCtx.activeMeetingId;

    final canLoad = cycleId != null && meetingId != null;

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
          'Fines',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed:
                canLoad
                    ? () =>
                        context.read<FinesViewModel>().load(cycleId, meetingId)
                    : null,
          ),
        ],
      ),
      body:
          !canLoad
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No active cycle or meeting. Please start a meeting to manage fines.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.redHatDisplay(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.home),
                        label: const Text('Go to Home'),
                      ),
                    ],
                  ),
                ),
              )
              : vm.busy
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh:
                    () =>
                        context.read<FinesViewModel>().load(cycleId, meetingId),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (vm.error != null)
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: ListTile(
                          title: Text(
                            'Failed to load fines',
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                            ),
                          ),
                          subtitle: Text(
                            vm.error!,
                            style: GoogleFonts.redHatDisplay(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                            ),
                          ),
                          trailing: TextButton.icon(
                            onPressed:
                                () => context.read<FinesViewModel>().load(
                                  cycleId,
                                  meetingId,
                                ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reload'),
                          ),
                        ),
                      ),
                    Text(
                      'Fine Types',
                      style: GoogleFonts.redHatDisplay(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (vm.types.isEmpty && vm.error == null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No fine types yet. Please set them in the Constitution.',
                              style: GoogleFonts.redHatDisplay(),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => context.push('/constitution'),
                              icon: const Icon(Icons.rule),
                              label: Text(
                                'Open Constitution',
                                style: GoogleFonts.redHatDisplay(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final t in vm.types)
                            Chip(
                              label: Text(
                                '${t.name} • ${t.amount} UGX',
                                style: GoogleFonts.redHatDisplay(),
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.08),
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Recent Fines',
                      style: GoogleFonts.redHatDisplay(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (vm.records.isEmpty && vm.error == null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'No fines recorded for this meeting yet.',
                          style: GoogleFonts.redHatDisplay(),
                        ),
                      )
                    else
                      ...vm.records.map((r) {
                        final memberName =
                            (r.member?['name'] as String?)?.trim();
                        final displayName =
                            (memberName != null && memberName.isNotEmpty)
                                ? memberName
                                : 'Member #${r.memberId}';
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            title: Text(
                              r.type.name,
                              style: GoogleFonts.redHatDisplay(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '$displayName • ${r.date.toLocal()}',
                              style: GoogleFonts.redHatDisplay(),
                            ),
                            trailing: Icon(
                              r.paid ? Icons.check_circle : Icons.pending,
                              color: r.paid ? Colors.green : null,
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text(
          'Assign Fine',
          style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold),
        ),
        onPressed:
            canLoad
                ? () async {
                  if (vm.types.isEmpty) return; // nothing to assign yet
                  int? selectedMemberId;
                  FineType? selectedType;
                  DateTime selectedDate = DateTime.now();
                  bool saving = false;
                  String? saveError;
                  await showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return ChangeNotifierProvider.value(
                        value: vm,
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              title: Text(
                                'Assign Fine',
                                style: GoogleFonts.redHatDisplay(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MemberPicker(
                                      onSelected: (id, name) {
                                        setState(() {
                                          selectedMemberId = id;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<FineType>(
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'Fine Type',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      items:
                                          vm.types
                                              .map(
                                                (t) => DropdownMenuItem(
                                                  value: t,
                                                  child: Text(
                                                    '${t.name} • ${t.amount} UGX',
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      value: selectedType,
                                      onChanged: (val) {
                                        setState(() {
                                          selectedType = val;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                                      ),
                                      trailing: const Icon(
                                        Icons.calendar_today,
                                      ),
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: selectedDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            selectedDate = picked;
                                          });
                                        }
                                      },
                                    ),
                                    if (saveError != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        saveError ?? '',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      saving
                                          ? null
                                          : () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.redHatDisplay(),
                                  ),
                                ),
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
                                  onPressed:
                                      saving
                                          ? null
                                          : () async {
                                            if (selectedMemberId == null ||
                                                selectedType == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Select member & fine type.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            setState(() {
                                              saving = true;
                                              saveError = null;
                                            });
                                            try {
                                              await context
                                                  .read<FinesViewModel>()
                                                  .assignAndRefresh(
                                                    cycleId: cycleId,
                                                    meetingId: meetingId,
                                                    memberId: selectedMemberId!,
                                                    type: selectedType!,
                                                    amount:
                                                        selectedType!.adjustable
                                                            ? selectedType!
                                                                .amount
                                                            : null,
                                                  );
                                              if (context.mounted) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Fine assigned.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              setState(
                                                () => saveError = e.toString(),
                                              );
                                            } finally {
                                              if (context.mounted) {
                                                setState(() {
                                                  saving = false;
                                                });
                                              }
                                            }
                                          },
                                  child:
                                      saving
                                          ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text('Assign'),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  );
                }
                : null,
      ),
    );
  }
}
