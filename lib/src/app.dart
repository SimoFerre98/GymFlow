import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/ui/auth_wrapper.dart';
import 'package:gymflow/src/core/providers/theme_provider.dart';
import 'package:gymflow/src/ui/widgets/timer_overlay.dart';
import 'package:gymflow/src/services/timer_service.dart';

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
      builder: (context, child) => GymFlowShell(child: child),
    );
  }
}

/// Il telaio: la pillola del tempo in alto, tutto il resto sotto.
///
/// È un widget e non una chiusura dentro `builder` per una ragione precisa: i
/// test devono poter montare **questo**, cioe la struttura vera. La prima
/// versione di US-052 era provata da test che si costruivano una `Column` nel
/// proprio file, e sarebbero rimasti verdi anche rimettendo lo `Stack` che
/// copriva il contenuto — cioe proprio il difetto che la storia chiude.
class GymFlowShell extends ConsumerWidget {
  const GymFlowShell({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(timerNotifierProvider);
    final visibile = pillolaVisibile(ref.read(timerNotifierProvider.notifier));

    return Column(
      children: [
        const TimerOverlay(),
        if (child != null)
          Expanded(
            // Quando la pillola c'e, copre lei la fascia di sistema: lasciarla
            // anche al contenuto significa una seconda striscia vuota sotto di
            // lei, che su una schermata con `AppBar` misura altri 40 dp.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: visibile,
              child: child!,
            ),
          ),
      ],
    );
  }
}
