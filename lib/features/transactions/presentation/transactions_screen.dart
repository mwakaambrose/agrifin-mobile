import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../data/transaction_models.dart';
import '../data/transactions_repository.dart';
import 'viewmodels/transactions_viewmodel.dart';
import '../../../core/context/current_context.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransactionsViewModel(TransactionsRepository()),
        ),
      ],
      child: const _TransactionsBody(),
    );
  }
}

class _TransactionsBody extends StatelessWidget {
  const _TransactionsBody();

  String _label(TransactionType t) {
    switch (t) {
      case TransactionType.savings:
        return 'Savings';
      case TransactionType.loanDisbursement:
        return 'Loan Disbursement';
      case TransactionType.loanRepayment:
        return 'Loan Repayment';
      case TransactionType.fine:
        return 'Fine';
      case TransactionType.social:
        return 'Social Fund';
    }
  }

  IconData _icon(TransactionType t) {
    switch (t) {
      case TransactionType.savings:
        return Icons.savings;
      case TransactionType.loanDisbursement:
        return Icons.upload;
      case TransactionType.loanRepayment:
        return Icons.download_done;
      case TransactionType.fine:
        return Icons.receipt_long;
      case TransactionType.social:
        return Icons.favorite;
    }
  }

  Color _chipColor(BuildContext context, TransactionType t) {
    final scheme = Theme.of(context).colorScheme;
    switch (t) {
      case TransactionType.savings:
        return scheme.primary.withOpacity(0.15);
      case TransactionType.loanDisbursement:
        return Colors.orange.withOpacity(0.15);
      case TransactionType.loanRepayment:
        return Colors.green.withOpacity(0.15);
      case TransactionType.fine:
        return Colors.red.withOpacity(0.15);
      case TransactionType.social:
        return Colors.purple.withOpacity(0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TransactionsViewModel>();
    final ctx = context.watch<CurrentContext>();
    final cycleId = ctx.cycleId ?? 1;
    // Show a one-shot error toast when error appears
    if (vm.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = ScaffoldMessenger.of(context);
        if (messenger.mounted) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(vm.error!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
    // if (!vm.busy && vm.transactions.isEmpty) {
    //   // initial load
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     context.read<TransactionsViewModel>().load(cycleId);
    //   });
    // }
    final types = TransactionType.values;
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
          'Transactions',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        actions: [
          if (vm.activeFilter != null)
            IconButton(
              tooltip: 'Clear filter',
              onPressed: vm.busy ? null : vm.clearFilter,
              icon: Icon(
                Icons.filter_alt_off,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                final t = types[i];
                final selected = vm.activeFilter == t;
                return FilterChip(
                  label: Text(_label(t)),
                  selected: selected,
                  avatar: Icon(_icon(t), size: 18),
                  onSelected:
                      (_) => vm.load(cycleId, filter: selected ? null : t),
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.25),
                  backgroundColor: _chipColor(context, t),
                  showCheckmark: false,
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: types.length,
            ),
          ),
          if (vm.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                vm.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child:
                vm.busy
                    ? const Center(child: CircularProgressIndicator())
                    : vm.transactions.isEmpty
                    ? RefreshIndicator(
                      onRefresh:
                          () => vm.load(cycleId, filter: vm.activeFilter),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(32),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.2,
                          ),
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions yet',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.redHatDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            vm.activeFilter == null
                                ? 'Pull down to refresh.'
                                : 'Try clearing the filter or pull down to refresh.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.redHatDisplay(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh:
                          () => vm.load(cycleId, filter: vm.activeFilter),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.transactions.length,
                        itemBuilder: (_, i) {
                          final tr = vm.transactions[i];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _chipColor(context, tr.type),
                                child: Icon(
                                  _icon(tr.type),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                '${tr.amount} UGX • ${_label(tr.type)}',
                                style: GoogleFonts.redHatDisplay(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${tr.memberName ?? ''}\n${tr.description ?? ''}'
                                    .trim(),
                                style: GoogleFonts.redHatDisplay(),
                              ),
                              isThreeLine:
                                  (tr.memberName != null &&
                                      tr.description != null),
                              trailing: Text(
                                '${tr.date.year}-${tr.date.month.toString().padLeft(2, '0')}-${tr.date.day.toString().padLeft(2, '0')}',
                                style: GoogleFonts.redHatDisplay(fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
