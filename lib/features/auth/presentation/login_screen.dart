import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/auth_repository.dart';
import 'auth_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../core/session/user_session.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(AuthRepository()),
      child: const _LoginForm(),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  String _fullPhone = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await vm.login(_fullPhone, _pinController.text);
    if (!mounted) return;
    if (ok) {
      final user = vm.user; // Assuming vm.user contains the logged-in user data
      final session = Provider.of<UserSession>(context, listen: false);
      session.setUser(user);
      context.go('/home');
    } else if (vm.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.error!)));
    }
  }

  void _showForgotPin(AuthViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final phoneController = TextEditingController(
          text: _fullPhone,
        ); // may be blank
        final codeController = TextEditingController();
        final newPinController = TextEditingController();
        final confirmPinController = TextEditingController();
        final formKey = GlobalKey<FormState>();
        bool submitting = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> submitRequest() async {
              if (phoneController.text.trim().isEmpty) return;
              setSheetState(() => submitting = true);
              final ok = await vm.requestPinReset(phoneController.text.trim());
              setSheetState(() => submitting = false);
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset code sent')),
                );
              }
            }

            Future<void> submitConfirm() async {
              if (!formKey.currentState!.validate()) return;
              setSheetState(() => submitting = true);
              final ok = await vm.confirmPinReset(
                phoneController.text.trim(),
                codeController.text.trim(),
                newPinController.text,
              );
              setSheetState(() => submitting = false);
              if (ok) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN updated. Please login.')),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      vm.pinResetRequested ? 'Reset PIN' : 'Forgot PIN',
                      style: GoogleFonts.redHatDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vm.pinResetRequested
                          ? 'Enter the verification code sent to your phone and choose a new 6-digit PIN.'
                          : 'Enter your phone number to receive a verification code to reset your PIN.',
                      style: GoogleFonts.redHatDisplay(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: phoneController,
                      readOnly: vm.pinResetRequested,
                      decoration: const InputDecoration(
                        labelText: 'Phone (with country code)',
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                    ),
                    if (vm.pinResetRequested) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Verification Code',
                        ),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPinController,
                        decoration: const InputDecoration(labelText: 'New PIN'),
                        maxLength: 6,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        validator:
                            (v) =>
                                (v == null || v.length != 6)
                                    ? '6 digits'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPinController,
                        decoration: const InputDecoration(
                          labelText: 'Confirm PIN',
                        ),
                        maxLength: 6,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        validator:
                            (v) =>
                                (v != newPinController.text)
                                    ? 'PINs do not match'
                                    : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(
                          onPressed:
                              submitting
                                  ? null
                                  : () {
                                    Navigator.pop(ctx);
                                  },
                          child: const Text('Close'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed:
                              submitting
                                  ? null
                                  : () {
                                    if (!vm.pinResetRequested) {
                                      submitRequest();
                                    } else {
                                      if (formKey.currentState!.validate()) {
                                        submitConfirm();
                                      }
                                    }
                                  },
                          icon:
                              submitting
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Icon(
                                    vm.pinResetRequested
                                        ? Icons.check
                                        : Icons.send,
                                  ),
                          label: Text(
                            vm.pinResetRequested ? 'Reset PIN' : 'Send Code',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    // Ensure we persist the user in Hive once login succeeds
    vm.setOnUserLoggedIn((user) {
      // user is UserDto
      // ignore: use_build_context_synchronously
      final session = Provider.of<UserSession>(context, listen: false);
      session.setUser(user);
    });
    return Stack(
      children: [
        // Full-screen gradient background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.85),
                  Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Icon(Icons.savings, color: Colors.white, size: 72),
                      // const SizedBox(width: 8),
                      // Text(
                      //   'Agrifin Savings Groups',
                      //   style: GoogleFonts.redHatDisplay(
                      //     color: Colors.white,
                      //     fontWeight: FontWeight.bold,
                      //     fontSize: 26,
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome Back',
                    style: GoogleFonts.redHatDisplay(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login to continue to your group dashboard',
                    style: GoogleFonts.redHatDisplay(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            IntlPhoneField(
                              decoration: InputDecoration(
                                labelText: 'Phone',
                                labelStyle: GoogleFonts.redHatDisplay(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              initialCountryCode: 'UG',
                              disableLengthCheck: true,
                              keyboardType: TextInputType.phone,
                              onChanged: (p) => _fullPhone = p.completeNumber,
                              validator: (p) {
                                if (_fullPhone.isEmpty) return 'Enter phone';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _pinController,
                              obscureText: true,
                              maxLength: 6,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'PIN',
                                counterText: '',
                                labelStyle: GoogleFonts.redHatDisplay(),
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator:
                                  (v) =>
                                      (v == null || v.length != 6)
                                          ? '6-digit PIN'
                                          : null,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showForgotPin(vm),
                                child: Text(
                                  'Forgot PIN?',
                                  style: GoogleFonts.redHatDisplay(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: vm.busy ? null : () => _submit(vm),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child:
                                    vm.busy
                                        ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : Text(
                                          'Login',
                                          style: GoogleFonts.redHatDisplay(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'By continuing you agree to the group policies.',
                      style: GoogleFonts.redHatDisplay(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
