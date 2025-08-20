import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for consistent typography
import '../../members/data/api/members_api_repository.dart';
import '../../../core/context/current_context.dart';
import '../data/member_model.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class EditMemberScreen extends StatefulWidget {
  final Member? member;
  final bool isEditMode;

  const EditMemberScreen({this.member, this.isEditMode = false, super.key});

  @override
  _EditMemberScreenState createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _addressController =
      TextEditingController(); // Added controller for address
  bool _isLoading = false;
  String _fullPhone = '';

  // Remove country dial code (defaults UG: 256) from an existing phone
  String _stripDialCode(String input, {String dialCode = '256'}) {
    var p = input.trim();
    if (p.isEmpty) return p;
    // normalize leading symbols
    if (p.startsWith('+')) p = p.substring(1);
    if (p.startsWith('00')) p = p.substring(2);
    // remove spaces, dashes and parentheses at the start
    p = p.replaceFirst(RegExp(r'^[\s\-()]+'), '');
    if (p.startsWith(dialCode)) {
      p = p.substring(dialCode.length);
      p = p.replaceFirst(RegExp(r'^[\s\-()]+'), '');
    }
    return p;
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.member != null) {
      _nameController.text = widget.member!.name;
      _phoneController.text = _stripDialCode(widget.member!.phone ?? '');
      _addressController.text =
          widget.member!.address ?? ''; // Set initial value for address
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _addressController.dispose(); // Dispose address controller
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ctx = context.read<CurrentContext>();
      final groupId = ctx.group_id;
      if (groupId == null) throw Exception('Group ID not found');

      final api = MembersApiRepository();
      // Ensure we submit a single, correct E.164 number
      String phoneToSend =
          _fullPhone.isNotEmpty
              ? _fullPhone
              : '+256${_stripDialCode(_phoneController.text)}';
      if (widget.isEditMode) {
        await api.updateMember(
          group_id: groupId,
          memberId: widget.member!.id,
          data: {
            'name': _nameController.text,
            'phone': phoneToSend,
            if (_pinController.text.isNotEmpty) 'pin': _pinController.text,
          },
        );
      } else {
        await api.createMember(
          groupId: groupId,
          name: _nameController.text,
          phone: phoneToSend,
          pin: _pinController.text,
          joinedAt: DateTime.now().toIso8601String(),
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${widget.isEditMode ? 'update' : 'create'} member: $e',
          ),
        ),
      );
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
          widget.isEditMode ? 'Edit Member' : 'Create Member',
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
                  initialValue: widget.member?.nationalId,
                ),
                const SizedBox(height: 16),
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
                      widget.isEditMode ? 'Save Changes' : 'Create Member',
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
