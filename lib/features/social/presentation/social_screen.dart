import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/social_repository.dart';
import 'viewmodels/social_viewmodel.dart';
import '../../../core/context/current_context.dart';
import '../../members/presentation/member_picker.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SocialViewModel(SocialRepository()),
      child: const _SocialBody(),
    );
  }
}

class _SocialBody extends StatelessWidget {
  const _SocialBody();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SocialViewModel>();
    final appCtx = context.watch<CurrentContext>();
    final cycleId = appCtx.cycleId ?? 1;
    final meetingId = appCtx.activeMeetingId ?? 1;
    final currency = NumberFormat('#,##0');
    if (!vm.busy && vm.balance == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SocialViewModel>().load(cycleId);
      });
    }
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
          'Social Fund',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        actions: [
          if (vm.activeMeetingFilter != null)
            IconButton(
              tooltip: 'Clear filter',
              color: Theme.of(context).colorScheme.onPrimary,
              onPressed: vm.busy ? null : () => vm.loadAll(cycleId),
              icon: const Icon(Icons.filter_alt_off),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed:
                vm.busy
                    ? null
                    : () async {
                      if (vm.activeMeetingFilter == null) {
                        await vm.loadAll(cycleId);
                      } else {
                        await vm.loadForMeeting(
                          meetingId: vm.activeMeetingFilter!,
                          cycleId: cycleId,
                        );
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
                    return vm.loadAll(cycleId);
                  } else {
                    return vm.loadForMeeting(
                      meetingId: vm.activeMeetingFilter!,
                      cycleId: cycleId,
                    );
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
                              vm.busy ? null : (_) => vm.loadAll(cycleId),
                          showCheckmark: false,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('This meeting'),
                          selected: vm.activeMeetingFilter == meetingId,
                          onSelected:
                              vm.busy
                                  ? null
                                  : (_) => vm.loadForMeeting(
                                    meetingId: meetingId,
                                    cycleId: cycleId,
                                  ),
                          showCheckmark: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (vm.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          vm.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (vm.balance != null)
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          title: Text(
                            'Social Fund Balance',
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Cycle #${vm.balance!.cycleId}',
                            style: GoogleFonts.redHatDisplay(),
                          ),
                          trailing: Text(
                            '${currency.format(vm.balance!.balance)} UGX',
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
                    for (final c in vm.contributions)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          title: Text(
                            '+ ${currency.format(c.amount)} UGX',
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (c.memberName != null &&
                                  c.memberName!.isNotEmpty)
                                '${c.memberName}',
                              c.date.toLocal().toString(),
                            ].where((e) => e.isNotEmpty).join(' \u2022 '),
                            style: GoogleFonts.redHatDisplay(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            vm.busy
                ? null
                : () async {
                  int? selectedMemberId;
                  final amountController = TextEditingController();
                  DateTime selectedDate = DateTime.now();
                  await showDialog(
                    context: context,
                    builder: (context) {
                      bool submitting = false;
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: Text(
                              'Contribute to Social Fund',
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
                                      setState(() => selectedMemberId = id);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: amountController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Amount (UGX)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                                    ),
                                    trailing: const Icon(Icons.calendar_today),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setState(() => selectedDate = picked);
                                      }
                                    },
                                  ),
                                ],
                              ),
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
                                    submitting
                                        ? null
                                        : () async {
                                          if (selectedMemberId == null ||
                                              amountController.text.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Select member & enter amount.',
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
                                          setState(() => submitting = true);
                                          final ok = await vm.addContribution(
                                            meetingId: meetingId,
                                            memberId: selectedMemberId!,
                                            amount: amount,
                                            date: selectedDate,
                                          );
                                          if (!context.mounted) return;
                                          setState(() => submitting = false);
                                          if (ok) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Contribution added.',
                                                ),
                                              ),
                                            );
                                          } else {
                                            final err =
                                                vm.error ??
                                                'Failed to add contribution';
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(content: Text(err)),
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
                                              child: CircularProgressIndicator(
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
        icon: const Icon(Icons.volunteer_activism),
        label: Text(
          'Contribute',
          style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
