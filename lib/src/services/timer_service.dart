import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timer_service.g.dart';

/// 100 ms — i decimi di secondo sono la cifra piu fine che lo schermo mostra
/// (`time_tools_screen.dart`), quindi aggiornare piu spesso ridisegna senza
/// cambiare niente.
const Duration kTickerInterval = Duration(milliseconds: 100);

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
/// Da quando comincia il conto alla rovescia sentito: gli ultimi tre secondi.
const Duration kSecondiDiAvviso = Duration(seconds: 3);

abstract class AvvisiTempo {
  /// Uno degli ultimi secondi e passato.
  void secondoFinale();

  /// Il tempo e scaduto.
  void scaduto();
}

/// Quello vero: la vibrazione e il suono del sistema.
///
/// Nessuna dipendenza nuova. `HapticFeedback.vibrate()` e non `heavyImpact()`:
/// verificato nel sorgente di Flutter (`haptic_feedback.dart`), su Android
/// `heavyImpact` diventa `HapticFeedbackConstants.CONTEXT_CLICK` — pensato per
/// il click destro del mouse, quasi impercettibile su un telefono — mentre
/// `vibrate()` diventa `LONG_PRESS`, un impulso piu lungo e piu netto. Sono
/// comunque due colpi brevi tarati dal produttore, non un'ampiezza
/// controllabile: se anche `vibrate()` risulta moscio, l'unica strada resta una
/// dipendenza che comandi il motore di vibrazione direttamente.
class AvvisiTempoDiSistema implements AvvisiTempo {
  const AvvisiTempoDiSistema();

  @override
  void secondoFinale() => HapticFeedback.vibrate();

  @override
  void scaduto() {
    // Il suono e la vibrazione insieme: in palestra la cuffia puo essere
    // occupata dalla musica e il telefono in tasca.
    SystemSound.play(SystemSoundType.alert);
    // Due colpi vicini invece di uno: `vibrate()` e gia il piu forte
    // disponibile senza dipendenze, e un singolo LONG_PRESS resta breve. La
    // scadenza e il momento che conta di piu — deve notarsi anche col telefono
    // in tasca — quindi qui si raddoppia.
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 120), HapticFeedback.vibrate);
  }
}

///
/// Il ticker gira a 100 ms ed e attivo solo quando serve.
@Riverpod(keepAlive: true)
/// Il ritorno fisico del conto alla rovescia: vibra e suona.
///
/// È un'interfaccia e non due chiamate sparse nel ticker per una ragione sola:
/// `HapticFeedback` e `SystemSound` parlano con un canale di piattaforma che in
/// un test non esiste, e senza poterli sostituire «vibra negli ultimi tre
/// secondi» non sarebbe dimostrabile — resterebbe una cosa da provare a mano
/// ogni volta.
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

  /// Se il ticker sta battendo.
  ///
  /// Esiste perche altrimenti «il ticker non parte nel costruttore» non e
  /// verificabile: appoggiarsi al fatto che `testWidgets` protesti per i timer
  /// pendenti non basta, perche smontare il container li cancella comunque e il
  /// test passerebbe anche col difetto. Verificato: rimettendo l'avvio dentro
  /// `build()`, senza questo getter la suite restava verde.
  bool get isTickerActive => _ticker != null;

  /// Chi vibra e chi suona. Sostituibile nei test.
  AvvisiTempo avvisi = const AvvisiTempoDiSistema();

  /// L'ultimo secondo per cui si e gia vibrato.
  ///
  /// Il ticker batte molto piu spesso di una volta al secondo: senza ricordare
  /// l'ultimo, negli ultimi tre secondi il telefono vibrerebbe a ogni battito.
  int? _ultimoSecondoAvvisato;

  /// Il ticker serve solo se c'e qualcosa che scorre.
  void _syncTicker() {
    final serve = state.isStopwatchRunning || state.isTimerRunning;
    if (serve && _ticker == null) {
      _ticker = Timer.periodic(kTickerInterval, _onTick);
    } else if (!serve && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  void _onTick(Timer _) {
    var next = state;
    var changed = false;
    var timerReachedZero = false;

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
        timerReachedZero = true;
      } else {
        next = next.copyWith(timerRemaining: remaining);
        avvisaSeUltimiSecondi(remaining);
      }
      changed = true;
    }

    if (changed) state = next;
    if (timerReachedZero) {
      segnalaScadenza();
      _syncTicker();
    }
  }

  /// Una vibrazione per ognuno degli ultimi tre secondi.
  ///
  /// Si conta il secondo **intero** che sta per finire: a 2,4 secondi dalla fine
  /// il secondo e il terzo, e si vibra una volta sola finche non diventa il
  /// secondo. Cosi i colpi sono tre, uno al secondo, e non uno per battito del
  /// ticker.
  @visibleForTesting
  void avvisaSeUltimiSecondi(Duration restante) {
    if (restante > kSecondiDiAvviso) {
      _ultimoSecondoAvvisato = null;
      return;
    }
    final secondo = restante.inSeconds;
    if (_ultimoSecondoAvvisato == secondo) return;
    _ultimoSecondoAvvisato = secondo;
    avvisi.secondoFinale();
  }

  /// Il tempo e finito: si suona, e il conto delle vibrazioni riparte.
  @visibleForTesting
  void segnalaScadenza() {
    _ultimoSecondoAvvisato = null;
    avvisi.scaduto();
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
      // Il valore mostrato si allinea al tempo vero **nel momento della pausa**,
      // e non resta quello dell'ultimo tick.
      //
      // Con il ticker a 30 ms lo scarto era invisibile; a 100 ms puo essere di
      // un decimo intero, cioe esattamente la cifra piu fine che lo schermo
      // mostra: il cronometro si fermerebbe su un numero diverso da quello
      // raggiunto, e sarebbe quello registrato dai giri.
      state = state.copyWith(
        isStopwatchRunning: false,
        stopwatchElapsed: _stopwatchOffset,
      );
    } else {
      _stopwatchStartedAt = DateTime.now();
      state = state.copyWith(isStopwatchRunning: true);
    }
    _syncTicker();
  }

  void resetStopwatch() {
    _stopwatchStartedAt = null;
    _stopwatchOffset = Duration.zero;
    state = state.copyWith(
      isStopwatchRunning: false,
      stopwatchElapsed: Duration.zero,
      stopwatchLaps: const [],
    );
    _syncTicker();
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
    _syncTicker();
  }

  void resetTimer() {
    _timerEndsAt = null;
    state = state.copyWith(
      isTimerRunning: false,
      timerRemaining: state.timerDuration,
    );
    _syncTicker();
  }
}
