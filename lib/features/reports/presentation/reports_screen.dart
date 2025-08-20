import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'viewmodels/reports_viewmodel.dart';
import '../../../core/context/current_context.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportsViewModel(),
      child: const _ReportsBody(),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportsViewModel>();
    final appCtx = context.watch<CurrentContext>();
    final cycleId = appCtx.cycleId ?? 1;
    if (!vm.busy && vm.summaries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ReportsViewModel>().load(cycleId);
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
          'Financial Reports',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => vm.load(cycleId),
          ),
        ],
      ),
      body:
          vm.busy
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () => vm.load(cycleId),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 16),
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
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Cycle-based Reports',
                              style: GoogleFonts.redHatDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Shareout moved to its own card at the bottom
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Key Summaries',
                      style: GoogleFonts.redHatDisplay(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...vm.summaries.map(
                      (s) => Card(
                        child: ListTile(
                          title: Text(
                            s.title,
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Text(
                            s.amount == null
                                ? s.value
                                : NumberFormat.currency(
                                  locale: 'en_UG',
                                  symbol: 'UGX ',
                                  decimalDigits: 0,
                                ).format(s.amount),
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (vm.interestSummaries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Interest Summaries',
                        style: GoogleFonts.redHatDisplay(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...vm.interestSummaries.map(
                        (i) => Card(
                          child: ListTile(
                            title: Text(
                              i.title,
                              style: GoogleFonts.redHatDisplay(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              i.amount == null
                                  ? i.value
                                  : NumberFormat.currency(
                                    locale: 'en_UG',
                                    symbol: 'UGX ',
                                    decimalDigits: 0,
                                  ).format(i.amount),
                              style: GoogleFonts.redHatDisplay(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Shareout: bottom card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shareout',
                              style: GoogleFonts.redHatDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final f = NumberFormat.currency(
                                  locale: 'en_UG',
                                  symbol: 'UGX ',
                                  decimalDigits: 0,
                                );
                                final s = vm.shareout;
                                if (s == null && vm.shareoutError == null) {
                                  return const SizedBox.shrink();
                                }
                                if (vm.shareoutError != null) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Shareout unavailable',
                                          style: GoogleFonts.redHatDisplay(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => vm.reloadShareout(cycleId),
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  );
                                }
                                final executed = s!.executedAt != null;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.start,
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        _ShareoutChip(
                                          label: 'Total Savings',
                                          value: f.format(s.totalSavings),
                                        ),
                                        _ShareoutChip(
                                          label: 'Total Interest',
                                          value: f.format(s.totalInterest),
                                        ),
                                        _ShareoutChip(
                                          label: 'Total Fines',
                                          value: f.format(s.totalFines),
                                        ),
                                        _ShareoutChip(
                                          label: 'Total Profit',
                                          value: f.format(s.totalProfit),
                                        ),
                                        _ShareoutChip(
                                          label: 'Share Price',
                                          value: f.format(s.sharePrice),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (!executed && vm.canExecuteShareout)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: ElevatedButton.icon(
                                          icon:
                                              vm.executingShareout
                                                  ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                            Colors.white,
                                                          ),
                                                    ),
                                                  )
                                                  : const Icon(
                                                    Icons.play_arrow,
                                                  ),
                                          label: Text(
                                            vm.executingShareout
                                                ? 'Executing...'
                                                : 'Execute Shareout',
                                          ),
                                          onPressed:
                                              vm.executingShareout
                                                  ? null
                                                  : () async {
                                                    final ok = await vm
                                                        .executeShareout(
                                                          cycleId,
                                                        );
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          ok
                                                              ? 'Shareout executed'
                                                              : 'Failed to execute shareout',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                        ),
                                      ),
                                    if (!executed && !vm.canExecuteShareout)
                                      Text(
                                        'You can only execute shareout when closing the cycle.',
                                        style: GoogleFonts.redHatDisplay(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    if (executed)
                                      Text(
                                        'Executed at: ${s.executedAt}',
                                        style: GoogleFonts.redHatDisplay(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class _ShareoutChip extends StatelessWidget {
  final String label;
  final String value;
  const _ShareoutChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
        color: cs.primary.withOpacity(0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.redHatDisplay(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
