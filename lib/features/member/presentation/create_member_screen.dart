import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/context/current_context.dart';
import '../../members/data/api/members_api_repository.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class CreateMemberScreen extends StatefulWidget {
  @override
  State<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends State<CreateMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  // final _pinController = TextEditingController(); // Added PIN controller
  bool _isLoading = false;
  final MembersApiRepository _apiRepository = MembersApiRepository();
  String _fullPhone = '';

  String _stripDialCode(String input, {String dialCode = '256'}) {
    var p = input.trim();
    if (p.isEmpty) return p;
    if (p.startsWith('+')) p = p.substring(1);
    if (p.startsWith('00')) p = p.substring(2);
    p = p.replaceFirst(RegExp(r'^[\s\-()]+'), '');
    if (p.startsWith(dialCode)) {
      p = p.substring(dialCode.length);
      p = p.replaceFirst(RegExp(r'^[\s\-()]+'), '');
    }
    return p;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    // _pinController.dispose(); // Dispose PIN controller
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ctx = context.read<CurrentContext>();
      final groupId = ctx.group_id;
      if (groupId == null) throw Exception('Group ID not found');

      // Ensure single country code (E.164). If user didn't change, build from local part.
      final phoneToSend =
          _fullPhone.isNotEmpty
              ? _fullPhone
              : '+256${_stripDialCode(_phoneController.text)}';
      await _apiRepository.createMember(
        groupId: groupId,
        name: _nameController.text,
        phone: phoneToSend,
        nationalId: _nationalIdController.text,
        // pin: _pinController.text,
        pin: '123456',
        joinedAt: DateTime.now().toIso8601String(),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add member: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Member',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: 'Enter member name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Name is required'
                              : null,
                ),
                const SizedBox(height: 16),
                IntlPhoneField(
                  controller: _phoneController,
                  initialCountryCode: 'UG',
                  disableLengthCheck: true,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    labelStyle: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: 'Enter phone number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (phone) {
                    setState(() => _fullPhone = phone.completeNumber);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nationalIdController,
                  decoration: InputDecoration(
                    labelText: 'National ID',
                    labelStyle: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: 'Enter national ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                // const SizedBox(height: 16),
                // TextFormField(
                //   controller: _pinController,
                //   decoration: InputDecoration(
                //     labelText: 'PIN',
                //     labelStyle: GoogleFonts.redHatDisplay(
                //       fontWeight: FontWeight.w600,
                //     ),
                //     hintText: 'Enter PIN',
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(8.0),
                //     ),
                //   ),
                //   keyboardType: TextInputType.number,
                //   obscureText: true,
                //   validator:
                //       (value) =>
                //           value == null || value.isEmpty
                //               ? 'PIN is required'
                //               : null,
                // ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Add Member',
                      style: GoogleFonts.redHatDisplay(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
