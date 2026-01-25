import 'package:flutter/material.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gymflow/src/core/providers/theme_provider.dart';

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

          if (profile != null &&
              _gymNameController.text.isEmpty &&
              !_isLoading) {
            _gymNameController.text = profile.gymName ?? '';
            _gymAddressController.text = profile.gymAddress ?? '';
            _gymLat = profile.gymLat;
            _gymLng = profile.gymLng;
            _subscriptionExpiry = profile.subscriptionExpiry;
          }

          return ListView(
            children: [
              _buildGymSection(), // Pass context if needed, or remove arg if not used
              const Divider(),
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Enable push notifications'),
                value: _notificationsEnabled,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
              const Divider(),
              ListTile(
                title: const Text('Account'),
                subtitle: Text(profile?.email ?? 'Not logged in'),
                leading: const Icon(Icons.person),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              ListTile(
                title: const Text('Logout'),
                leading: const Icon(Icons.logout, color: Colors.red),
                onTap: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
              ),
              ListTile(
                title: const Text('Load Default Exercises'),
                leading: const Icon(Icons.cloud_upload_outlined),
                onTap: () async {
                  await FirestoreService().seedDefaultExercises();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Default exercises loaded!'),
                      ),
                    );
                  }
                },
              ),
              // Theme Selection
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return Column(
                    children: [
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, top: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Theme',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('System Default'),
                        value: ThemeMode.system,
                        groupValue: themeProvider.themeMode,
                        onChanged: (val) => themeProvider.setThemeMode(val!),
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Light Mode'),
                        value: ThemeMode.light,
                        groupValue: themeProvider.themeMode,
                        onChanged: (val) => themeProvider.setThemeMode(val!),
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Dark Mode'),
                        value: ThemeMode.dark,
                        groupValue: themeProvider.themeMode,
                        onChanged: (val) => themeProvider.setThemeMode(val!),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGymSection() {
    return ExpansionTile(
      leading: const Icon(Icons.fitness_center),
      title: const Text('Gym Information'),
      subtitle: const Text('Set your gym location & subscription'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _gymNameController,
                decoration: const InputDecoration(labelText: 'Gym Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _gymAddressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _subscriptionExpiry == null
                      ? 'Set Subscription Expiry'
                      : 'Expires: ${_subscriptionExpiry!.toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() => _subscriptionExpiry = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _gymLat != null && _gymLng != null
                      ? 'Location Set'
                      : 'Pick Location on Map',
                ),
                trailing: const Icon(Icons.map),
                onTap: () => _showMapPicker(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveGymInfo,
                child: const Text('Save Gym Info'),
              ),
            ],
          ),
        ),
      ],
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
    final userProfile = await AuthService().getUserProfile();
    if (userProfile != null) {
      final updatedProfile = UserProfile(
        id: userProfile.id,
        email: userProfile.email,
        displayName: userProfile.displayName,
        weight: userProfile.weight,
        height: userProfile.height,
        photoUrl: userProfile.photoUrl,
        createdAt: userProfile.createdAt,
        streakDays: userProfile.streakDays,
        gymName: _gymNameController.text,
        gymAddress: _gymAddressController.text,
        gymLat: _gymLat,
        gymLng: _gymLng,
        subscriptionExpiry: _subscriptionExpiry,
      );

      await AuthService().updateUserProfile(updatedProfile);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gym Info Saved!')));
      }
    }
  }
}
