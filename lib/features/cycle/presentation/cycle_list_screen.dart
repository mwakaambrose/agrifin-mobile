import 'package:agrifinity/features/cycle/data/api/cycles_api_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'viewmodels/cycle_viewmodel.dart';

class CycleListScreen extends StatelessWidget {
  const CycleListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CycleViewModel(CyclesApiRepository())..load(),
      child: const _CycleBody(),
    );
  }
}

class _CycleBody extends StatelessWidget {
  const _CycleBody();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CycleViewModel>();
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
          'Cycles',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => vm.load(),
          ),
        ],
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
                    ...vm.cycles.map(
                      (c) => Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Icon(
                            c.isCurrent
                                ? Icons.play_circle_fill
                                : Icons.history,
                            color: c.isCurrent ? Colors.green : Colors.grey,
                          ),
                          title: Text(
                            c.name,
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${c.startDate.split(' ')[0]} → ${c.endDate.split(' ')[0]}',
                            style: GoogleFonts.redHatDisplay(),
                          ),
                          trailing:
                              c.isCurrent
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Text(
                                          'Active',
                                          style: GoogleFonts.redHatDisplay(
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          // Capture dependencies before async gap to satisfy lints
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final vm =
                                              context.read<CycleViewModel>();
                                          final confirm = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (ctx) => AlertDialog(
                                                  title: const Text(
                                                    'Close Cycle?',
                                                  ),
                                                  content: const Text(
                                                    'Closing a cycle will prevent further transactions in this cycle. Proceed?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            ctx,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    FilledButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            ctx,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Close',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );
                                          if (confirm == true) {
                                            await vm.closeCycle(c.id);
                                            if (vm.error != null) {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to close: ${vm.error}',
                                                  ),
                                                ),
                                              );
                                            } else {
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text('Cycle closed'),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.lock),
                                        label: const Text('Close'),
                                      ),
                                    ],
                                  )
                                  : Text(
                                    'Closed',
                                    style: GoogleFonts.redHatDisplay(
                                      color: Colors.grey,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final vm = context.read<CycleViewModel>();
          final TextEditingController controller = TextEditingController();

          final newCycleName = await showDialog<String>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Create New Cycle'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Cycle Name'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      child: const Text('Create'),
                    ),
                  ],
                ),
          );

          if (newCycleName != null && newCycleName.isNotEmpty) {
            final now = DateTime.now();
            final endOfYear = DateTime(now.year, 12, 31);

            final box = await Hive.openBox('user_data');
            dynamic groupId = box.get('group_id');

            await vm.createCycle(
              groupId: groupId,
              name: newCycleName,
              startDate: now.toIso8601String(),
              endDate: endOfYear.toIso8601String(),
              description: 'New cycle created via FAB',
              isCurrent: true,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
