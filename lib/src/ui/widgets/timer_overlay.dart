import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/app.dart';
import 'package:gymflow/src/ui/screens/time_tools_screen.dart';

/// La chiave della pillola, per i test.
const chiavePillola = Key('pillola_del_tempo');

/// Se la pillola del tempo deve comparire.
///
/// Sta qui e non dentro `build` perche la serve anche il telaio in `app.dart`,
/// che sulla stessa risposta decide se togliere al contenuto il bordo di sistema
/// — quello che la pillola sta gia coprendo. Due copie della stessa condizione
/// finirebbero per divergere.
bool pillolaVisibile(TimerNotifier service) {
  final cronometroAttivo =
      service.isStopwatchRunning || service.stopwatchElapsed > Duration.zero;
  final recuperoAttivo =
      service.isTimerRunning || service.timerRemaining != service.timerDuration;
  return !service.isToolsVisible && (cronometroAttivo || recuperoAttivo);
}

class TimerOverlay extends ConsumerWidget {
  const TimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(timerNotifierProvider);
    final service = ref.read(timerNotifierProvider.notifier);

    // Il recupero ha la precedenza sul cronometro: e quello che scade.
    final bool isTimerActive =
        service.isTimerRunning || service.timerRemaining != service.timerDuration;

    // La `SafeArea` sta **dentro** il ramo visibile e non attorno a tutto.
    // Attorno, impagina un figlio di dimensione zero e occupa comunque la
    // fascia di sistema: misurato, con una barra di stato da 40 dp la pillola
    // nascosta si prendeva 40 dp su ogni schermata, per sempre.
    return AnimatedSize(
      duration: context.expressive.motion.standard,
      curve: context.expressive.motion.standardCurve,
      alignment: Alignment.topCenter,
      child: pillolaVisibile(service)
          ? SafeArea(
              bottom: false,
              child: _buildPill(context, service, isTimerActive),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPill(BuildContext context, TimerNotifier service, bool isTimerActive) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.expressive;

    return GestureDetector(
      onTap: () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const TimeToolsScreen(),
          ),
        );
      },
      child: Container(
        // Con una chiave: `find.byType(Container)` prende il primo Container
        // che capita, e in un albero vero ce ne sono molti.
        key: chiavePillola,
        margin: EdgeInsets.all(t.spacing.sm),
        padding: EdgeInsets.symmetric(
          horizontal: t.spacing.lg,
          vertical: t.spacing.md,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: t.shape.cornerFull,
          boxShadow: t.elevation.level3(scheme.shadow),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTimerActive ? Icons.hourglass_bottom : Icons.timer,
              color: scheme.primary,
              size: t.sizing.iconLg,
            ),
            SizedBox(width: t.spacing.sm),
            RepaintBoundary(
              child: Text(
                _getMainDisplay(service, isTimerActive),
                style: t.typography.metricMedium?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
            SizedBox(width: t.spacing.md),
            GestureDetector(
              onTap: () {
                if (isTimerActive) {
                  service.toggleTimer();
                } else {
                  service.toggleStopwatch();
                }
              },
              child: Icon(
                (isTimerActive ? service.isTimerRunning : service.isStopwatchRunning)
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: scheme.primary,
                size: t.sizing.iconLg,
              ),
            ),
            SizedBox(width: t.spacing.sm),
            GestureDetector(
              onTap: () {
                if (isTimerActive) {
                  service.resetTimer();
                } else {
                  service.resetStopwatch();
                }
              },
              child: Icon(
                Icons.cancel,
                color: scheme.onSurfaceVariant,
                size: t.sizing.iconLg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMainDisplay(TimerNotifier service, bool isTimerActive) {
    final Duration d;
    if (isTimerActive) {
      d = service.timerRemaining;
    } else {
      d = service.stopwatchElapsed;
    }
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
