import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'viewmodels/loans_viewmodel.dart';
import '../data/loan_repository.dart';
import '../data/loan_models.dart';
import '../../../core/context/current_context.dart';
import '../../members/presentation/member_picker.dart';
import '../../member/viewmodel/member_list_viewmodel.dart';
import '../../constitution/viewmodels/constitution_viewmodel.dart';
import '../../constitution/data/constitution_repository.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoansViewModel(LoanRepository())),
        ChangeNotifierProvider(create: (_) => MemberListViewModel()),
        ChangeNotifierProvider(
          create: (_) => ConstitutionViewModel(ConstitutionRepository()),
        ),
      ],
      child: const _LoansBody(),
    );
  }
}

class _LoansBody extends StatefulWidget {
  const _LoansBody();

  @override
  State<_LoansBody> createState() => _LoansBodyState();
}

class _LoansBodyState extends State<_LoansBody> {
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
          context.read<LoansViewModel>().load(cycleId);
          context.read<MemberListViewModel>().load();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoansViewModel>();
    final memberVm = context.watch<MemberListViewModel>();
    final appCtx = context.watch<CurrentContext>();
    final cycleId = appCtx.cycleId ?? 1;
    final meetingId = appCtx.activeMeetingId ?? 1;
    final currency = NumberFormat('#,##0');
    String fmtAmount(int v) => '${currency.format(v)} UGX';
    String fmtDate(DateTime d) => DateFormat.yMMMd().format(d);

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
          'Loans',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed:
                vm.busy
                    ? null
                    : () {
                      context.read<LoansViewModel>().load(cycleId);
                      context.read<MemberListViewModel>().load();
                    },
          ),
        ],
      ),
      body:
          vm.busy
              ? const Center(child: CircularProgressIndicator())
              : (vm.error != null && vm.loans.isEmpty)
              ? _EmptyState(
                message: vm.error!,
                onRetry: () => context.read<LoansViewModel>().load(cycleId),
              )
              : (vm.loans.isEmpty)
              ? _EmptyState(
                message: 'No loans found yet.',
                onRetry: () => context.read<LoansViewModel>().load(cycleId),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: vm.loans.length,
                itemBuilder: (_, i) {
                  final l = vm.loans[i];
                  // Prefer API-provided member name/phone; fall back to Members VM.
                  String memberName = l.memberName ?? 'Unknown';
                  String memberPhone = l.memberPhone ?? '-';
                  if (l.memberName == null || l.memberPhone == null) {
                    final m =
                        memberVm.members
                            .where((m) => m.id == l.memberId)
                            .firstOrNull;
                    if (m != null) {
                      memberName = m.name;
                      memberPhone = m.phone ?? '-';
                    }
                  }
                  // Repayment progress & outstanding from schedule
                  final sch = l.schedule ?? const <LoanRepaymentScheduleItem>[];
                  final totalInstallments = sch.length;
                  final paidCount = sch.where((s) => s.paid).length;
                  final outstanding = sch
                      .where((s) => !s.paid)
                      .fold<int>(0, (sum, s) => sum + s.total);
                  final progress =
                      totalInstallments == 0
                          ? 0.0
                          : paidCount / totalInstallments;
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      title: Text(
                        '${fmtAmount(l.amount)} • ${l.purpose}',
                        style: GoogleFonts.redHatDisplay(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$memberName ($memberPhone)',
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Term: ${l.termWeeks} weeks • ${l.interestType.name} ${l.interestRate}% • ${l.status}',
                            style: GoogleFonts.redHatDisplay(),
                          ),
                          if (totalInstallments > 0) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$paidCount/$totalInstallments paid • Outstanding: ${fmtAmount(outstanding)}',
                              style: GoogleFonts.redHatDisplay(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final schedule =
                            l.schedule ?? const <LoanRepaymentScheduleItem>[];
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                          ),
                          builder: (_) {
                            bool paying = false;
                            return StatefulBuilder(
                              builder: (context, setSheetState) {
                                final unpaid =
                                    schedule.where((s) => !s.paid).toList();
                                final nextDue =
                                    unpaid.isNotEmpty ? unpaid.first : null;
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    24,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Repayment Schedule',
                                            style: GoogleFonts.redHatDisplay(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (nextDue != null)
                                            Text(
                                              'Next: ${fmtAmount(nextDue.total)}',
                                              style: GoogleFonts.redHatDisplay(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (schedule.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 24,
                                          ),
                                          child: Text(
                                            'No schedule available.',
                                            style: GoogleFonts.redHatDisplay(),
                                          ),
                                        )
                                      else
                                        Flexible(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: schedule.length,
                                            itemBuilder: (_, idx) {
                                              final s = schedule[idx];
                                              return ListTile(
                                                leading: CircleAvatar(
                                                  child: Text(
                                                    '${s.installment}',
                                                  ),
                                                ),
                                                title: Text(
                                                  fmtAmount(s.total),
                                                  style:
                                                      GoogleFonts.redHatDisplay(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                subtitle: Text(
                                                  'Due: ${fmtDate(s.dueDate)} • Principal: ${fmtAmount(s.principal)} Interest: ${fmtAmount(s.interest)}',
                                                  style:
                                                      GoogleFonts.redHatDisplay(),
                                                ),
                                                trailing: Icon(
                                                  s.paid
                                                      ? Icons.check_circle
                                                      : Icons
                                                          .radio_button_unchecked,
                                                  color:
                                                      s.paid
                                                          ? Colors.green
                                                          : null,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            foregroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                            minimumSize: const Size(
                                              double.infinity,
                                              52,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed:
                                              (nextDue == null || paying)
                                                  ? null
                                                  : () async {
                                                    setSheetState(
                                                      () => paying = true,
                                                    );
                                                    final ok = await vm
                                                        .repayLoan(
                                                          meetingId: meetingId,
                                                          loanId: l.id,
                                                          amount: nextDue.total,
                                                        );
                                                    if (!context.mounted)
                                                      return;
                                                    setSheetState(
                                                      () => paying = false,
                                                    );
                                                    if (ok) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Repayment of ${fmtAmount(nextDue.total)} recorded.',
                                                          ),
                                                        ),
                                                      );
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    } else {
                                                      final err =
                                                          vm.error ??
                                                          'Failed to repay';
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(err),
                                                        ),
                                                      );
                                                    }
                                                  },
                                          icon:
                                              paying
                                                  ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : const Icon(Icons.payments),
                                          label: Text(
                                            paying
                                                ? 'Processing...'
                                                : nextDue == null
                                                ? 'Fully paid'
                                                : 'Repay ${fmtAmount(nextDue.total)}',
                                            style: GoogleFonts.redHatDisplay(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Ensure constitution is loaded before showing dialog
          final constitutionVm = context.read<ConstitutionViewModel>();
          if (constitutionVm.isEmpty) {
            await constitutionVm.refresh();
          }

          int? selectedMemberId;
          String? selectedMemberName;
          final amountController = TextEditingController();
          final purposes = <String>[
            'Business',
            'School fees',
            'Medical',
            'Agriculture inputs',
            'Household needs',
            'Emergency',
            'Rent',
            'Education',
            'Income generating activity',
          ];
          String? selectedPurpose;
          final termController = TextEditingController();
          final loansSection = constitutionVm.sections.firstWhere(
            (s) => s.kind == SectionKind.loans,
            orElse:
                () => ConstitutionSection(
                  id: 'loans',
                  title: 'Loans',
                  kind: SectionKind.loans,
                  body: '',
                  settings: {'interestType': 'flat', 'interestRate': 0.0},
                ),
          );
          final settings = loansSection.settings;
          final String settingsInterestType =
              (settings['interestType'] as String?) ?? 'flat';
          final double settingsInterestRate =
              (settings['interestRate'] as num?)?.toDouble() ?? 0.0;
          InterestType interestType =
              settingsInterestType == 'reducing_balance'
                  ? InterestType.reducing
                  : InterestType.flat;
          final rateDisplay = settingsInterestRate.toString();
          final rateController = TextEditingController(text: rateDisplay);

          await showDialog(
            context: context,
            builder: (context) {
              bool submitting = false;
              return StatefulBuilder(
                builder: (context, setLocalState) {
                  return AlertDialog(
                    title: Text(
                      'Apply for Loan',
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedPurpose,
                            decoration: InputDecoration(
                              labelText: 'Purpose',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items:
                                purposes
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) =>
                                    setLocalState(() => selectedPurpose = val),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: termController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Term (weeks)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<InterestType>(
                            value: interestType,
                            decoration: InputDecoration(
                              labelText: 'Interest Type (from constitution)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items:
                                InterestType.values
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                null, // This is read-only from constitution
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: rateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText:
                                  'Interest Rate (%) (from constitution)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed:
                            submitting ? null : () => Navigator.pop(context),
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
                                      amountController.text.isEmpty ||
                                      selectedPurpose == null ||
                                      termController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Fill all fields.'),
                                      ),
                                    );
                                    return;
                                  }
                                  final amount =
                                      int.tryParse(amountController.text) ?? 0;
                                  final term =
                                      int.tryParse(termController.text) ?? 0;
                                  if (amount <= 0 || term <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invalid values.'),
                                      ),
                                    );
                                    return;
                                  }
                                  setLocalState(() => submitting = true);
                                  final ok = await vm.applyLoan(
                                    meetingId: meetingId,
                                    memberId: selectedMemberId!,
                                    amount: amount,
                                    termWeeks: term,
                                    interestType: interestType,
                                    interestRate: settingsInterestRate,
                                    purpose: selectedPurpose!,
                                  );
                                  if (!context.mounted) return;
                                  setLocalState(() => submitting = false);
                                  if (ok) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Loan application submitted for $selectedMemberName',
                                        ),
                                      ),
                                    );
                                  } else {
                                    final err =
                                        vm.error ?? 'Failed to apply for loan';
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                    Text('Submitting...'),
                                  ],
                                )
                                : const Text('Apply'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        label: const Text('Apply for Loan'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _EmptyState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.redHatDisplay(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
