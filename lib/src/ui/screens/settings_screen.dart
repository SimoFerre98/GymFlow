import 'package:flutter/material.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:gymflow/src/core/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Mock settings state for now
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable push notifications'),
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
          const Divider(),
          ListTile(
            title: const Text('Account'),
            subtitle: Text(AuthService().currentUser?.email ?? 'Not logged in'),
            leading: const Icon(Icons.person),
          ),
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),
          ListTile(
            title: const Text('Load Default Exercises'),
            leading: const Icon(Icons.cloud_upload_outlined),
            onTap: () async {
              await FirestoreService().seedDefaultExercises();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Default exercises loaded!')),
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
      ),
    );
  }
}
