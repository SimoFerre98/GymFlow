import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/app.dart';
import 'package:gymflow/src/ui/screens/time_tools_screen.dart';

/// La chiave della pillola, per i test.
const chiavePillola = Key('pillola_del_tempo');

/// Quanto e larga e alta la pillola.
///
/// Serve a tenerla dentro lo schermo mentre la si trascina, e a posizionarla in
/// basso a destra senza misurarla a posteriori. Piu grande di prima: era troppo
/// piccola per leggere il tempo con un'occhiata.
const double kLarghezzaPillola = 268;
const double kAltezzaPillola = 68;

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

/// La pillola flottante del tempo.
///
/// **Flotta, non occupa spazio.** Farle spingere giu il contenuto e stato
/// provato sul telefono ed era peggio del problema: tutta l'applicazione
/// scendeva. Quindi torna sopra, dove stava, un po' piu grande di prima e con i
/// colori del design system invece dei valori scritti a mano.
class TimerOverlay extends ConsumerStatefulWidget {
  const TimerOverlay({super.key});

  @override
  ConsumerState<TimerOverlay> createState() => _TimerOverlayState();
}

class _TimerOverlayState extends ConsumerState<TimerOverlay> {
  Offset? _posizione;

  @override
  Widget build(BuildContext context) {
    ref.watch(timerNotifierProvider);
    final service = ref.read(timerNotifierProvider.notifier);

    if (!pillolaVisibile(service)) return const SizedBox.shrink();

    // Il recupero ha la precedenza sul cronometro: e quello che scade.
    final isTimerActive =
        service.isTimerRunning ||
        service.timerRemaining != service.timerDuration;

    final schermo = MediaQuery.sizeOf(context);
    final bordo = MediaQuery.paddingOf(context);
    final t = context.expressive;

    // In basso a destra, dove stava prima. La posizione si ricorda solo se
    // l'utente l'ha spostata.
    final posizione =
        _posizione ??
        Offset(
          schermo.width - kLarghezzaPillola - t.spacing.lg,
          schermo.height - bordo.bottom - kAltezzaPillola - t.spacing.xxl,
        );

    return Positioned(
      left: posizione.dx,
      top: posizione.dy,
      child: GestureDetector(
        onPanUpdate: (dettagli) {
          setState(() {
            final nuova = posizione + dettagli.delta;
            // Non oltre i bordi, o si perde fuori dallo schermo.
            _posizione = Offset(
              nuova.dx.clamp(0.0, schermo.width - kLarghezzaPillola),
              nuova.dy.clamp(bordo.top, schermo.height - kAltezzaPillola),
            );
          });
        },
        child: _buildPill(context, service, isTimerActive),
      ),
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
        // La larghezza e quella dichiarata, non quella che viene: cosi il
        // calcolo che la tiene dentro lo schermo dice il vero. Misurato: a ruota
        // libera arrivava a 400 dp su uno schermo da 360, e meta dei comandi
        // finiva fuori — intoccabili.
        width: kLarghezzaPillola,
        height: kAltezzaPillola,
        alignment: Alignment.center,
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
          children: [
            Icon(
              isTimerActive ? Icons.hourglass_bottom : Icons.timer,
              color: scheme.primary,
              size: t.sizing.iconLg,
            ),
            SizedBox(width: t.spacing.sm),
            // Il tempo prende lo spazio che avanza e si adatta: e la parte che
            // si legge di sfuggita, quindi la piu grande che ci stia.
            Expanded(
              child: RepaintBoundary(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _getMainDisplay(service, isTimerActive),
                    style: t.typography.metricMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: t.spacing.sm),
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
