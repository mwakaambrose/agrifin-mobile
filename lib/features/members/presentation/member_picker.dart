import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../members/data/members_repository.dart';
import '../../../core/context/current_context.dart';

class MemberPicker extends StatefulWidget {
  final void Function(int id, String name) onSelected;
  final int? initialId;
  const MemberPicker({super.key, required this.onSelected, this.initialId});

  @override
  State<MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends State<MemberPicker> {
  late final MembersRepository _repo;
  bool _loading = true;
  String? _error;
  List<MemberLite> _members = [];
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _repo = MembersRepository();
    _selectedId = widget.initialId;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ctx = context.read<CurrentContext>();
      final groupId = ctx.group_id ?? 1;
      final data = await _repo.listByCycle(groupId);
      setState(() => _members = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: 'Select Member',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedId,
      items:
          _members
              .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
              .toList(),
      onChanged: (val) {
        setState(() => _selectedId = val);
        final m = _members.firstWhere((e) => e.id == val);
        widget.onSelected(m.id, m.name);
      },
    );
  }
}
