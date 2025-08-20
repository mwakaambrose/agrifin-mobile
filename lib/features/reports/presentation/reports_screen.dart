import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'viewmodels/reports_viewmodel.dart';
import '../../../core/context/current_context.dart';

class ReportsScreen extends StatelessWidget {
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
                    // Screen description
                    // Text(
                    //   'Comprehensive, cycle-based financial insights for the group including Profit & Loss, savings performance, loans exposure, fines, social fund position and member-level statements.',
                    //   style: GoogleFonts.redHatDisplay(
                    //     fontSize: 14,
                    //     color: Theme.of(
                    //       context,
                    //     ).colorScheme.onSurface.withOpacity(0.75),
                    //   ),
                    // ),
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
                            // const SizedBox(height: 8),
                            // Text(
                            //   'P&L, savings, fines, loans, welfare, member statements',
                            //   textAlign: TextAlign.center,
                            //   style: GoogleFonts.redHatDisplay(
                            //     fontSize: 16,
                            //     color: Theme.of(context).colorScheme.onSurface,
                            //   ),
                            // ),
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
                            s.value,
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
                              i.value,
                              style: GoogleFonts.redHatDisplay(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }
}

// Removed unused _PnLCard widget
