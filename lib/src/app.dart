import 'package:flutter/material.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/ui/auth_wrapper.dart';

class GymFlowApp extends StatelessWidget {
  const GymFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Add Providers here (Auth, UserProfile, Workout)
    return MaterialApp(
      title: 'GymFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          ThemeMode.system, // TODO: Implement dynamic theme switching provider
      home: const AuthWrapper(),
    );
  }
}
