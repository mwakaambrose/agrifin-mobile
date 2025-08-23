import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../members/data/api/members_api_repository.dart';
import '../data/member_model.dart';
import 'member_detail_screen.dart';
import 'create_member_screen.dart'; // Import the new CreateMemberScreen

class MemberListScreen extends StatefulWidget {
  @override
  _MemberListScreenState createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final MembersApiRepository _apiRepository = MembersApiRepository();
  List<Member> _members = [];
  bool _isLoading = true;
  String? _error;
  // int? _group_id; // managed via Hive box in this screen

  @override
  void initState() {
    super.initState();
    _initializegroup_idAndFetchMembers();
  }

  Future<void> _initializegroup_idAndFetchMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _fetchMembers();
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize group ID: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final box = await Hive.openBox('user_data');
    final group_id = box.get('group_id');
    try {
      final membersData = await _apiRepository.listCycleMembers(group_id);
      setState(() {
        _members = membersData.map((data) => Member.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load members: $e';
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
          'Members',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed: _fetchMembers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      style: GoogleFonts.redHatDisplay(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _initializegroup_idAndFetchMembers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchMembers,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  itemCount: _members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final member = _members[i];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.15),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: GoogleFonts.redHatDisplay(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text('Phone: ${member.phone ?? '-'}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      MemberDetailScreen(member: member),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateMemberScreen()),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class MemberEditScreen extends StatefulWidget {
  final Member? member;
  MemberEditScreen({this.member});

  @override
  State<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends State<MemberEditScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _joinedAtController = TextEditingController();
  String? _photoPath;
  final MembersApiRepository _apiRepository = MembersApiRepository();

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    if (member != null) {
      _nameController.text = member.name;
      _phoneController.text = member.phone ?? '';
      _addressController.text = member.address ?? '';
      _nationalIdController.text = member.nationalId ?? '';
      _joinedAtController.text = member.joinedOn.toIso8601String();
      _photoPath = member.photoPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    _joinedAtController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    // TODO: Integrate with image_picker or camera package
    setState(() {
      _photoPath = 'mock_photo_path.jpg';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Text(
          widget.member == null ? 'Add Member' : 'Edit Member',
          style: GoogleFonts.redHatDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
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
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _takePhoto,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.15),
                      backgroundImage:
                          _photoPath != null
                              ? FileImage(File(_photoPath!))
                              : null,
                      child:
                          _photoPath == null
                              ? Icon(
                                Icons.camera_alt,
                                size: 36,
                                color: Theme.of(context).colorScheme.primary,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nationalIdController,
                    decoration: InputDecoration(
                      labelText: 'National ID Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _joinedAtController,
                    decoration: InputDecoration(
                      labelText: 'Joined At (YYYY-MM-DD)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.redHatDisplay(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        try {
                          final box = await Hive.openBox('user_data');
                          dynamic groupId = box.get('group_id');

                          await _apiRepository.createMember(
                            groupId: groupId,
                            name: _nameController.text,
                            phone: _phoneController.text,
                            nationalId: _nationalIdController.text,
                            pin: '123456',
                            joinedAt: _joinedAtController.text,
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add member: $e')),
                          );
                        }
                      },
                      child: Text(
                        widget.member == null ? 'Add Member' : 'Save Changes',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Removed legacy local MemberDetailScreen class. Using the dedicated screen from member_detail_screen.dart
