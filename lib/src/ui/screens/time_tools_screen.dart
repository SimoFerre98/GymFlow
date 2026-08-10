import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/ui/widgets/app_drawer.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';

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
        const Spacer(flex: 2),
        Text(
          _formatDuration(stato.stopwatchElapsed),
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const Spacer(flex: 1),
        // Laps List
        Expanded(
          flex: 4,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            itemCount: stato.stopwatchLaps.length,
            itemBuilder: (context, index) {
              final lapTime = stato.stopwatchLaps[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${loc.t('lap')} ${stato.stopwatchLaps.length - index}',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    Text(
                      _formatDuration(lapTime),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Left Button (Lap / Reset)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (isRunning) {
                        service.lapStopwatch();
                      } else {
                        service.resetStopwatch();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isRunning
                          ? Colors.grey[300]
                          : Colors.red, // Grey for Lap, Red for Reset
                      foregroundColor: isRunning ? Colors.black : Colors.white,
                    ),
                    child: Text(
                      isRunning ? loc.t('lap') : loc.t('reset'),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
              // Right Button (Avvia / Pausa)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton(
                    onPressed: service.toggleStopwatch,
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isRunning
                          ? Colors.orange
                          : Colors.green, // Orange for Pause, Green for Start
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isRunning ? loc.t('pause') : loc.t('start'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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

    // Logic for Buttons (requested):
    // "Quando avvio un timer, vorrei poterlo prima stoppare con lo stesso pulsante" -> Pause
    // "e quando lo fermo il testo a sinistra diventa il tasto che fa resettare l'orologio" -> Reset
    //
    // So:
    // Right Button: Start / Pause
    // Left Button:
    //  - If Running: Disabled or maybe "+1m"? (User didn't specify, likely nothing or Lap?)
    //  - If Paused: Reset

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Display Time
        // Circular Progress + Time
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: CircularProgressIndicator(
                value: stato.timerDuration.inMilliseconds > 0
                    ? stato.timerRemaining.inMilliseconds /
                          stato.timerDuration.inMilliseconds
                    : 0.0,
                strokeWidth: 12,
                backgroundColor: Theme.of(
                  context,
                ).disabledColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isRunning ? Colors.orange : Theme.of(context).primaryColor,
                ),
              ),
            ),
            GestureDetector(
              onTap: isRunning ? null : () => _showTimePicker(context, service),
              child: Text(
                _formatDuration(stato.timerRemaining),
                style: TextStyle(
                  fontSize: 56, // Smaller to fit
                  fontWeight: FontWeight.bold,
                  color: stato.timerRemaining == Duration.zero && !isRunning
                      ? Colors.red
                      : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        if (!isRunning)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              loc.t('tap_to_edit'),
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        const Spacer(),
        // Presets
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPresetButton(service, stato.timerDuration, 3, isRunning),
            const SizedBox(width: 16),
            _buildPresetButton(service, stato.timerDuration, 5, isRunning),
            const SizedBox(width: 16),
            _buildPresetButton(service, stato.timerDuration, 10, isRunning),
          ],
        ),
        const SizedBox(height: 48),

        // Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Logic: Show split if we are NOT in the initial state (Timer not running AND at full duration)
              // i.e. Show split if Running OR (Paused/Finished and not at full duration)
              final bool isInitial =
                  !isRunning && stato.timerRemaining == stato.timerDuration;
              final bool showSplit = !isInitial;

              final double totalWidth = constraints.maxWidth;
              // We want a gap of 16 when split
              final double gap = 16.0;
              // Calculate width for the left button (Reset)
              // When split: (Total - Gap) / 2
              // When not split: 0
              final double resetButtonTargetWidth = showSplit
                  ? (totalWidth - gap) / 2
                  : 0;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LEFT BUTTON (Reset) - Animated Entry
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: resetButtonTargetWidth,
                    height: 56, // Fixed height for smoother animation
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Container(
                        width:
                            (totalWidth - gap) /
                            2, // Always render full width content to avoid squishing
                        padding: const EdgeInsets.only(
                          right: 0,
                        ), // No padding needed here
                        child: ElevatedButton(
                          onPressed: service.resetTimer,
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            fixedSize: Size.fromHeight(56),
                          ),
                          child: Text(
                            loc.t('reset'),
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // GAP - Animated
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: showSplit ? gap : 0,
                  ),

                  // RIGHT BUTTON (Start / Pause)
                  // We can't use Expanded easily with AnimatedContainer width changes causing flex issues?
                  // Actually, if we use a fixed width for the Right button that animates from Full to Half?
                  // Or just Expanded?
                  // If Left is 0, Gap is 0, Expanded takes Total.
                  // If Left is Half, Gap is 16, Expanded takes Remaining (Half).
                  // This works perfectly without explicit width animation on this one.
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: service.toggleTimer,
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: isRunning
                              ? Colors.orange
                              : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          isRunning ? loc.t('pause') : loc.t('start'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const Spacer(flex: 2),
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
    return ElevatedButton(
      onPressed: isRunning
          ? null
          : () => service.setTimerDuration(Duration(minutes: minutes)),
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text('${minutes}m'),
    );
  }
}
