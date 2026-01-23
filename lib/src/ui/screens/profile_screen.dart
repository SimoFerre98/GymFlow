import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final FirestoreService _firestore =
      FirestoreService(); // We'll need to add updateUser to FirestoreService, or use AuthService

  // Or better, let's keep profile logic in AuthService for now or pure FirestoreService
  // Given previous pattern, let's use AuthService for fetching and saving profile.

  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  UserProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _auth.getUserProfile();
    if (profile != null) {
      _profile = profile;
      _nameController.text = profile.displayName;
      _heightController.text = profile.height?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        // Turn on editing mode if not already? Or just allow upload without full edit
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    setState(() => _isLoading = true);

    String? photoUrl = _profile!.photoUrl;

    // 1. Upload Image if new one selected
    if (_imageFile != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_avatars')
            .child('${_profile!.id}.jpg');

        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
        }
      }
    }

    // 2. Create updated profile
    final updatedProfile = UserProfile(
      id: _profile!.id,
      email: _profile!.email,
      displayName: _nameController.text.trim(),
      photoUrl: photoUrl,
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      createdAt: _profile!.createdAt,
    );

    // 3. Save to Firestore (We need to expose a method for this)
    // For now I'll call a new method in AuthService
    await _auth.updateUserProfile(updatedProfile);

    setState(() {
      _profile = updatedProfile;
      _isEditing = false;
      _imageFile = null; // Reset local file as it is now uploaded
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context); // Go back to Settings
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_profile?.photoUrl != null
                                    ? NetworkImage(_profile!.photoUrl!)
                                          as ImageProvider
                                    : null),
                          child:
                              (_imageFile == null && _profile?.photoUrl == null)
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
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
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _heightController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _weightController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(),
                    ),
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
