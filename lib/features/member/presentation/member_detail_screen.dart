import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../members/data/api/members_api_repository.dart';
import '../../../core/context/current_context.dart';
import '../data/member_model.dart';
import 'edit_member_screen.dart'; // Corrected import path for MemberFormScreen

class MemberDetailScreen extends StatefulWidget {
  final Member member;

  const MemberDetailScreen({required this.member, Key? key}) : super(key: key);

  @override
  _MemberDetailScreenState createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final MembersApiRepository _apiRepository = MembersApiRepository();
  Map<String, dynamic>? _memberDetails;
  bool _isLoading = true;
  String? _error;
  int? _groupId;

  @override
  void initState() {
    super.initState();
    // Delay to ensure providers are available in context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctx = context.read<CurrentContext>();
      var gid = ctx.group_id;
      // If group id isn't ready yet, try refreshing it once.
      if (gid == null) {
        await ctx.refresh();
        gid = ctx.group_id;
      }
      setState(() => _groupId = gid);
      if (gid != null) {
        await _fetchMemberDetails(gid);
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Group not selected. Please try again later.';
        });
      }
    });
  }

  Future<void> _fetchMemberDetails(int groupId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await _apiRepository.getMemberDetails(
        group_id: groupId,
        memberId: widget.member.id,
      );
      setState(() {
        _memberDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load member details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          'Member Details',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditMemberScreen(
                        member: widget.member,
                        isEditMode: true,
                      ),
                ),
              );
              if (result == true) {
                await _fetchMemberDetails(_groupId!);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.block),
            onPressed: () async {
              try {
                final api = MembersApiRepository();
                await api.disableMember(
                  group_id: _groupId!,
                  memberId: widget.member.id,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Member disabled successfully')),
                );
                await _fetchMemberDetails(_groupId!);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to disable member: $e')),
                );
              }
            },
          ),
          if (!widget.member.active)
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () async {
                try {
                  final api = MembersApiRepository();
                  await api.activateMember(
                    group_id: _groupId!,
                    memberId: widget.member.id,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Member activated successfully'),
                    ),
                  );
                  await _fetchMemberDetails(_groupId!);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to activate member: $e')),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Delete Member'),
                      content: const Text(
                        'Are you sure you want to delete this member?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
              );

              if (confirm == true) {
                try {
                  final api = MembersApiRepository();
                  await api.deleteMember(
                    group_id: _groupId!,
                    memberId: widget.member.id,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Member deleted successfully'),
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete member: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.redHatDisplay(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  _groupId == null
                      ? null
                      : () => _fetchMemberDetails(_groupId!),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_groupId != null) {
          await _fetchMemberDetails(_groupId!);
        }
      },
      child: _buildDetailsView(),
    );
  }

  Widget _buildDetailsView() {
    final details = _memberDetails ?? const {};
    final member = (details['member'] as Map?) ?? const {};
    final aggregates = (details['aggregates'] as Map?) ?? const {};
    final loans = (aggregates['loans'] as Map?) ?? const {};
    final welfare = (aggregates['welfare'] as Map?) ?? const {};
    final fines = (aggregates['fines'] as Map?) ?? const {};

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header/profile card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  Theme.of(context).colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.12),
                      backgroundImage:
                          widget.member.photoPath != null
                              ? AssetImage(widget.member.photoPath!)
                              : null,
                      child:
                          widget.member.photoPath == null
                              ? Icon(
                                Icons.person,
                                size: 36,
                                color: Theme.of(context).colorScheme.primary,
                              )
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.member.name,
                                  style: GoogleFonts.redHatDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(
                                active: (member['is_active'] as bool?) ?? false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (widget.member.phone != null)
                            Text(
                              widget.member.phone!,
                              style: GoogleFonts.redHatDisplay(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Member ID: ${member['id'] ?? widget.member.id}  •  Group: ${member['group_id'] ?? (_groupId ?? '-')}',
                            style: GoogleFonts.redHatDisplay(
                              fontSize: 12,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: GoogleFonts.redHatDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _MetricsGrid(
                  cards: [
                    _MetricCardData(
                      title: 'Savings Total',
                      value: _money(aggregates['savings_total']),
                      icon: Icons.savings,
                      color: Colors.teal,
                    ),
                    _MetricCardData(
                      title: 'Loans Count',
                      value: '${loans['count'] ?? 0}',
                      icon: Icons.receipt_long,
                      color: Colors.indigo,
                    ),
                    _MetricCardData(
                      title: 'Active Loans',
                      value: '${loans['active'] ?? 0}',
                      icon: Icons.play_circle_fill,
                      color: Colors.orange,
                    ),
                    _MetricCardData(
                      title: 'Completed Loans',
                      value: '${loans['completed'] ?? 0}',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  'Loans Details',
                  style: GoogleFonts.redHatDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _MetricsGrid(
                  cards: [
                    _MetricCardData(
                      title: 'Total Principal',
                      value: _money(loans['total_principal']),
                      icon: Icons.account_balance,
                      color: Colors.blueGrey,
                    ),
                    _MetricCardData(
                      title: 'Interest Paid',
                      value: _money(loans['total_interest_paid']),
                      icon: Icons.trending_up,
                      color: Colors.purple,
                    ),
                    _MetricCardData(
                      title: 'Outstanding',
                      value: _money(loans['outstanding_balance']),
                      icon: Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  'Welfare',
                  style: GoogleFonts.redHatDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _MetricsGrid(
                  cards: [
                    _MetricCardData(
                      title: 'Contributed',
                      value: _money(welfare['contributed']),
                      icon: Icons.volunteer_activism,
                      color: Colors.cyan,
                    ),
                    _MetricCardData(
                      title: 'Received',
                      value: _money(welfare['received']),
                      icon: Icons.card_giftcard,
                      color: Colors.amber,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  'Fines',
                  style: GoogleFonts.redHatDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _MetricsGrid(
                  cards: [
                    _MetricCardData(
                      title: 'Paid',
                      value: _money(fines['paid']),
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    _MetricCardData(
                      title: 'Unpaid',
                      value: _money(fines['unpaid']),
                      icon: Icons.cancel_outlined,
                      color: Colors.deepOrange,
                    ),
                    _MetricCardData(
                      title: 'Count',
                      value: '${fines['count'] ?? 0}',
                      icon: Icons.numbers,
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _money(dynamic value) {
    final numVal =
        (value is num) ? value : num.tryParse(value?.toString() ?? '0') ?? 0;
    // Simple formatting to UGX with no decimals if whole number
    String formatted = numVal.toStringAsFixed(0);
    // Add thousands separators
    final regex = RegExp(r"\B(?=(\d{3})+(?!\d))");
    formatted = formatted.replaceAllMapped(regex, (m) => ',');
    return 'UGX $formatted';
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.grey;
    final label = active ? 'Active' : 'Inactive';
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.pause_circle_filled,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.redHatDisplay(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  _MetricCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricsGrid extends StatelessWidget {
  final List<_MetricCardData> cards;
  const _MetricsGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // calculate aspect ratio dynamically based on width
        final width = constraints.maxWidth;
        final itemWidth = (width - 8) / 2; // 2 columns with spacing
        const itemHeight = 120; // adjust to your card height
        final aspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: aspectRatio,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final c = cards[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: c.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(c.icon, color: c.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.redHatDisplay(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.value,
                            style: GoogleFonts.redHatDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
