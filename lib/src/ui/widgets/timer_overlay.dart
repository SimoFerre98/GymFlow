import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymflow/src/services/timer_service.dart';

class TimerOverlay extends StatelessWidget {
  const TimerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, service, child) {
        // Show only if not visible in main screen AND (stopwatch running OR timer running)
        // Actually user said: "when I start ... and exit ... show small box"
        // Also: "buttons to eliminate timer or block it"
        final showOverlay =
            !service.isToolsVisible &&
            (service.isStopwatchRunning ||
                service.isTimerRunning ||
                service.timerRemaining != service.timerDuration);
        // Also show if paused but not reset? Usually yes.
        // Let's stick to "Running or Paused (non-zero)"

        if (!showOverlay) return const SizedBox.shrink();

        // If Timer is just default (5m) and not running, don't show.
        if (!service.isTimerRunning &&
            service.timerRemaining == service.timerDuration &&
            !service.isStopwatchRunning &&
            service.stopwatchElapsed == Duration.zero) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 80, // Above Bottom Nav if exists
          right: 16,
          left: 16,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  // Icon
                  Icon(
                    service.isStopwatchRunning ||
                            service.stopwatchElapsed > Duration.zero
                        ? Icons.timer
                        : Icons.hourglass_bottom,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Text(
                      _getMainDisplay(service),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Controls
                  // "stop with same button" logic is inside service toggle.
                  // User wants "two small buttons to eliminate or block".
                  // Block = Pause? Eliminate = Reset/Close?

                  // Pause/Resume Button
                  IconButton(
                    icon: Icon(
                      (service.isStopwatchRunning || service.isTimerRunning)
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      if (service.stopwatchElapsed > Duration.zero ||
                          service.isStopwatchRunning) {
                        service.toggleStopwatch();
                      } else {
                        service.toggleTimer();
                      }
                    },
                    color: Colors.orange,
                  ),
                  // Close/Reset Button
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (service.stopwatchElapsed > Duration.zero ||
                          service.isStopwatchRunning) {
                        service.resetStopwatch();
                      } else {
                        service.resetTimer();
                      }
                    },
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMainDisplay(TimerService service) {
    // Prioritize showing what is running. If both, show stopwatch? Or Timer?
    // Let's assume user uses one at a time.
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
