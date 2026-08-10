import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/services/auth_service.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();

  // Or better, let's keep profile logic in AuthService for now or pure FirestoreService
  // Given previous pattern, let's use AuthService for fetching and saving profile.

  late TextEditingController _nameController; // Acting as "Username"
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  UserProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  File? _imageFile;

  DateTime? _birthDate;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _auth.getUserProfile();
    if (profile != null) {
      _profile = profile;
      _profile = profile;
      _nameController.text = profile.displayName;
      _firstNameController.text = profile.firstName ?? '';
      _lastNameController.text = profile.lastName ?? '';
      _birthDate = profile.birthDate;
      _gender = profile.gender;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    setState(() => _isLoading = true);

    // Uniqueness check removed as per user request. "Username" is just a Display Name now.

    String? photoUrl = _profile!.photoUrl;

    // 1. Upload Image if new one selected
    if (_imageFile != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_avatars')
          .child('${_profile!.id}_$timestamp.jpg');

      try {
        debugPrint('Starting upload to ${ref.fullPath}');
        await ref.putFile(_imageFile!);
        debugPrint('Upload completed');
      } catch (e) {
        debugPrint('Error in putFile: $e');
        if (mounted) {
          ToastUtils.showError(context, 'Upload failed: $e');
        }
        setState(() => _isLoading = false);
        return;
      }

      try {
        debugPrint('Getting download URL');
        photoUrl = await ref.getDownloadURL();
        debugPrint('Got URL: $photoUrl');
      } catch (e) {
        debugPrint('Error in getDownloadURL: $e');
        if (mounted) {
          ToastUtils.showError(context, 'Failed to get image URL: $e');
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    // 2. Create updated profile
    final updatedProfile = UserProfile(
      id: _profile!.id,
      email: _profile!.email,
      displayName: _nameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      friendCode: _profile!.friendCode, // Preserve existing code
      photoUrl: photoUrl,
      // Height and Weight are now managed in BodyMeasurementsScreen
      // We keep existing values or allow them to be updated via that screen,
      // but here we just pass existing values to avoid nulling them if we want to keep them in profile
      height: _profile!.height,
      weight: _profile!.weight,
      createdAt: _profile!.createdAt,
      gymName: _profile!.gymName,
      gymAddress: _profile!.gymAddress,
      gymLat: _profile!.gymLat,
      gymLng: _profile!.gymLng,
      subscriptionExpiry: _profile!.subscriptionExpiry,
      streakDays: _profile!.streakDays,
      birthDate: _birthDate,
      gender: _gender,
    );

    // 3. Save to Firestore
    try {
      await _auth.updateUserProfile(updatedProfile);

      // Force reload from server to confirm
      await _loadProfile();

      setState(() {
        _isEditing = false;
        _imageFile = null;
        _isLoading = false;
      });

      if (mounted) {
        ToastUtils.showSuccess(context, 'Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Failed to save profile: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Stack(
                      children: [
                        Builder(
                          builder: (context) {
                            final ImageProvider? imageProvider =
                                _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_profile?.photoUrl != null
                                      ? NetworkImage(_profile!.photoUrl!)
                                      : null);
                            return CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: imageProvider,
                              onBackgroundImageError: imageProvider != null
                                  ? (exception, stackTrace) {
                                      debugPrint('Image load error: $exception');
                                    }
                                  : null,
                              child: (imageProvider == null)
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    )
                                  : null,
                            );
                          },
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Username', // Renamed from "Display Name"
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name and Surname
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstNameController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _lastNameController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

                  // Gender and BirthDate
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _gender,
                              isDense: true,
                              hint: const Text('Select'),
                              onChanged: _isEditing
                                  ? (String? newValue) {
                                      setState(() {
                                        _gender = newValue;
                                      });
                                    }
                                  : null,
                              items: const [
                                DropdownMenuItem(
                                  value: 'male',
                                  child: Text('Male'),
                                ),
                                DropdownMenuItem(
                                  value: 'female',
                                  child: Text('Female'),
                                ),
                                DropdownMenuItem(
                                  value: 'other',
                                  child: Text('Other'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _isEditing ? () => _selectDate(context) : null,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Birth Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _birthDate != null
                                  ? "${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}"
                                  : 'Select Date',
                              style: TextStyle(
                                color: _birthDate == null ? Colors.grey : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Email'),
                    subtitle: Text(_profile?.email ?? ''),
                    leading: const Icon(Icons.email),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
    );
  }
}
