import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/app.dart';
import 'package:gymflow/src/ui/screens/time_tools_screen.dart';

class TimerOverlay extends ConsumerWidget {
  const TimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(timerNotifierProvider);
    final service = ref.read(timerNotifierProvider.notifier);

    final bool isStopwatchActive =
        service.isStopwatchRunning || service.stopwatchElapsed > Duration.zero;
    final bool isTimerActive =
        service.isTimerRunning || service.timerRemaining != service.timerDuration;

    final bool showOverlay =
        !service.isToolsVisible && (isStopwatchActive || isTimerActive);

    return SafeArea(
      bottom: false,
      child: AnimatedSize(
        duration: context.expressive.motion.standard,
        curve: context.expressive.motion.standardCurve,
        alignment: Alignment.topCenter,
        child: showOverlay ? _buildPill(context, service, isTimerActive) : const SizedBox.shrink(),
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
