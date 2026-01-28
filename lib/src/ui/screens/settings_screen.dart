import 'package:flutter/material.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/profile_screen.dart';
import 'package:gymflow/src/ui/screens/body_measurements_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gymflow/src/core/providers/theme_provider.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';
import 'package:gymflow/src/services/health_service.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart'; // Added

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Mock settings state for now
  bool _notificationsEnabled = true;

  final TextEditingController _gymNameController = TextEditingController();
  final TextEditingController _gymAddressController = TextEditingController();
  double? _gymLat;
  double? _gymLng;
  DateTime? _subscriptionExpiry;
  bool _isLoading =
      true; // Use this to check if initial load is done for pristine check.

  @override
  void dispose() {
    _gymNameController.dispose();
    _gymAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get Providers
    final loc = Provider.of<LocalizationProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    // 2. Define Color presets
    final List<Color> colorPresets = [
      const Color(0xFFD500F9), // Neon Purple (Default)
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.redAccent,
      Colors.teal,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('settings_title')),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<UserProfile?>(
        stream: AuthService().getUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;

          if (profile != null && _gymNameController.text.isEmpty) {
            _gymNameController.text = profile.gymName ?? '';
            _gymAddressController.text = profile.gymAddress ?? '';
            _gymLat = profile.gymLat;
            _gymLng = profile.gymLng;
            _subscriptionExpiry = profile.subscriptionExpiry;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. Account Section
              _buildSectionHeader(loc.t('account_section')),
              _buildSettingsCard(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    title: loc.t('my_profile'),
                    subtitle: profile?.displayName ?? loc.t('guest_user'),
                    icon: Icons.person_outline,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),

                  _buildSettingsTile(
                    context,
                    title: loc.t('body_measurements'),
                    subtitle: loc.t('track_progress'),
                    icon: Icons.monitor_weight_outlined,
                    color: Colors.tealAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BodyMeasurementsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildSettingsTile(
                    context,
                    title: loc.t('subscription'),
                    subtitle: _subscriptionExpiry == null
                        ? loc.t('free_plan')
                        : '${loc.t('expires')}: ${_subscriptionExpiry!.toString().split(' ')[0]}',
                    icon: Icons.star_outline,
                    color: Colors.amber,
                    trailing: _subscriptionExpiry != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _subscriptionExpiry!.isAfter(DateTime.now())
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _subscriptionExpiry!.isAfter(DateTime.now())
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Text(
                              _subscriptionExpiry!.isAfter(DateTime.now())
                                  ? 'ACTIVE'
                                  : 'EXPIRED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    _subscriptionExpiry!.isAfter(DateTime.now())
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          )
                        : null,
                    onTap: () async {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _subscriptionExpiry ??
                            today.add(const Duration(days: 30)),
                        firstDate: today, // Allows selecting today
                        lastDate: today.add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setState(() => _subscriptionExpiry = picked);
                        _saveGymInfo();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Gym Section
              _buildSectionHeader(loc.t('gym_settings_section')),
              _buildSettingsCard(
                context,
                children: [
                  ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.purpleAccent,
                      ),
                    ),
                    title: Text(
                      loc.t('gym_details'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _gymNameController.text.isNotEmpty
                          ? _gymNameController.text
                          : loc.t('set_name_address'),
                    ),
                    childrenPadding: const EdgeInsets.all(16),
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: const Border(),
                    children: [
                      TextField(
                        controller: _gymNameController,
                        decoration: const InputDecoration(
                          labelText: 'Gym Name',
                          prefixIcon: Icon(Icons.business),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _gymAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.place),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveGymInfo,
                          child: const Text('Update Info'),
                        ),
                      ),
                    ],
                  ),

                  _buildSettingsTile(
                    context,
                    title: loc.t('gym_location'),
                    subtitle: _gymLat != null
                        ? loc.t('location_pinned')
                        : loc.t('tap_to_set'),
                    icon: Icons.map_outlined,
                    color: Colors.green,
                    onTap: _showMapPicker,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Integrations
              _buildSectionHeader(loc.t('integrations_section')),
              _buildSettingsCard(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    title: 'Google Fit / Health Connect',
                    subtitle: loc.t('sync_steps'),
                    icon: Icons.health_and_safety,
                    color: Colors.redAccent,
                    onTap: () async {
                      bool success = await HealthService().requestPermissions();
                      if (context.mounted) {
                        if (success) {
                          ToastUtils.showSuccess(
                            context,
                            loc.t('permissions_granted'),
                          );
                        } else {
                          // Allow user to check permissions
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Preferences Section
              _buildSectionHeader(loc.t('preferences_section')),
              _buildSettingsCard(
                context,
                children: [
                  // Language Selection
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language, color: Colors.indigo),
                    ),
                    title: Text(
                      loc.t('language'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: DropdownButton<String>(
                      value: loc.locale.languageCode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'it',
                          child: Text('🇮🇹 Italiano'),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('🇬🇧 English'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          loc.setLocale(Locale(val));
                        }
                      },
                    ),
                  ),

                  // Color Picker
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.color_lens, color: theme.primaryColor),
                    ),
                    title: Text(
                      loc.t('primary_color'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: colorPresets.map((color) {
                          final isSelected =
                              theme.primaryColor.value == color.value;
                          return GestureDetector(
                            onTap: () => theme.setPrimaryColor(color),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12, top: 4),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge!.color!,
                                        width: 2,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    title: Text(
                      loc.t('notifications'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _notificationsEnabled,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),

                  // Theme Selector
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.palette_outlined,
                        color: Colors.teal,
                      ),
                    ),
                    title: Text(
                      loc.t('app_theme'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      theme.themeMode == ThemeMode.system
                          ? loc.t('system')
                          : (theme.themeMode == ThemeMode.dark
                                ? loc.t('dark')
                                : loc.t('light')),
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: theme.themeMode,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      onChanged: (ThemeMode? newValue) {
                        if (newValue != null) {
                          theme.setThemeMode(newValue);
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(loc.t('system')),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(loc.t('light')),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(loc.t('dark')),
                        ),
                      ],
                    ),
                  ),

                  _buildSettingsTile(
                    context,
                    title: loc.t('load_default_data'),
                    subtitle: 'Reset exercises list',
                    icon: Icons.cloud_download_outlined,
                    color: Colors.blueGrey,
                    onTap: () async {
                      await FirestoreService().seedDefaultExercises();
                      if (context.mounted) {
                        ToastUtils.showSuccess(
                          context,
                          loc.t('default_loaded'),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    loc.t('sign_out'),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[trailing, const SizedBox(width: 8)],
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showMapPicker() {
    // Default to Rome if not set
    final initialCenter = _gymLat != null && _gymLng != null
        ? LatLng(_gymLat!, _gymLng!)
        : const LatLng(41.9028, 12.4964);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 13.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _gymLat = point.latitude;
                        _gymLng = point.longitude;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.gymflow.app',
                    ),
                    if (_gymLat != null && _gymLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_gymLat!, _gymLng!),
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: const Text('Tap to select location'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveGymInfo() async {
    setState(
      () => _isLoading = true,
    ); // Reuse isLoading for button state or add new one
    // Actually, let's create a local saving state to not mess with the page loading logic
    // But since _isLoading was for initial load, let's use a new variable or just wrap in try/catch properly.

    try {
      var userProfile = await AuthService().getUserProfile();

      // Fallback: If no Firestore doc exists, try to create from Auth
      if (userProfile == null) {
        final authUser = AuthService().currentUser;
        if (authUser != null) {
          userProfile = UserProfile(
            id: authUser.uid,
            email: authUser.email ?? '',
            displayName: authUser.displayName ?? 'User',
            createdAt: DateTime.now(),
          );
        } else {
          if (mounted) ToastUtils.showError(context, 'User not authenticated');
          return;
        }
      }

      final updatedProfile = UserProfile(
        id: userProfile.id,
        email: userProfile.email,
        displayName: userProfile.displayName,
        weight: userProfile.weight,
        height: userProfile.height,
        photoUrl: userProfile.photoUrl,
        createdAt: userProfile.createdAt,
        streakDays: userProfile.streakDays,
        gymName: _gymNameController.text.trim(),
        gymAddress: _gymAddressController.text.trim(),
        gymLat: _gymLat,
        gymLng: _gymLng,
        subscriptionExpiry: _subscriptionExpiry,
      );

      print('Saving profile: ${updatedProfile.toMap()}'); // Debug log

      await AuthService().updateUserProfile(updatedProfile);

      if (mounted) {
        ToastUtils.showSuccess(context, 'Gym Info Saved!');
      }
    } catch (e) {
      print('Error saving gym info: $e');
      if (mounted) {
        ToastUtils.showError(context, 'Error saving info: $e');
      }
    } finally {
      if (mounted)
        setState(() => _isLoading = false); // Or separate saving flag
    }
  }
}
