import 'package:flutter/material.dart';
import 'package:gymflow/src/services/auth_service.dart';

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
          // TODO: Add Theme selection here when ThemeProvider is implemented
        ],
      ),
    );
  }
}
