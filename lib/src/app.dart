import 'package:flutter/material.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/ui/auth_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:gymflow/src/core/providers/theme_provider.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/ui/widgets/timer_overlay.dart';

class GymFlowApp extends StatelessWidget {
  const GymFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => TimerService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'GymFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            builder: (context, child) {
              return Stack(
                children: [if (child != null) child, const TimerOverlay()],
              );
            },
          );
        },
      ),
    );
  }
}
