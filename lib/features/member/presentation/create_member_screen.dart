import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/context/current_context.dart';
import '../../members/data/api/members_api_repository.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:image_picker/image_picker.dart';

class CreateMemberScreen extends StatefulWidget {
  @override
  State<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends State<CreateMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _regionController = TextEditingController();
  final _districtController = TextEditingController();
  String? _gender; // male | female | other
  String? _maritalStatus; // single | married | divorced | widowed
  bool _hasDisability = false;
  String?
  _idType; // national_id | refugee_id | passport | driving_licence | other
  String? _photoPath; // local file path
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
    _idNumberController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _districtController.dispose();
    // _pinController.dispose(); // Dispose PIN controller
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked != null) {
      setState(() => _photoPath = picked.path);
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
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
        address:
            _addressController.text.isNotEmpty ? _addressController.text : null,
        region:
            _regionController.text.isNotEmpty ? _regionController.text : null,
        district:
            _districtController.text.isNotEmpty
                ? _districtController.text
                : null,
        nationalId: _idType == 'national_id' ? _idNumberController.text : null,
        gender: _gender,
        maritalStatus: _maritalStatus,
        hasDisability: _hasDisability,
        idType: _idType,
        idNumber:
            _idNumberController.text.isNotEmpty
                ? _idNumberController.text
                : null,
        photoPath: _photoPath,
        // pin: _pinController.text,
        pin: '123456',
        joinedAt: DateTime.now().toIso8601String(),
      );

      // Success message then close
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member added successfully')),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, true);
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
                // Profile picture
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Builder(
                        builder: (context) {
                          ImageProvider? provider;
                          if (_photoPath != null && _photoPath!.isNotEmpty) {
                            provider =
                                _photoPath!.startsWith('http')
                                    ? NetworkImage(_photoPath!)
                                    : FileImage(File(_photoPath!));
                          }
                          return CircleAvatar(
                            radius: 44,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            foregroundImage: provider,
                            child:
                                provider == null
                                    ? Icon(
                                      Icons.person,
                                      size: 44,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    )
                                    : null,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        color: theme.colorScheme.primary,
                        onPressed: _showImageSourcePicker,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _maritalStatus,
                  decoration: InputDecoration(
                    labelText: 'Marital Status',
                    labelStyle: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'single', child: Text('Single')),
                    DropdownMenuItem(value: 'married', child: Text('Married')),
                    DropdownMenuItem(
                      value: 'divorced',
                      child: Text('Divorced'),
                    ),
                    DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                  ],
                  onChanged: (v) => setState(() => _maritalStatus = v),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(
                    'Has disability',
                    style: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _hasDisability,
                  onChanged: (v) => setState(() => _hasDisability = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _idType,
                  decoration: InputDecoration(
                    labelText: 'ID Type',
                    labelStyle: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'national_id',
                      child: Text('National ID'),
                    ),
                    DropdownMenuItem(
                      value: 'refugee_id',
                      child: Text('Refugee ID'),
                    ),
                    DropdownMenuItem(
                      value: 'passport',
                      child: Text('Passport'),
                    ),
                    DropdownMenuItem(
                      value: 'driving_licence',
                      child: Text('Driving licence'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Other (e.g., LC 1 ID)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _idType = v),
                  validator:
                      (v) => v == null || v.isEmpty ? 'Select ID type' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idNumberController,
                  decoration: InputDecoration(
                    labelText: 'ID Number',
                    labelStyle: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: 'Enter the selected ID number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (v) {
                    if (_idType != null && (_idType!.isNotEmpty)) {
                      if (v == null || v.isEmpty) return 'Enter ID number';
                    }
                    return null;
                  },
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _regionController,
                  decoration: InputDecoration(
                    labelText: 'Region',
                    labelStyle: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: 'Enter region',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _districtController,
                  decoration: InputDecoration(
                    labelText: 'District',
                    labelStyle: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: 'Enter district',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: 'Enter address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  maxLines: 2,
                ),
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
