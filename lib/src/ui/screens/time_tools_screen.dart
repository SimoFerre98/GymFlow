import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
// Prefisso: convive con flutter_riverpod finche il timer non e migrato (US-007).
import 'package:provider/provider.dart' as legacy;
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      legacy.Provider.of<TimerService>(context, listen: false).setToolsVisible(true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // We can't access context easily in dispose if the widget is removed from tree,
    // but we can try. However, usually clean up is done via a route observer or similar.
    // For simplicity, we'll assume if this screen disposes, tools are not visible.
    // But since Provider might be disposed too if it was local (it's global now), we need to be careful.
    // Actually, accessing Provider in dispose is unsafe.
    // Better approach: Use a WillPopScope or RouteObserver.
    // But for MVP, let's rely on the Overlay checking if the user is on this page.
    // Actually, the simplest way is to assume if this widget is built, we are visible.
    // If we leave, we might not be able to set it to false easily without a RouteObserver.
    // Let's postpone setToolsVisible(false) and rely on the fact that if we navigate away,
    // this widget is still in the stack? No, if we pop, it disposes.
    // If we push, it stays. The user said "esco dal time tool" (pop) or "vado da un'altra parte" (push?).
    // If we use the Drawer to navigate, we usually Replace or Pop then Push.
    // Let's Try Microtask in dispose.
    scheduleMicrotask(() {
      // This might throw if context is unmounted, but since Service is global...
      // We need an instance ref.
    });

    super.dispose();
  }

  // Actually, to handle Dispose correctly for global provider:
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure visible when refined
    legacy.Provider.of<TimerService>(context, listen: false).setToolsVisible(true);
  }

  @override
  void deactivate() {
    legacy.Provider.of<TimerService>(context, listen: false).setToolsVisible(false);
    super.deactivate();
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
    // Consume TimerService
    final service = legacy.Provider.of<TimerService>(context);
    final loc = ref.watch(localizationNotifierProvider);

    // Logic for Buttons:
    // Left:
    // - If Running: "Parziale"
    // - If Paused/Stopped: "Reset" (unless 0)
    // Right:
    // - If Running: "Pausa" (Yellow/Orange)
    // - If Paused/Stopped: "Avvia" (Green)

    final isRunning = service.isStopwatchRunning;
    final hasTime = service.stopwatchElapsed > Duration.zero;

    return Column(
      children: [
        const Spacer(flex: 2),
        Text(
          _formatDuration(service.stopwatchElapsed),
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
            itemCount: service.stopwatchLaps.length,
            itemBuilder: (context, index) {
              final lapTime = service.stopwatchLaps[index];
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
                      '${loc.t('lap')} ${service.stopwatchLaps.length - index}',
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

  void _showTimePicker(BuildContext context, TimerService service) {
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
    final service = legacy.Provider.of<TimerService>(context);
    final loc = ref.watch(localizationNotifierProvider);
    final isRunning = service.isTimerRunning;

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
                value: service.timerDuration.inMilliseconds > 0
                    ? service.timerRemaining.inMilliseconds /
                          service.timerDuration.inMilliseconds
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
                _formatDuration(service.timerRemaining),
                style: TextStyle(
                  fontSize: 56, // Smaller to fit
                  fontWeight: FontWeight.bold,
                  color: service.timerRemaining == Duration.zero && !isRunning
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
            _buildPresetButton(service, 3, isRunning),
            const SizedBox(width: 16),
            _buildPresetButton(service, 5, isRunning),
            const SizedBox(width: 16),
            _buildPresetButton(service, 10, isRunning),
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
                  !isRunning && service.timerRemaining == service.timerDuration;
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

  Widget _buildPresetButton(TimerService service, int minutes, bool isRunning) {
    final isSelected = !isRunning && service.timerDuration.inMinutes == minutes;
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
