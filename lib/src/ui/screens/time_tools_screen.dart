import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/ui/widgets/time_dial.dart';

class TimeToolsScreen extends ConsumerStatefulWidget {
  const TimeToolsScreen({super.key});

  @override
  ConsumerState<TimeToolsScreen> createState() => _TimeToolsScreenState();
}

class _TimeToolsScreenState extends ConsumerState<TimeToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Il notifier del tempo, catturato dopo il primo frame.
  ///
  /// Serve per spegnere la visibilita in `dispose`, dove leggere `ref` non e
  /// piu sicuro. Tenerne il riferimento e lecito perche `TimerNotifier` e
  /// `keepAlive`: non viene distrutto quando questa schermata muore.
  TimerNotifier? _timerNotifier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Dopo il frame e non subito: modificare un provider mentre l'albero si
    // costruisce solleva un'eccezione, e la schermata diventa rossa.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timerNotifier = ref.read(timerNotifierProvider.notifier);
      _timerNotifier!.setToolsVisible(true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();

    // L'overlay flottante torna visibile uscendo di qui.
    //
    // In un microtask perche `dispose` gira dentro la stessa fase in cui
    // l'albero si smonta, e modificare un provider la' dentro e la stessa
    // eccezione di prima: il microtask parte quando quella fase e finita. E la
    // via che il messaggio d'errore di Riverpod indica esplicitamente.
    //
    // In `dispose` e non in `deactivate`: `deactivate` scatta anche quando un
    // widget viene riagganciato altrove nell'albero, e nasconderebbe l'overlay
    // per un movimento che non ha portato l'utente da nessuna parte.
    final notifier = _timerNotifier;
    if (notifier != null) {
      scheduleMicrotask(() => notifier.setToolsVisible(false));
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.t('stopwatch_menu'),
        ), // Using general stopwatch_menu key or specific title
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(), // Persistent Drawer
      body: Column(
        children: [
          // Styled Pill Tabs
          Container(
            height: 50,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: loc.t('stopwatch_tab')),
                Tab(text: loc.t('timer_tab')),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [StopwatchView(), TimerView()],
            ),
          ),
        ],
      ),
    );
  }
}

class StopwatchView extends ConsumerWidget {
  const StopwatchView({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final deciseconds = (d.inMilliseconds % 1000) ~/ 100;
    return '$minutes:$seconds:$deciseconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `watch` sullo **stato** e `read` sul notifier, e la distinzione non e
    // stilistica: con il solo `read` questa vista non si iscrive a niente, il
    // ticker gira, lo stato cambia e lo schermo resta fermo sul primo frame.
    // Da qui il «tocco un tasto e non succede niente»: i tasti funzionavano,
    // era il disegno che non tornava.
    //
    // Quindi i valori si leggono da `stato`, e `service` serve solo alle azioni.
    final stato = ref.watch(timerNotifierProvider);
    final service = ref.read(timerNotifierProvider.notifier);
    final loc = ref.watch(localizationNotifierProvider);

    // Logic for Buttons:
    // Left:
    // - If Running: "Parziale"
    // - If Paused/Stopped: "Reset" (unless 0)
    // Right:
    // - If Running: "Pausa" (Yellow/Orange)
    // - If Paused/Stopped: "Avvia" (Green)

    final isRunning = stato.isStopwatchRunning;
    final hasTime = stato.stopwatchElapsed > Duration.zero;

    return Column(
      children: [
        // Il quadrante prende lo spazio che avanza: «tutta l'altezza, un solo
        // protagonista». Prima le cifre stavano in mezzo al vuoto e l'ultima
        // arrivava tagliata — sullo schermo si leggeva «00:00:0».
        Expanded(
          child: TimeDial(
            tempo: _formatDuration(stato.stopwatchElapsed),
            etichetta: isRunning
                ? loc.t('time_running')
                : (hasTime ? loc.t('time_paused') : loc.t('time_ready')),
          ),
        ),
        // I giri, se ce ne sono.
        if (stato.stopwatchLaps.isNotEmpty)
          SizedBox(
            height: context.expressive.sizing.thumbnailMd * 2,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: context.expressive.spacing.lg,
              ),
              itemCount: stato.stopwatchLaps.length,
              itemBuilder: (context, index) {
                final lapTime = stato.stopwatchLaps[index];
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: context.expressive.spacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${loc.t('lap')} ${stato.stopwatchLaps.length - index}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatDuration(lapTime),
                        style: context.expressive.typography.metricSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: EdgeInsets.all(context.expressive.spacing.lg),
          child: TimeControls(
            inCorsa: isRunning,
            onPrimario: service.toggleStopwatch,
            etichettaPrimario: isRunning ? loc.t('pause') : loc.t('start'),
            iconaSinistra: Icons.refresh_rounded,
            etichettaSinistra: loc.t('reset'),
            // «Azzera» non compare a cronometro fermo su zero: non c'e niente
            // da azzerare. Era una delle intenzioni non implementate dei
            // diciassette avvisi — la variabile `hasTime` scritta e mai letta.
            onSinistra: hasTime ? service.resetStopwatch : null,
            iconaDestra: Icons.flag_outlined,
            etichettaDestra: loc.t('lap'),
            onDestra: isRunning ? service.lapStopwatch : null,
          ),
        ),
      ],
    );
  }
}

class TimerView extends ConsumerWidget {
  const TimerView({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final deciseconds = (d.inMilliseconds % 1000) ~/ 100;

    if (hours > 0) {
      return '$hours:$minutes:$seconds:$deciseconds';
    }
    return '$minutes:$seconds:$deciseconds';
  }

  void _showTimePicker(BuildContext context, TimerNotifier service) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: Theme.of(context).cardColor,
        child: CupertinoTimerPicker(
          mode: CupertinoTimerPickerMode.hm,
          initialTimerDuration: service.timerDuration,
          onTimerDurationChanged: (Duration newDuration) {
            // Only allow update if not running handled inside service via check or UI disable
            if (!service.isTimerRunning) {
              service.setTimerDuration(newDuration);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Vedi la nota in `StopwatchView.build`: senza `watch` sullo stato questa
    // vista non si ricostruisce, e il conto alla rovescia resta fermo.
    final stato = ref.watch(timerNotifierProvider);
    final service = ref.read(timerNotifierProvider.notifier);
    final loc = ref.watch(localizationNotifierProvider);
    final isRunning = stato.isTimerRunning;

    final durata = stato.timerDuration;
    final restante = stato.timerRemaining;
    final haTempo = restante != durata || isRunning;

    return Column(
      children: [
        // Il quadrante, con l'anello che dice quanto resta senza leggere le
        // cifre: e la ragione per cui il mockup lo vuole grande.
        Expanded(
          child: GestureDetector(
            onTap: isRunning ? null : () => _showTimePicker(context, service),
            child: TimeDial(
              tempo: _formatDuration(restante),
              etichetta: isRunning
                  ? loc.t('time_running')
                  : (haTempo ? loc.t('time_paused') : loc.t('tap_to_edit')),
              frazione: durata.inMilliseconds > 0
                  ? restante.inMilliseconds / durata.inMilliseconds
                  : 0,
              // Il quadrante del recupero vira sul salmone: il tempo di
              // recupero e un dato del corpo, non un'azione da fare.
              coloreArco: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ),
        // I tempi pronti, come le pillole del mockup.
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.expressive.spacing.lg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPresetButton(service, durata, 1, isRunning),
              _buildPresetButton(service, durata, 2, isRunning),
              _buildPresetButton(service, durata, 3, isRunning),
              _buildPresetButton(service, durata, 5, isRunning),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(context.expressive.spacing.lg),
          child: TimeControls(
            inCorsa: isRunning,
            onPrimario: service.toggleTimer,
            etichettaPrimario: isRunning ? loc.t('pause') : loc.t('start'),
            iconaSinistra: Icons.refresh_rounded,
            etichettaSinistra: loc.t('reset'),
            onSinistra: haTempo ? service.resetTimer : null,
          ),
        ),
      ],
    );
  }

  /// La durata arriva come parametro invece di essere riletta dal notifier: qui
  /// si sta disegnando, e cio che si disegna deve venire dallo stato osservato.
  Widget _buildPresetButton(
    TimerNotifier service,
    Duration durataCorrente,
    int minutes,
    bool isRunning,
  ) {
    final isSelected = !isRunning && durataCorrente.inMinutes == minutes;
    return Builder(
      builder: (context) {
        final t = context.expressive;
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: t.spacing.xs),
          child: TextButton(
            onPressed: isRunning
                ? null
                : () => service.setTimerDuration(Duration(minutes: minutes)),
            style: TextButton.styleFrom(
              shape: const StadiumBorder(),
              // La pillola scelta e in ambra, le altre sono superficie: e la
              // stessa grammatica del segmentato del mockup.
              backgroundColor: isSelected
                  ? scheme.primary
                  : scheme.surfaceContainerHigh,
              foregroundColor: isSelected
                  ? scheme.onPrimary
                  : scheme.onSurfaceVariant,
              padding: EdgeInsets.symmetric(
                horizontal: t.spacing.md,
                vertical: t.spacing.sm,
              ),
            ),
            child: Text('${minutes}m'),
          ),
        );
      },
    );
  }
}
