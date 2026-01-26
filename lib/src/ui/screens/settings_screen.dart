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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: StreamBuilder<UserProfile?>(
        stream: AuthService().getUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;
          // Update controllers if profile changes and we aren't editing?
          // For simplicity in this "view/edit" mix, we might need a more complex state management.
          // However, to solve the "slow load", showing data immediately is key.
          // Let's populate the controllers only if they are empty or if we want to sync.
          // But editing text fields while a stream updates them is tricky (cursor jumps).
          // OPTION: Load initial data from stream, then let user edit.
          // But the user asked for "load things then update".

          // Better approach for settings form:
          // 1. Initial build: show loading or cached data.
          // 2. If we receive data and controllers are "pristine" (not modified by user yet), update them.

          // Actually, the simplest fix for "slow load" is just using the stream to SHOW the data.
          // But here we have text fields.

          // Let's rely on the fact that the stream emits the CACHED value immediately.
          // So we can just use a FutureBuilder or similar, BUT `getUserProfile` was `get()`, forcing a network fetch if not configured to cache-first.
          // Firestore `get()` usually fetches from server unless source is specified.
          // `snapshots()` emits cache first.

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
              // 1. Account Section (Premium Banner)
              _buildSectionHeader('Account'),
              _buildSettingsCard(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    title: 'My Profile',
                    subtitle: profile?.displayName ?? 'Guest User',
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
                  const Divider(height: 1, indent: 60),
                  _buildSettingsTile(
                    context,
                    title: 'Body Measurements',
                    subtitle: 'Track your progress',
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
                  const Divider(height: 1, indent: 60),
                  _buildSettingsTile(
                    context,
                    title: 'Subscription',
                    subtitle: _subscriptionExpiry == null
                        ? 'Free Plan'
                        : 'Expires: ${_subscriptionExpiry!.toString().split(' ')[0]}',
                    icon: Icons.star_outline,
                    color: Colors.amber,
                    onTap: () async {
                      // Date Picker logic shifted here or similar
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 30),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (picked != null) {
                        setState(() => _subscriptionExpiry = picked);
                        _saveGymInfo(); // Auto save for simplicity in this flow? Or just local state.
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Gym Section
              _buildSectionHeader('Gym Settings'),
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
                    title: const Text(
                      'Gym Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _gymNameController.text.isNotEmpty
                          ? _gymNameController.text
                          : 'Set Name & Address',
                    ),
                    childrenPadding: const EdgeInsets.all(16),
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: const Border(), // Remove borders
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
                  const Divider(height: 1, indent: 60),
                  _buildSettingsTile(
                    context,
                    title: 'Gym Location',
                    subtitle: _gymLat != null
                        ? 'Location pinned'
                        : 'Tap to set location',
                    icon: Icons.map_outlined,
                    color: Colors.green,
                    onTap: _showMapPicker,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Preferences Section
              _buildSectionHeader('Preferences'),
              _buildSettingsCard(
                context,
                children: [
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
                    title: const Text(
                      'Notifications',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Workout reminders',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: _notificationsEnabled,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                  const Divider(height: 1, indent: 60),
                  // Theme Selector integrated cleanly
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return ListTile(
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
                        title: const Text(
                          'App Theme',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          themeProvider.themeMode == ThemeMode.system
                              ? 'System'
                              : (themeProvider.themeMode == ThemeMode.dark
                                    ? 'Dark Mode'
                                    : 'Light Mode'),
                        ),
                        trailing: DropdownButton<ThemeMode>(
                          value: themeProvider.themeMode,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          onChanged: (ThemeMode? newValue) {
                            if (newValue != null) {
                              themeProvider.setThemeMode(newValue);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('Auto'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildSettingsTile(
                    context,
                    title: 'Load Default Data',
                    subtitle: 'Reset exercises list',
                    icon: Icons.cloud_download_outlined,
                    color: Colors.blueGrey,
                    onTap: () async {
                      await FirestoreService().seedDefaultExercises();
                      if (context.mounted) {
                        ToastUtils.showSuccess(
                          context,
                          'Default exercises loaded!',
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
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
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
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
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
