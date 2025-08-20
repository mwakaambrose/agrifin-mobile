import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/accounts_repository.dart';
import 'viewmodels/accounts_viewmodel.dart';

class AccountsOverviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AccountsViewModel(AccountsRepository())..load(),
      child: const _AccountsBody(),
    );
  }
}

class _AccountsBody extends StatelessWidget {
  const _AccountsBody();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountsViewModel>();
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
          'Accounts Overview',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      body:
          vm.busy
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () => vm.load(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
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
                    ...vm.accounts.map(
                      (a) => Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            a.name,
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Text(
                            'UGX ${a.balance.toStringAsFixed(0)}',
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
