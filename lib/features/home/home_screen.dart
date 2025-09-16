import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrifinity/features/meetings/data/meeting_status_service.dart';
import 'package:agrifinity/features/meetings/presentation/active_meeting_banner.dart';
import 'package:provider/provider.dart';
import 'presentation/home_viewmodel.dart';
import 'package:agrifinity/features/group/viewmodels/group_viewmodel.dart';
import 'package:agrifinity/core/session/user_session.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int? _activeMeetingId;
  late final HomeViewModel _vm;

  String _formatUGX(num? amount) {
    if (amount == null) return '—';
    final f = NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    );
    return f.format(amount);
  }

  @override
  void initState() {
    super.initState();
    _vm = HomeViewModel();
    _vm.load();
    _loadActiveMeeting();
  }

  Future<void> _loadActiveMeeting() async {
    final id = await MeetingStatusService.getActiveMeeting();
    setState(() {
      _activeMeetingId = id;
    });
  }

  static final List<_NavItem> _navItems = [
    _NavItem('Home', Icons.dashboard, '/home'),
    _NavItem('Fines', Icons.money, '/fines'),
    _NavItem('Savings', Icons.savings, '/savings'),
    _NavItem('Loans', Icons.account_balance, '/loans'),
    _NavItem('Reports', Icons.bar_chart, '/reports'),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (_navItems[index].route != '/home') {
      context.go(_navItems[index].route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _vm),
        ChangeNotifierProvider(create: (_) => GroupViewModel()),
      ],
      child: Builder(
        builder: (context) {
          final vm = context.watch<HomeViewModel>();
          final groupVm = context.watch<GroupViewModel>();
          String greeting() {
            final hour = DateTime.now().hour;
            if (hour < 12) return 'Good morning';
            if (hour < 17) return 'Good afternoon';
            return 'Good evening';
          }

          final userName = context.watch<UserSession>().name;
          final groupName = groupVm.group.name;
          final List<(String title, IconData icon, String route)> items = [
            ('Meetings', Icons.groups, '/meetings'),
            ('Members', Icons.people, '/members'),
            ('Notifications', Icons.notifications, '/notifications'),
            ('Social Fund', Icons.favorite, '/social'),
          ];
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
              title: Text(
                'Home',
                style: GoogleFonts.redHatDisplay(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.account_circle,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  tooltip: 'Edit Group Leader Profile',
                  onPressed: () => context.go('/member-profile'),
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        top: 10,
                        bottom: 0,
                      ),
                      child: Text(
                        '${greeting()},',
                        style: GoogleFonts.redHatDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        bottom: 0,
                        top: 2,
                      ),
                      child: Text(
                        userName,
                        style: GoogleFonts.redHatDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 0),
                      child: Text(
                        'Group: $groupName',
                        style: GoogleFonts.redHatDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    if (_activeMeetingId != null) ...[
                      ActiveMeetingBanner(meetingId: _activeMeetingId!),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (vm.error != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Failed to load dashboard. Tap to retry.',
                                          style: GoogleFonts.redHatDisplay(),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: vm.load,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              Text(
                                'Cycle Progress',
                                style: GoogleFonts.redHatDisplay(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        vm.busy
                                            ? const LinearProgressIndicator()
                                            : LinearProgressIndicator(
                                              value: vm.cycleProgressValue,
                                              minHeight: 10,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.15),
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                            ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    vm.summary == null
                                        ? '--/--'
                                        : vm.cycleProgressLabel,
                                    style: GoogleFonts.redHatDisplay(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vm.summary?.cycleName.isNotEmpty == true
                                    ? vm.summary!.cycleName
                                    : "",
                                style: GoogleFonts.redHatDisplay(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Members',
                                          style: GoogleFonts.redHatDisplay(
                                            fontSize: 13,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          vm.summary?.membersTotal.toString() ??
                                              '—',
                                          style: GoogleFonts.redHatDisplay(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Attendance Rate',
                                          style: GoogleFonts.redHatDisplay(
                                            fontSize: 13,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          vm.attendancePercentLabel,
                                          style: GoogleFonts.redHatDisplay(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Loan Outstanding',
                                          style: GoogleFonts.redHatDisplay(
                                            fontSize: 13,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatUGX(
                                            vm.summary?.totalOutstandingLoan,
                                          ),
                                          style: GoogleFonts.redHatDisplay(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Savings',
                                          style: GoogleFonts.redHatDisplay(
                                            fontSize: 13,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatUGX(vm.summary?.totalSavings),
                                          style: GoogleFonts.redHatDisplay(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.1,
                            ),
                        itemCount: items.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (_, i) {
                          final (title, icon, route) = items[i];
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            color: Theme.of(context).colorScheme.surface,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => context.go(route),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 8,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(14),
                                      child: Icon(
                                        icon,
                                        size: 36,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.redHatDisplay(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items:
                  _navItems
                      .map(
                        (e) => BottomNavigationBarItem(
                          icon: Icon(e.icon),
                          label: e.label,
                        ),
                      )
                      .toList(),
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: GoogleFonts.redHatDisplay(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GoogleFonts.redHatDisplay(),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}
