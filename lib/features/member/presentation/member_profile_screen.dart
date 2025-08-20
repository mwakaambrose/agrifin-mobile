import 'package:agrifinity/core/session/user_session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/services.dart';
import 'package:agrifinity/features/auth/data/auth_repository.dart';
import '../viewmodel/member_profile_viewmodel.dart';
import '../data/member_repository.dart';

class MemberProfileScreen extends StatefulWidget {
  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  final _viewModel = MemberProfileViewModel(repository: MemberRepository());
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _currentPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String _fullPhone = '';

  String? _userName;
  String? _groupName;
  int? _groupId;

  @override
  void initState() {
    super.initState();
    _loadProfileFromHive();
  }

  String _stripDialCode(String input, {String dialCode = '256'}) {
    final normalized = input.replaceAll(RegExp(r'[^0-9+]'), '');
    final digitsOnly = normalized.replaceAll('+', '');
    if (digitsOnly.startsWith(dialCode)) {
      return digitsOnly.substring(dialCode.length);
    }
    if (digitsOnly.startsWith('0')) {
      return digitsOnly.replaceFirst(RegExp('^0+'), '');
    }
    return digitsOnly;
  }

  Future<void> _loadProfileFromHive() async {
    try {
      final box = await Hive.openBox('user_data');
      // user_name kept for backward compat if needed
      final _ = box.get('user_name') ?? box.get('username') ?? box.get('name');
      final group = box.get('group'); // could be Map
      final groupName =
          box.get('group_name') ?? (group is Map ? group['name'] : null);
      final groupId = box.get('group_id');

      final session = Provider.of<UserSession>(context, listen: false);
      final user = session.user;
      final currentPhone = user?.phone;

      if (mounted) {
        setState(() {
          _userName = user?.name;
          _groupName = groupName;
          _groupId = groupId;

          if (currentPhone is String && currentPhone.isNotEmpty) {
            final localPart = _stripDialCode(currentPhone, dialCode: '256');
            _phoneController.text = localPart;
            _fullPhone =
                currentPhone.startsWith('+') ? currentPhone : '+256$localPart';
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _currentPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<(String title, IconData icon, String route)> profileMenus = [
      // ('Accounts', Icons.account_balance_wallet, '/accounts'),
      ('Cycles', Icons.repeat, '/cycles'),
      ('Constitution', Icons.rule, '/constitution'),
      // ('Reports', Icons.bar_chart, '/reports'),
      // ('Group Profile', Icons.info, '/group'),
      ('Transactions', Icons.swap_horiz, '/transactions'),
    ];

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
          'More Settings',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
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
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userName ?? '—',
                            style: GoogleFonts.redHatDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _groupName ??
                                (_groupId != null ? 'Group #$_groupId' : '—'),
                            style: GoogleFonts.redHatDisplay(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Group Leader',
                            style: GoogleFonts.redHatDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),

                          // const SizedBox(height: 24),
                          // Text(
                          //   'Financial history, roles, statements, savings & contributions',
                          //   textAlign: TextAlign.center,
                          //   style: GoogleFonts.redHatDisplay(
                          //     fontSize: 16,
                          //     color: Theme.of(context).colorScheme.onSurface,
                          //   ),
                          // ),
                          // const SizedBox(height: 16),
                          // Divider(),
                          // const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Profile Menus Grid
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: profileMenus.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (_, i) {
                    final (title, icon, route) = profileMenus[i];
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
                                  color: Theme.of(context).colorScheme.primary,
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
                                      Theme.of(context).colorScheme.onSurface,
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Change Login Phone Number',
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        IntlPhoneField(
                          controller: _phoneController,
                          initialCountryCode: 'UG',
                          disableLengthCheck: true,
                          decoration: InputDecoration(
                            labelText: 'New Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (phone) {
                            setState(() {
                              _fullPhone = phone.completeNumber;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // boxy
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: GoogleFonts.redHatDisplay(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final phoneToSend =
                                  _fullPhone.isNotEmpty
                                      ? _fullPhone
                                      : _phoneController.text;
                              final success = await _viewModel
                                  .changePhoneNumber(phoneToSend);
                              if (success) {
                                await AuthRepository().logout();
                                // ignore: use_build_context_synchronously
                                await context.read<UserSession>().clear();
                                if (!mounted) return;
                                context.go('/login');
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to update phone number.',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text('Update Phone Number'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Divider(),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Reset/Change PIN',
                            style: GoogleFonts.redHatDisplay(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _currentPinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Current PIN',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: InputDecoration(
                            labelText: 'New PIN',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _confirmPinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Confirm New PIN',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // boxy
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: GoogleFonts.redHatDisplay(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              if (_pinController.text !=
                                  _confirmPinController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('PINs do not match.')),
                                );
                                return;
                              }
                              final success = await _viewModel.changePin(
                                currentPin: _currentPinController.text,
                                newPin: _pinController.text,
                              );
                              if (success) {
                                await AuthRepository().logout();
                                // ignore: use_build_context_synchronously
                                await context.read<UserSession>().clear();
                                if (!mounted) return;
                                context.go('/login');
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update PIN.'),
                                  ),
                                );
                              }
                            },
                            child: Text('Update PIN'),
                          ),
                        ),
                        SizedBox(height: 32),
                        // Logout button moved into scrollable content
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: const Text('Logout'),
                                      content: const Text(
                                        'Are you sure you want to logout?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('Logout'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm != true) return;
                              await AuthRepository().logout();
                              // Clear cached user details
                              // ignore: use_build_context_synchronously
                              await context.read<UserSession>().clear();
                              if (!mounted) return;
                              context.go('/login');
                            },
                            icon: const Icon(Icons.logout),
                            label: Text(
                              'Logout',
                              style: GoogleFonts.redHatDisplay(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error.withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
