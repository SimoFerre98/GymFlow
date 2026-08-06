import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timer_service.g.dart';

/// Stato osservabile di cronometro e timer.
@immutable
class TimerState {
  const TimerState({
    this.stopwatchElapsed = Duration.zero,
    this.isStopwatchRunning = false,
    this.stopwatchLaps = const [],
    this.timerDuration = const Duration(minutes: 5),
    this.timerRemaining = const Duration(minutes: 5),
    this.isTimerRunning = false,
    this.isToolsVisible = false,
  });

  final Duration stopwatchElapsed;
  final bool isStopwatchRunning;
  final List<Duration> stopwatchLaps;

  final Duration timerDuration;
  final Duration timerRemaining;
  final bool isTimerRunning;

  /// Vero quando la schermata degli strumenti e aperta: in quel caso
  /// l'overlay flottante resta nascosto per non duplicare i comandi.
  final bool isToolsVisible;

  TimerState copyWith({
    Duration? stopwatchElapsed,
    bool? isStopwatchRunning,
    List<Duration>? stopwatchLaps,
    Duration? timerDuration,
    Duration? timerRemaining,
    bool? isTimerRunning,
    bool? isToolsVisible,
  }) {
    return TimerState(
      stopwatchElapsed: stopwatchElapsed ?? this.stopwatchElapsed,
      isStopwatchRunning: isStopwatchRunning ?? this.isStopwatchRunning,
      stopwatchLaps: stopwatchLaps ?? this.stopwatchLaps,
      timerDuration: timerDuration ?? this.timerDuration,
      timerRemaining: timerRemaining ?? this.timerRemaining,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isToolsVisible: isToolsVisible ?? this.isToolsVisible,
    );
  }
}

/// Cronometro e timer da conto alla rovescia, condivisi da tutta l'app.
///
/// keepAlive perche devono continuare a scorrere anche quando l'utente lascia
/// la schermata degli strumenti: e il presupposto dell'overlay flottante.
///
/// Il ticker gira a 30 ms ed e sempre attivo, come nella versione precedente.
/// Fermarlo quando cronometro e timer sono inattivi e compito di US-013:
/// cambiarlo qui renderebbe indistinguibile una regressione della migrazione
/// da un cambio voluto di comportamento.
@Riverpod(keepAlive: true)
class TimerNotifier extends _$TimerNotifier {
  Timer? _ticker;

  /// Istante di avvio dell'ultima corsa del cronometro.
  DateTime? _stopwatchStartedAt;

  /// Tempo accumulato nelle corse precedenti, prima dell'ultima pausa.
  Duration _stopwatchOffset = Duration.zero;

  /// Istante in cui il conto alla rovescia raggiungera lo zero.
  DateTime? _timerEndsAt;

  @override
  TimerState build() {
    _ticker = Timer.periodic(const Duration(milliseconds: 30), _onTick);
    ref.onDispose(() {
      _ticker?.cancel();
      _ticker = null;
    });
    return const TimerState();
  }

  // Getter di comodo: permettono ai consumatori di usare il notifier come
  // usavano il servizio, senza distinguere fra lettura e comando.
  Duration get stopwatchElapsed => state.stopwatchElapsed;
  bool get isStopwatchRunning => state.isStopwatchRunning;
  List<Duration> get stopwatchLaps => List.unmodifiable(state.stopwatchLaps);
  Duration get timerDuration => state.timerDuration;
  Duration get timerRemaining => state.timerRemaining;
  bool get isTimerRunning => state.isTimerRunning;
  bool get isToolsVisible => state.isToolsVisible;

  void _onTick(Timer _) {
    var next = state;
    var changed = false;

    if (state.isStopwatchRunning && _stopwatchStartedAt != null) {
      next = next.copyWith(
        stopwatchElapsed:
            _stopwatchOffset + DateTime.now().difference(_stopwatchStartedAt!),
      );
      changed = true;
    }

    if (state.isTimerRunning && _timerEndsAt != null) {
      final remaining = _timerEndsAt!.difference(DateTime.now());
      if (remaining.isNegative) {
        _timerEndsAt = null;
        next = next.copyWith(
          timerRemaining: Duration.zero,
          isTimerRunning: false,
        );
      } else {
        next = next.copyWith(timerRemaining: remaining);
      }
      changed = true;
    }

    if (changed) state = next;
  }

  void setToolsVisible(bool visible) {
    state = state.copyWith(isToolsVisible: visible);
  }

  // --- Cronometro ---

  void toggleStopwatch() {
    if (state.isStopwatchRunning) {
      if (_stopwatchStartedAt != null) {
        _stopwatchOffset += DateTime.now().difference(_stopwatchStartedAt!);
        _stopwatchStartedAt = null;
      }
      state = state.copyWith(isStopwatchRunning: false);
    } else {
      _stopwatchStartedAt = DateTime.now();
      state = state.copyWith(isStopwatchRunning: true);
    }
  }

  void resetStopwatch() {
    _stopwatchStartedAt = null;
    _stopwatchOffset = Duration.zero;
    state = state.copyWith(
      isStopwatchRunning: false,
      stopwatchElapsed: Duration.zero,
      stopwatchLaps: const [],
    );
  }

  void lapStopwatch() {
    if (state.stopwatchElapsed == Duration.zero) return;
    state = state.copyWith(
      stopwatchLaps: [state.stopwatchElapsed, ...state.stopwatchLaps],
    );
  }

  // --- Timer da conto alla rovescia ---

  void setTimerDuration(Duration d) {
    if (state.isTimerRunning) return; // non si cambia mentre scorre
    state = state.copyWith(timerDuration: d, timerRemaining: d);
  }

  void toggleTimer() {
    if (state.isTimerRunning) {
      // In pausa: il tempo rimanente e gia aggiornato dal ticker.
      _timerEndsAt = null;
      state = state.copyWith(isTimerRunning: false);
    } else {
      final remaining = state.timerRemaining == Duration.zero
          ? state.timerDuration
          : state.timerRemaining;
      _timerEndsAt = DateTime.now().add(remaining);
      state = state.copyWith(isTimerRunning: true, timerRemaining: remaining);
    }
  }

  void resetTimer() {
    _timerEndsAt = null;
    state = state.copyWith(
      isTimerRunning: false,
      timerRemaining: state.timerDuration,
    );
  }
}
