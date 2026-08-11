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
      builder: (context, child) => GymFlowShell(child: child),
    );
  }
}

/// Il telaio: la pillola del tempo **sopra** il contenuto, senza spostarlo.
///
/// È tornata a flottare dopo la prova sul telefono: farle occupare spazio in
/// una `Column` spingeva giu tutta l'applicazione, e il risultato era peggiore
/// del problema che risolveva. Il criterio di US-052 diceva «il contenuto si
/// sposta invece di essere coperto»: era sbagliato, e a dirlo e stato l'occhio
/// sull'APK. Resta di quel giro tutto il resto — i token al posto dei valori a
/// mano, il tocco che porta al tempo, la precedenza al recupero.
///
/// È un widget e non una chiusura dentro `builder` perche i test devono poter
/// montare **questo**, cioe la struttura vera: la prima versione di US-052 era
/// provata da test che si costruivano un albero nel proprio file.
class GymFlowShell extends ConsumerWidget {
  const GymFlowShell({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        if (child != null) child!,
        const TimerOverlay(),
      ],
    );
  }
}
