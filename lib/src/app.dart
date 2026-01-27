import 'package:flutter/material.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/ui/auth_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:gymflow/src/core/providers/theme_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/ui/widgets/timer_overlay.dart';

class GymFlowApp extends StatelessWidget {
  const GymFlowApp({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => TimerService()),
      ],
      child: Consumer2<ThemeProvider, LocalizationProvider>(
        builder: (context, themeProvider, localizationProvider, child) {
          return MaterialApp(
            title: 'GymFlow',
            debugShowCheckedModeBanner: false,
            // Pass primaryColor to the theme generator methods
            theme: AppTheme.lightTheme(themeProvider.primaryColor),
            darkTheme: AppTheme.darkTheme(themeProvider.primaryColor),
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
