import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/services/auth_service.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';

/// Raggio del ritratto grande in cima al profilo.
const double _kRaggioAvatarProfilo = 60;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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

    // Preso qui e non ai punti d'uso: piu sotto `ref` e la reference di
    // Firebase Storage, non il `WidgetRef`, e `ref.read` la significherebbe
    // un'altra cosa.
    final loc = ref.read(localizationNotifierProvider);

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
          ToastUtils.showError(context, '${loc.t('upload_failed')}: $e');
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
          ToastUtils.showError(context, '${loc.t('image_url_failed')}: $e');
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    // 2. Create updated profile
    //
    // `copyWith` e non un `UserProfile(...)` scritto da zero: quest'ultimo
    // esisteva prima e non passava `friends`, `calendarSharedWith`,
    // `programsSharedWith` — tornavano `const []` a ogni salvataggio, quindi
    // ogni volta che si aggiornava il profilo si perdeva la lista amici e le
    // condivisioni. `copyWith` porta avanti quello che non viene toccato qui.
    final updatedProfile = _profile!.copyWith(
      displayName: _nameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      photoUrl: photoUrl,
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
        ToastUtils.showSuccess(context, loc.t('profile_updated'));
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, '${loc.t('profile_save_failed')}: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final t = context.expressive;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      // Si arriva sempre scendendo da Impostazioni, mai dal cassetto: la
      // pillola indietro sostituisce l'hamburger, non lo affianca.
      appBar: AppBar(
        title: Text(loc.t('my_profile')),
        leading: BackPill(label: loc.t('settings_title')),
        leadingWidth: BackPill.leadingWidth,
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
              padding: EdgeInsets.all(t.spacing.md),
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
                              radius: _kRaggioAvatarProfilo,
                              backgroundColor: scheme.surfaceContainer,
                              backgroundImage: imageProvider,
                              onBackgroundImageError: imageProvider != null
                                  ? (exception, stackTrace) {
                                      debugPrint('Image load error: $exception');
                                    }
                                  : null,
                              child: (imageProvider == null)
                                  ? Icon(
                                      Icons.person,
                                      size: _kRaggioAvatarProfilo,
                                      color: scheme.onSurfaceVariant,
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
                              padding: EdgeInsets.all(t.spacing.xs),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: scheme.onPrimary,
                                size: t.sizing.iconMd,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: t.spacing.xl),
                  TextField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      labelText: loc.t('username_label'), // Renamed from "Display Name"
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: t.spacing.md),

                  // Name and Surname
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstNameController,
                          enabled: _isEditing,
                          decoration: InputDecoration(
                            labelText: loc.t('first_name'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: t.spacing.md),
                      Expanded(
                        child: TextField(
                          controller: _lastNameController,
                          enabled: _isEditing,
                          decoration: InputDecoration(
                            labelText: loc.t('last_name'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: t.spacing.md),

                  // Gender and BirthDate
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: loc.t('gender_label'),
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: t.spacing.sm,
                              vertical: t.spacing.xs,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _gender,
                              isDense: true,
                              hint: Text(loc.t('select_date_label')),
                              onChanged: _isEditing
                                  ? (String? newValue) {
                                      setState(() {
                                        _gender = newValue;
                                      });
                                    }
                                  : null,
                              items: [
                                DropdownMenuItem(
                                  value: 'male',
                                  child: Text(loc.t('gender_male')),
                                ),
                                DropdownMenuItem(
                                  value: 'female',
                                  child: Text(loc.t('gender_female')),
                                ),
                                DropdownMenuItem(
                                  value: 'other',
                                  child: Text(loc.t('gender_other')),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: t.spacing.md),
                      Expanded(
                        child: InkWell(
                          onTap: _isEditing ? () => _selectDate(context) : null,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: loc.t('birth_date_label'),
                              border: const OutlineInputBorder(),
                            ),
                            child: Text(
                              _birthDate != null
                                  ? "${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}"
                                  : loc.t('select_date_label'),
                              style: TextStyle(
                                color: _birthDate == null
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: t.spacing.md),
                  ListTile(
                    title: Text(loc.t('email_label')),
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




