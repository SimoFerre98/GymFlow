import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/ui/auth_wrapper.dart';
import 'package:gymflow/src/core/providers/theme_provider.dart';
import 'package:gymflow/src/ui/widgets/timer_overlay.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class GymFlowApp extends ConsumerWidget {
  const GymFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeSettingsNotifierProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'GymFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(theme.primaryColor),
      darkTheme: AppTheme.darkTheme(theme.primaryColor),
      themeMode: theme.themeMode,
      home: const AuthWrapper(),
      builder: (context, child) {
        return Column(
          children: [
            const TimerOverlay(),
            if (child != null) Expanded(child: child),
          ],
        );
      },
    );
  }
}
