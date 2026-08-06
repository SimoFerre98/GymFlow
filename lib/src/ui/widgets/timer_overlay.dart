import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/services/timer_service.dart';

class TimerOverlay extends ConsumerStatefulWidget {
  const TimerOverlay({super.key});

  @override
  ConsumerState<TimerOverlay> createState() => _TimerOverlayState();
}

class _TimerOverlayState extends ConsumerState<TimerOverlay> {
  // Initial position (bottom right-ish)
  Offset _position = const Offset(20, 100);
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Set initial position safely after context is available
      final size = MediaQuery.of(context).size;
      _position = Offset(size.width - 200, size.height - 150);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // watch per ricostruire a ogni tick; il notifier espone stato e comandi.
    ref.watch(timerNotifierProvider);
    final service = ref.read(timerNotifierProvider.notifier);

    // Logic to show overlay
    final bool isStopwatchActive =
        service.isStopwatchRunning || service.stopwatchElapsed > Duration.zero;
    final bool isTimerActive =
        service.isTimerRunning ||
        service.timerRemaining != service.timerDuration;

    final bool showOverlay =
        !service.isToolsVisible && (isStopwatchActive || isTimerActive);

    if (!showOverlay) return const SizedBox.shrink();

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(50), // Pill shape
          color: Theme.of(context).primaryColor, // More visible
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20, // Increased
              vertical: 12, // Increased
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              // border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Wrap content
              children: [
                // Icon
                Icon(
                  service.isStopwatchRunning ||
                          service.stopwatchElapsed > Duration.zero
                      ? Icons.timer
                      : Icons.hourglass_bottom,
                  color: Colors.white,
                  size: 24, // Increased
                ),
                const SizedBox(width: 12),
                // Text
                RepaintBoundary(
                  child: Text(
                    _getMainDisplay(service),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Increased
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Controls (Compact)
                // Pause/Resume
                InkWell(
                  onTap: () {
                    if (service.stopwatchElapsed > Duration.zero ||
                        service.isStopwatchRunning) {
                      service.toggleStopwatch();
                    } else {
                      service.toggleTimer();
                    }
                  },
                  child: Icon(
                    (service.isStopwatchRunning || service.isTimerRunning)
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                // Close
                InkWell(
                  onTap: () {
                    if (service.stopwatchElapsed > Duration.zero ||
                        service.isStopwatchRunning) {
                      service.resetStopwatch();
                    } else {
                      service.resetTimer();
                    }
                  },
                  child: const Icon(
                    Icons.cancel,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMainDisplay(TimerNotifier service) {
    if (service.isStopwatchRunning ||
        service.stopwatchElapsed > Duration.zero) {
      final d = service.stopwatchElapsed;
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(d.inMinutes.remainder(60));
      final seconds = twoDigits(d.inSeconds.remainder(60));
      return '$minutes:$seconds';
    } else {
      final d = service.timerRemaining;
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(d.inMinutes.remainder(60));
      final seconds = twoDigits(d.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }
  }
}
