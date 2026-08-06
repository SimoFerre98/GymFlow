import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/ui/auth_wrapper.dart';
// Prefisso necessario finche convivono i due sistemi: package:provider e
// flutter_riverpod dichiarano entrambi Provider, Consumer e
// ChangeNotifierProvider. Sparisce con US-007.
import 'package:provider/provider.dart' as legacy;
import 'package:gymflow/src/core/providers/theme_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/ui/widgets/timer_overlay.dart';

class GymFlowApp extends ConsumerWidget {
  const GymFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeSettingsNotifierProvider);

    // MultiProvider resta finche localizzazione e timer non sono migrati
    // (US-006 e US-007). Il tema non passa piu di qui.
    return legacy.MultiProvider(
      providers: [
        legacy.ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        legacy.Provider<FirestoreService>(create: (_) => FirestoreService()),
        legacy.ChangeNotifierProvider(create: (_) => TimerService()),
      ],
      child: legacy.Consumer<LocalizationProvider>(
        builder: (context, localizationProvider, child) {
          return MaterialApp(
            title: 'GymFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(theme.primaryColor),
            darkTheme: AppTheme.darkTheme(theme.primaryColor),
            themeMode: theme.themeMode,
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
