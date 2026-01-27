import 'dart:async';
import 'package:flutter/foundation.dart';

class TimerService extends ChangeNotifier {
  // --- Stopwatch State ---
  Duration _stopwatchElapsed = Duration.zero;
  Duration _stopwatchOffset = Duration.zero; // Time accrued in previous runs
  DateTime? _stopwatchStartTime;
  bool _isStopwatchRunning = false;
  List<Duration> _stopwatchLaps = [];

  // --- Timer State ---
  Duration _timerDuration = const Duration(minutes: 5);
  Duration _timerRemaining = const Duration(minutes: 5);
  bool _isTimerRunning = false;
  DateTime? _timerEndTime;

  // Visibility Tracking for Overlay
  bool _isToolsVisible = false;

  // Tick Timer (for UI updates)
  Timer? _ticker;

  // Getters
  Duration get stopwatchElapsed => _stopwatchElapsed;
  bool get isStopwatchRunning => _isStopwatchRunning;
  List<Duration> get stopwatchLaps => List.unmodifiable(_stopwatchLaps);

  Duration get timerDuration => _timerDuration;
  Duration get timerRemaining => _timerRemaining;
  bool get isTimerRunning => _isTimerRunning;
  bool get isToolsVisible => _isToolsVisible;

  TimerService() {
    // Start a periodic ticker to update UI for high-precision
    _ticker = Timer.periodic(const Duration(milliseconds: 30), _onTick);
  }

  void setToolsVisible(bool visible) {
    _isToolsVisible = visible;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onTick(Timer timer) {
    bool notify = false;

    // Update Stopwatch
    if (_isStopwatchRunning && _stopwatchStartTime != null) {
      final now = DateTime.now();
      _stopwatchElapsed =
          _stopwatchOffset + now.difference(_stopwatchStartTime!);
      notify = true;
    }

    // Update Timer
    if (_isTimerRunning && _timerEndTime != null) {
      final now = DateTime.now();
      final remaining = _timerEndTime!.difference(now);
      if (remaining.isNegative) {
        _timerRemaining = Duration.zero;
        _isTimerRunning = false;
        _timerEndTime = null;
        // Optionally trigger callback / notification here
      } else {
        _timerRemaining = remaining;
      }
      notify = true;
    }

    if (notify) notifyListeners();
  }

  // --- Stopwatch Methods ---

  void toggleStopwatch() {
    if (_isStopwatchRunning) {
      // Pause
      _isStopwatchRunning = false;
      // Bake current elapsed into offset
      if (_stopwatchStartTime != null) {
        _stopwatchOffset += DateTime.now().difference(_stopwatchStartTime!);
        _stopwatchStartTime = null;
      }
    } else {
      // Start/Resume
      _isStopwatchRunning = true;
      _stopwatchStartTime = DateTime.now();
    }
    notifyListeners();
  }

  void resetStopwatch() {
    _isStopwatchRunning = false;
    _stopwatchStartTime = null;
    _stopwatchOffset = Duration.zero;
    _stopwatchElapsed = Duration.zero;
    _stopwatchLaps.clear();
    notifyListeners();
  }

  void lapStopwatch() {
    if (_stopwatchElapsed == Duration.zero) return;
    _stopwatchLaps.insert(0, _stopwatchElapsed);
    notifyListeners();
  }

  // --- Timer Methods ---

  void setTimerDuration(Duration d) {
    if (_isTimerRunning) return; // Prevent change while running
    _timerDuration = d;
    _timerRemaining = d;
    notifyListeners();
  }

  void toggleTimer() {
    if (_isTimerRunning) {
      // Pause (logic requested: "ferma che riazzera" or pause?
      // User request: "Quando starto un timer vorrei che non si resettasse ma che continuasse a funzionare" -> Background persistence
      // "vorrei poterlo prima stoppare con lo stesso pulsanto ... e quando lo fermo ... tasto resetta"
      // So: Running -> Pause -> Reset available.

      // Pause logic:
      _isTimerRunning = false;
      // Allow resuming? User said "when I stop it... button becomes reset".
      // This implies Pause is the "Stop" state.
      // We need to calculate remaining time accurately to resume or show it static.
      // _timerRemaining is already updated in _onTick.
      _timerEndTime = null;
      // Resume would need to set new EndTime based on current _timerRemaining.
    } else {
      // Start/Resume
      if (_timerRemaining == Duration.zero) {
        // If finished, reset to duration first?
        _timerRemaining = _timerDuration;
      }
      _isTimerRunning = true;
      _timerEndTime = DateTime.now().add(_timerRemaining);
    }
    notifyListeners();
  }

  void resetTimer() {
    _isTimerRunning = false;
    _timerEndTime = null;
    _timerRemaining = _timerDuration;
    notifyListeners();
  }
}
