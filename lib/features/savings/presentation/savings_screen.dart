import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'viewmodels/savings_viewmodel.dart';
import '../data/savings_repository.dart';
import '../../../core/context/current_context.dart';
import '../../members/presentation/member_picker.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SavingsViewModel(SavingsRepository()),
      child: const _SavingsBody(),
    );
  }
}

class _SavingsBody extends StatefulWidget {
  const _SavingsBody();

  @override
  State<_SavingsBody> createState() => _SavingsBodyState();
}

class _SavingsBodyState extends State<_SavingsBody> {
  int? _previousCycleId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appCtx = context.watch<CurrentContext>();
    final cycleId = appCtx.cycleId;
    if (cycleId != null && cycleId != _previousCycleId) {
      _previousCycleId = cycleId;
      // Use a post frame callback to avoid calling setState during a build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<SavingsViewModel>().loadAll(cycleId: cycleId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavingsViewModel>();
    final appCtx = context.watch<CurrentContext>();
    final meetingId = appCtx.activeMeetingId;
    final currency = NumberFormat('#,##0');

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
          'Savings',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        actions: [
          if (vm.activeMeetingFilter != null)
            IconButton(
              tooltip: 'Clear filter',
              onPressed:
                  vm.busy
                      ? null
                      : () async {
                        await vm.loadAll(cycleId: appCtx.cycleId);
                      },
              icon: Icon(
                Icons.filter_alt_off,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed:
                vm.busy
                    ? null
                    : () async {
                      if (vm.activeMeetingFilter == null) {
                        await vm.loadAll(cycleId: appCtx.cycleId);
                      } else {
                        await vm.loadForMeeting(vm.activeMeetingFilter!);
                      }
                    },
          ),
        ],
      ),
      body:
          vm.busy
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () {
                  if (vm.activeMeetingFilter == null) {
                    return vm.loadAll(cycleId: appCtx.cycleId);
                  } else {
                    return vm.loadForMeeting(vm.activeMeetingFilter!);
                  }
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Meeting filter chips
                    Row(
                      children: [
                        FilterChip(
                          label: const Text('All meetings'),
                          selected: vm.activeMeetingFilter == null,
                          onSelected:
                              vm.busy
                                  ? null
                                  : (_) => vm.loadAll(cycleId: appCtx.cycleId),
                          showCheckmark: false,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('This meeting'),
                          selected:
                              vm.activeMeetingFilter == meetingId &&
                              meetingId != null,
                          onSelected:
                              vm.busy || meetingId == null
                                  ? null
                                  : (_) => vm.loadForMeeting(meetingId),
                          showCheckmark: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        title: Text(
                          'Total Savings Balance',
                          style: GoogleFonts.redHatDisplay(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Cycle #${vm.summary?.cycleId ?? '-'}',
                          style: GoogleFonts.redHatDisplay(),
                        ),
                        trailing: Text(
                          '${currency.format(vm.summary?.balance ?? 0)} UGX',
                          style: GoogleFonts.redHatDisplay(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Recent Contributions',
                      style: GoogleFonts.redHatDisplay(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final t in vm.transactions)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          title: Text(
                            '+ ${currency.format(t.amount)} UGX',
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (t.memberName != null &&
                                  t.memberName!.isNotEmpty)
                                'Customer: ${t.memberName}',
                              t.date.toLocal().toString(),
                            ].where((e) => e.isNotEmpty).join('\n'),
                            style: GoogleFonts.redHatDisplay(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        int? selectedMemberId;
                        String? selectedMemberName;
                        final amountController = TextEditingController();
                        await showDialog(
                          context: context,
                          builder: (context) {
                            bool submitting = false;
                            return StatefulBuilder(
                              builder: (context, setLocalState) {
                                return AlertDialog(
                                  title: Text(
                                    'Contribute Savings',
                                    style: GoogleFonts.redHatDisplay(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MemberPicker(
                                        onSelected: (id, name) {
                                          selectedMemberId = id;
                                          selectedMemberName = name;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: amountController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Amount (UGX)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          submitting
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
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        foregroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        textStyle: GoogleFonts.redHatDisplay(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed:
                                          submitting
                                              ? null
                                              : () async {
                                                if (selectedMemberId == null ||
                                                    amountController
                                                        .text
                                                        .isEmpty) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Please select a member and enter amount.',
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                final amount =
                                                    int.tryParse(
                                                      amountController.text,
                                                    ) ??
                                                    0;
                                                if (amount <= 0) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Enter valid amount.',
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                if (meetingId == null) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'No active meeting.',
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                setLocalState(
                                                  () => submitting = true,
                                                );
                                                final ok = await vm.contribute(
                                                  memberId: selectedMemberId!,
                                                  amount: amount,
                                                  meetingId: meetingId,
                                                );
                                                if (!context.mounted) return;
                                                Navigator.pop(context);
                                                setLocalState(
                                                  () => submitting = false,
                                                );
                                                if (ok) {
                                                  if (vm.activeMeetingFilter !=
                                                      null) {
                                                    await vm.loadForMeeting(
                                                      vm.activeMeetingFilter!,
                                                    );
                                                  } else if (appCtx.cycleId !=
                                                      null) {
                                                    await vm.loadAll(
                                                      cycleId: appCtx.cycleId!,
                                                    );
                                                  }
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Contributed UGX ${amountController.text} for $selectedMemberName',
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  final err =
                                                      vm.error ??
                                                      'Failed to contribute';
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(err),
                                                    ),
                                                  );
                                                }
                                              },
                                      child:
                                          submitting
                                              ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Posting...'),
                                                ],
                                              )
                                              : const Text('Post'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                      style: FilledButton.styleFrom(
                        textStyle: GoogleFonts.redHatDisplay(
                          fontWeight: FontWeight.bold,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Contribute'),
                    ),
                  ],
                ),
              ),
    );
  }
}
