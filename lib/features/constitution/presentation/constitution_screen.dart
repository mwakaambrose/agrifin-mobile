import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/constitution_provider.dart';
import '../viewmodels/constitution_viewmodel.dart';
import '../../../core/context/current_context.dart';

class ConstitutionScreen extends StatefulWidget {
  @override
  State<ConstitutionScreen> createState() => _ConstitutionScreenState();
}

class _ConstitutionScreenState extends State<ConstitutionScreen> {
  @override
  Widget build(BuildContext context) {
    return ConstitutionProvider(
      child: Builder(
        builder: (context) {
          final vm = ConstitutionProvider.of(context);
          return AnimatedBuilder(
            animation: vm,
            builder: (context, _) {
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
                    'Constitution',
                    style: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  actions: [
                    if (!vm.isLocked && !vm.isLoading)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed:
                            vm.sections.isEmpty
                                ? null
                                : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          title: const Text(
                                            'Lock Constitution?',
                                          ),
                                          content: const Text(
                                            'Once locked, the constitution cannot be edited.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text('Lock'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    await vm.lockConstitution();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Constitution locked'),
                                        ),
                                      );
                                    }
                                  }
                                },
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Lock'),
                      ),
                  ],
                ),
                floatingActionButton:
                    (!vm.isLocked && !vm.isLoading)
                        ? FloatingActionButton(
                          onPressed: () async {
                            final result =
                                await showModalBottomSheet<ConstitutionSection>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder:
                                      (ctx) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              MediaQuery.of(
                                                ctx,
                                              ).viewInsets.bottom,
                                          left: 16,
                                          right: 16,
                                          top: 24,
                                        ),
                                        child: _SectionEditor(vm: vm),
                                      ),
                                );
                            if (result != null) {
                              vm.addSection(
                                result.title,
                                result.body,
                                kind: result.kind,
                                settings: result.settings,
                              );
                              try {
                                final appCtx = context.read<CurrentContext>();
                                final cycleId = appCtx.cycleId ?? 1;
                                await vm.syncSectionsToServer(cycleId);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Constitution saved.'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to sync constitution: ${e.toString()}',
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: const Icon(Icons.add),
                        )
                        : null,
                body:
                    vm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : vm.error != null
                        ? Center(child: Text(vm.error!))
                        : vm.isEmpty
                        ? _EmptyState(isLocked: vm.isLocked)
                        : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          itemBuilder: (context, index) {
                            final section = vm.sections[index];
                            return _SectionTile(
                              key: ValueKey(section.id),
                              section: section,
                              canEdit: !vm.isLocked,
                              onEdit: (updated) {
                                vm.updateSection(
                                  section.id,
                                  title: updated.title,
                                  body: updated.body,
                                  settings: updated.settings,
                                );
                              },
                              onDelete: () => vm.removeSection(section.id),
                              vm: vm,
                            );
                          },
                          itemCount: vm.sections.length,
                          onReorder: vm.isLocked ? (_, __) {} : vm.reorder,
                        ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isLocked;
  const _EmptyState({required this.isLocked});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rule,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isLocked
                  ? 'No sections defined'
                  : 'Add sections to build your constitution',
              textAlign: TextAlign.center,
              style: GoogleFonts.redHatDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final ConstitutionSection section;
  final bool canEdit;
  final void Function(ConstitutionSection updated) onEdit;
  final VoidCallback onDelete;
  final ConstitutionViewModel vm;
  const _SectionTile({
    super.key,
    required this.section,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    required this.vm,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      child: ListTile(
        title: Text(
          section.title,
          style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.body, style: GoogleFonts.redHatDisplay()),
              if (section.kind != SectionKind.generic) ...[
                const SizedBox(height: 8),
                _SettingsPreview(section: section),
              ],
            ],
          ),
        ),
        trailing:
            canEdit
                ? PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final updated = await showModalBottomSheet<
                        ConstitutionSection
                      >(
                        context: context,
                        isScrollControlled: true,
                        builder:
                            (ctx) => Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                                left: 16,
                                right: 16,
                                top: 24,
                              ),
                              child: _SectionEditor(initial: section, vm: vm),
                            ),
                      );
                      if (updated != null) {
                        onEdit(updated);
                      }
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text('Delete Section?'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) onDelete();
                    }
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                )
                : null,
      ),
    );
  }
}

class _SettingsPreview extends StatelessWidget {
  final ConstitutionSection section;
  const _SettingsPreview({required this.section});
  @override
  Widget build(BuildContext context) {
    switch (section.kind) {
      case SectionKind.savings:
        return Text(
          'Freq: ${section.settings['frequency']}  Min: ${section.settings['minContribution']}  Fixed: ${section.settings['fixedAmount']} ${section.settings['fixedAmount'] ? '(${section.settings['fixedAmountValue']})' : ''}  Penalty/Miss: ${section.settings['penaltyPerMiss']}',
          style: GoogleFonts.redHatDisplay(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
        );
      case SectionKind.loans:
        return Text(
          'Interest: ${section.settings['interestType']} ${section.settings['interestRate']}%  Max*Savings: ${section.settings['maxMultipleSavings']}  Penalty: ${section.settings['penaltyRate']}%  MaxDur: ${section.settings['maxDurationWeeks']}w',
          style: GoogleFonts.redHatDisplay(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
        );
      case SectionKind.socialFund:
        return Text(
          'Contribution: ${section.settings['contributionAmount']}  Approval: ${section.settings['approvalRule']}',
          style: GoogleFonts.redHatDisplay(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
        );
      case SectionKind.fines:
        final list = (section.settings['fineTypes'] as List?) ?? const [];
        final count = list.length;
        return Text(
          'Fines: $count type${count == 1 ? '' : 's'} configured',
          style: GoogleFonts.redHatDisplay(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
        );
      case SectionKind.generic:
        return const SizedBox.shrink();
    }
  }
}

class _SectionEditor extends StatefulWidget {
  final ConstitutionSection? initial;
  final ConstitutionViewModel vm;
  const _SectionEditor({this.initial, required this.vm});
  @override
  State<_SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends State<_SectionEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _body;
  SectionKind _kind = SectionKind.generic;
  bool _saving = false;
  String? _saveError;

  // Savings
  String _savingsFrequency = 'weekly';
  double _minContribution = 0;
  bool _fixedAmount = false;
  double _fixedAmountValue = 0;
  double _penaltyPerMiss = 0;

  // Loans
  String _interestType = 'flat';
  double _interestRate = 0;
  double _maxMultipleSavings = 3;
  double _penaltyRate = 0;
  int _maxDurationWeeks = 12;

  // Social Fund
  double _socialContribution = 0;
  String _approvalRule = 'Simple majority';
  String _usageNotes = 'Emergency assistance & welfare needs';
  // Fines
  final List<_FineTypeForm> _fineTypes = [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _body = TextEditingController(text: initial?.body ?? '');
    if (initial != null) {
      _kind = initial.kind;
      final set = initial.settings;
      switch (_kind) {
        case SectionKind.savings:
          _savingsFrequency = set['frequency'] ?? _savingsFrequency;
          _minContribution = (set['minContribution'] ?? 0).toDouble();
          _fixedAmount = set['fixedAmount'] ?? false;
          _fixedAmountValue = (set['fixedAmountValue'] ?? 0).toDouble();
          _penaltyPerMiss = (set['penaltyPerMiss'] ?? 0).toDouble();
          break;
        case SectionKind.loans:
          _interestType = set['interestType'] ?? _interestType;
          _interestRate = (set['interestRate'] ?? 0).toDouble();
          _maxMultipleSavings = (set['maxMultipleSavings'] ?? 3).toDouble();
          _penaltyRate = (set['penaltyRate'] ?? 0).toDouble();
          _maxDurationWeeks = (set['maxDurationWeeks'] ?? 12).toInt();
          break;
        case SectionKind.socialFund:
          _socialContribution = (set['contributionAmount'] ?? 0).toDouble();
          _approvalRule = set['approvalRule'] ?? _approvalRule;
          _usageNotes = set['usageNotes'] ?? _usageNotes;
          break;
        case SectionKind.fines:
          final list = (set['fineTypes'] as List?)?.cast<dynamic>() ?? const [];
          _fineTypes
            ..clear()
            ..addAll(
              list.map((e) {
                final m = e as Map;
                return _FineTypeForm(
                  name: (m['name'] ?? '').toString(),
                  amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
                );
              }),
            );
          break;
        case SectionKind.generic:
          break;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEdit ? 'Edit Section' : 'New Section',
              style: GoogleFonts.redHatDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (!isEdit) _kindSelector(),
            if (_kind != SectionKind.fines) ...[
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                decoration: const InputDecoration(
                  labelText: 'Content / Narrative',
                ),
                maxLines: 5,
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
            const SizedBox(height: 16),
            _settingsFields(),
            if (_saveError != null) ...[
              const SizedBox(height: 8),
              Text(
                _saveError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed:
                      _saving
                          ? null
                          : () async {
                            final formState = _formKey.currentState;
                            if (formState != null && formState.validate()) {
                              setState(() {
                                _saving = true;
                                _saveError = null;
                              });
                              try {
                                final settings = _buildSettings();
                                final resolvedTitle =
                                    _kind == SectionKind.fines
                                        ? (widget.initial?.title ?? 'Fines')
                                        : _title.text.trim();
                                final resolvedBody =
                                    _kind == SectionKind.fines
                                        ? (widget.initial?.body ??
                                            'Fine types and default amounts defined by the group.')
                                        : _body.text.trim();
                                final vm = widget.vm;
                                if (widget.initial != null) {
                                  vm.updateSection(
                                    widget.initial!.id,
                                    title: resolvedTitle,
                                    body: resolvedBody,
                                    settings: settings,
                                  );
                                } else {
                                  vm.addSection(
                                    resolvedTitle,
                                    resolvedBody,
                                    kind: _kind,
                                    settings: settings,
                                  );
                                }
                                // Sync to server via API
                                final appCtx = context.read<CurrentContext>();
                                final cycleId = appCtx.cycleId ?? 1;
                                await vm.syncSectionsToServer(cycleId);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Constitution saved.'),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                setState(() {
                                  _saveError = e.toString();
                                });
                              } finally {
                                if (mounted) {
                                  setState(() => _saving = false);
                                }
                              }
                            }
                          },
                  child:
                      _saving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(isEdit ? 'Save' : 'Add'),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 12),
          ],
        ),
      ),
    );
  }

  Widget _kindSelector() {
    return DropdownButtonFormField<SectionKind>(
      value: _kind,
      items: const [
        DropdownMenuItem(value: SectionKind.generic, child: Text('Generic')),
        DropdownMenuItem(value: SectionKind.savings, child: Text('Savings')),
        DropdownMenuItem(value: SectionKind.loans, child: Text('Loans')),
        DropdownMenuItem(
          value: SectionKind.socialFund,
          child: Text('Social Fund'),
        ),
        DropdownMenuItem(value: SectionKind.fines, child: Text('Fines')),
      ],
      onChanged: (v) => setState(() => _kind = v ?? SectionKind.generic),
      decoration: const InputDecoration(labelText: 'Section Type'),
    );
  }

  Widget _settingsFields() {
    switch (_kind) {
      case SectionKind.savings:
        return _savingsSettings();
      case SectionKind.loans:
        return _loanSettings();
      case SectionKind.socialFund:
        return _socialFundSettings();
      case SectionKind.fines:
        return _finesSettings();
      case SectionKind.generic:
        return const SizedBox.shrink();
    }
  }

  Map<String, dynamic> _buildSettings() {
    switch (_kind) {
      case SectionKind.savings:
        return {
          'frequency': _savingsFrequency,
          'minContribution': _minContribution,
          'fixedAmount': _fixedAmount,
          'fixedAmountValue': _fixedAmountValue,
          'penaltyPerMiss': _penaltyPerMiss,
        };
      case SectionKind.loans:
        return {
          'interestType': _interestType,
          'interestRate': _interestRate,
          'maxMultipleSavings': _maxMultipleSavings,
          'penaltyRate': _penaltyRate,
          'maxDurationWeeks': _maxDurationWeeks,
        };
      case SectionKind.socialFund:
        return {
          'contributionAmount': _socialContribution,
          'approvalRule': _approvalRule,
          'usageNotes': _usageNotes,
        };
      case SectionKind.fines:
        return {
          'fineTypes':
              _fineTypes
                  .map((e) => {'name': e.name, 'amount': e.amount})
                  .toList(),
        };
      case SectionKind.generic:
        return {};
    }
  }

  Widget _numberField({
    required String label,
    required double value,
    required void Function(double) onChanged,
  }) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }

  Widget _intField({
    required String label,
    required int value,
    required void Function(int) onChanged,
  }) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
    );
  }

  Widget _savingsSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _savingsFrequency,
          decoration: const InputDecoration(
            labelText: 'Contribution Frequency',
          ),
          items: const [
            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
            DropdownMenuItem(value: 'biweekly', child: Text('Bi-weekly')),
            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
          ],
          onChanged: (v) => setState(() => _savingsFrequency = v ?? 'weekly'),
        ),
        const SizedBox(height: 8),
        _numberField(
          label: 'Minimum Contribution',
          value: _minContribution,
          onChanged: (v) => setState(() => _minContribution = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fixed Amount Savings'),
          value: _fixedAmount,
          onChanged: (v) => setState(() => _fixedAmount = v),
        ),
        if (_fixedAmount)
          _numberField(
            label: 'Fixed Amount Value',
            value: _fixedAmountValue,
            onChanged: (v) => setState(() => _fixedAmountValue = v),
          ),
        _numberField(
          label: 'Penalty Per Miss',
          value: _penaltyPerMiss,
          onChanged: (v) => setState(() => _penaltyPerMiss = v),
        ),
      ],
    );
  }

  Widget _loanSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _interestType,
          decoration: const InputDecoration(labelText: 'Interest Type'),
          items: const [
            DropdownMenuItem(value: 'flat', child: Text('Flat')),
            DropdownMenuItem(
              value: 'reducing',
              child: Text('Reducing Balance'),
            ),
          ],
          onChanged: (v) => setState(() => _interestType = v ?? 'flat'),
        ),
        const SizedBox(height: 8),
        _numberField(
          label: 'Interest Rate (%)',
          value: _interestRate,
          onChanged: (v) => setState(() => _interestRate = v),
        ),
        _numberField(
          label: 'Max Multiple of Savings',
          value: _maxMultipleSavings,
          onChanged: (v) => setState(() => _maxMultipleSavings = v),
        ),
        _numberField(
          label: 'Penalty Rate (%)',
          value: _penaltyRate,
          onChanged: (v) => setState(() => _penaltyRate = v),
        ),
        _intField(
          label: 'Max Duration (weeks)',
          value: _maxDurationWeeks,
          onChanged: (v) => setState(() => _maxDurationWeeks = v),
        ),
      ],
    );
  }

  Widget _socialFundSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _numberField(
          label: 'Contribution Amount',
          value: _socialContribution,
          onChanged: (v) => setState(() => _socialContribution = v),
        ),
        TextFormField(
          initialValue: _approvalRule,
          decoration: const InputDecoration(labelText: 'Approval Rule'),
          onChanged: (v) => _approvalRule = v,
        ),
        TextFormField(
          initialValue: _usageNotes,
          decoration: const InputDecoration(labelText: 'Usage Notes'),
          maxLines: 3,
          onChanged: (v) => _usageNotes = v,
        ),
      ],
    );
  }

  Widget _finesSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._fineTypes.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value.name,
                    decoration: const InputDecoration(labelText: 'Fine Name'),
                    onChanged: (v) => entry.value.name = v,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    initialValue: entry.value.amount.toString(),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged:
                        (v) =>
                            entry.value.amount =
                                double.tryParse(v) ?? entry.value.amount,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed:
                      () => setState(() => _fineTypes.removeAt(entry.key)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed:
                () => setState(
                  () => _fineTypes.add(_FineTypeForm(name: '', amount: 0)),
                ),
            icon: const Icon(Icons.add),
            label: const Text('Add Fine Type'),
          ),
        ),
      ],
    );
  }
}

class _FineTypeForm {
  String name;
  double amount;
  _FineTypeForm({required this.name, required this.amount});
}
