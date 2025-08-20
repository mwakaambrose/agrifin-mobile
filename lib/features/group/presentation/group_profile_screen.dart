import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/group_viewmodel.dart';

class GroupProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupViewModel(),
      child: const _GroupBody(),
    );
  }
}

class _GroupBody extends StatelessWidget {
  const _GroupBody();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GroupViewModel>();
    final g = vm.group;
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
          'Group Profile',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => vm.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
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
                      Icons.info,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      g.name,
                      style: GoogleFonts.redHatDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Members: ${g.memberCount}',
                      style: GoogleFonts.redHatDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Meeting Frequency: ${g.meetingFrequency}',
                      style: GoogleFonts.redHatDisplay(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Savings: UGX ${g.totalSavings.toStringAsFixed(0)}',
                      style: GoogleFonts.redHatDisplay(),
                    ),
                    Text(
                      'Outstanding Loans: UGX ${g.outstandingLoans.toStringAsFixed(0)}',
                      style: GoogleFonts.redHatDisplay(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quick Actions',
              style: GoogleFonts.redHatDisplay(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionChip(
                  label: 'Rename',
                  icon: Icons.edit,
                  onTap: () async {
                    final controller = TextEditingController(text: g.name);
                    final ok = await showDialog<bool>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('Rename Group'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                    );
                    if (ok == true && controller.text.trim().isNotEmpty) {
                      vm.updateName(controller.text.trim());
                    }
                  },
                ),
                _ActionChip(
                  label: 'Add Savings +5k',
                  icon: Icons.savings,
                  onTap: () => vm.addSavings(5000),
                ),
                _ActionChip(
                  label: 'Adj Loans -2k',
                  icon: Icons.account_balance,
                  onTap: () => vm.adjustOutstandingLoans(-2000),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.w600),
      ),
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
    );
  }
}
