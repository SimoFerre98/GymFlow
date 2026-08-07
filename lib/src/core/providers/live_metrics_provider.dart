import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/health_service.dart';

part 'live_metrics_provider.g.dart';

/// Periodo di campionamento delle metriche dal vivo durante la sessione.
///
/// 30 secondi: un intervallo inferiore consumerebbe batteria senza che i
/// sensori producano nuovi campioni significativi; un intervallo superiore
/// farebbe sembrare bloccato il valore a schermo.
const Duration kLiveMetricsInterval = Duration(seconds: 30);

/// Numero massimo di campioni storici mantenuti per il tracciamento della sparkline.
const int kMaxRecentSamples = 20;

/// Stato delle metriche dal vivo (calorie bruciate e battito cardiaco).
@immutable
class LiveMetricsState {
  const LiveMetricsState({
    this.hasPermission = true,
    this.canReadHeartRate = true,
    this.calories,
    this.heartRate,
    this.calorieHistory = const [],
    this.heartRateHistory = const [],
    this.isLoading = false,
  });

  /// Indica se l'app dispone dei permessi per accedere a Health Connect / Apple Health.
  final bool hasPermission;

  /// Indica se il battito e leggibile: senza, la tessera del battito non
  /// compare. Non dice che il dispositivo non ha un sensore — vedi
  /// `HealthService.hasHeartRateAccess`.
  final bool canReadHeartRate;

  /// Calorie bruciate durante la sessione in corso (null se dato non ancora disponibile).
  final double? calories;

  /// Ultima rilevazione del battito cardiaco in bpm (null se dato non ancora disponibile).
  final int? heartRate;

  /// Finestra recente dei campioni di calorie per la sparkline.
  final List<double> calorieHistory;

  /// Finestra recente dei campioni di frequenza cardiaca per la sparkline.
  final List<double> heartRateHistory;

  /// Flag di caricamento iniziale.
  final bool isLoading;

  /// Una lettura che non porta valori **non azzera** quelli mostrati: le
  /// calorie di sessione sono cumulative, e un errore di rete o un campione in
  /// ritardo non significa che l'atleta ne abbia bruciate meno. Il valore
  /// resta l'ultimo noto finche la sessione non finisce.
  LiveMetricsState copyWith({
    bool? hasPermission,
    bool? canReadHeartRate,
    double? calories,
    int? heartRate,
    List<double>? calorieHistory,
    List<double>? heartRateHistory,
    bool? isLoading,
  }) {
    return LiveMetricsState(
      hasPermission: hasPermission ?? this.hasPermission,
      canReadHeartRate: canReadHeartRate ?? this.canReadHeartRate,
      calories: calories ?? this.calories,
      heartRate: heartRate ?? this.heartRate,
      calorieHistory: calorieHistory ?? this.calorieHistory,
      heartRateHistory: heartRateHistory ?? this.heartRateHistory,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveMetricsState &&
          runtimeType == other.runtimeType &&
          hasPermission == other.hasPermission &&
          canReadHeartRate == other.canReadHeartRate &&
          calories == other.calories &&
          heartRate == other.heartRate &&
          listEquals(calorieHistory, other.calorieHistory) &&
          listEquals(heartRateHistory, other.heartRateHistory) &&
          isLoading == other.isLoading;

  @override
  int get hashCode => Object.hash(
        hasPermission,
        canReadHeartRate,
        calories,
        heartRate,
        Object.hashAll(calorieHistory),
        Object.hashAll(heartRateHistory),
        isLoading,
      );
}

/// Espone l'istanza del servizio Salute.
@riverpod
class HealthServiceProvider extends _$HealthServiceProvider {
  @override
  HealthService build() => HealthService();
}

/// Gestisce l'acquisizione periodica delle metriche dal vivo durante l'allenamento.
///
/// Trattandosi di un provider `autoDispose`, quando l'utente lascia la schermata di
/// sessione attiva, la sottoscrizione e il timer periodico vengono automaticamente
/// annullati senza perdite di memoria.
@riverpod
class LiveMetricsNotifier extends _$LiveMetricsNotifier {
  Timer? _timer;
  DateTime? _startTime;
  bool _mounted = true;

  @override
  LiveMetricsState build() {
    _startTime = DateTime.now();
    _mounted = true;

    ref.onDispose(() {
      _mounted = false;
      _timer?.cancel();
      _timer = null;
    });

    _init();

    return const LiveMetricsState(isLoading: true);
  }

  Future<void> _init() async {
    if (!_mounted) return;
    final service = ref.read(healthServiceProvider);

    final hasPerm = await service.hasLiveMetricsPermissions();
    if (!_mounted) return;
    if (!hasPerm) {
      state = state.copyWith(
        hasPermission: false,
        isLoading: false,
      );
      return;
    }

    final canReadHr = await service.hasHeartRateAccess();
    if (!_mounted) return;

    state = state.copyWith(
      hasPermission: true,
      canReadHeartRate: canReadHr,
      isLoading: false,
    );

    await refresh();
    if (!_mounted) return;

    _timer?.cancel();
    _timer = Timer.periodic(kLiveMetricsInterval, (_) {
      refresh();
    });
  }

  /// Imposta l'orario di inizio sessione.
  void setSessionStartTime(DateTime startTime) {
    _startTime = startTime;
  }

  /// Esegue una nuova lettura delle metriche e aggiorna lo storico recente.
  Future<void> refresh() async {
    if (!_mounted) return;
    final service = ref.read(healthServiceProvider);

    final hasPerm = await service.hasLiveMetricsPermissions();
    if (!_mounted) return;
    if (!hasPerm) {
      state = state.copyWith(hasPermission: false);
      return;
    }

    final canReadHr = await service.hasHeartRateAccess();
    if (!_mounted) return;
    final now = DateTime.now();
    final start = _startTime ?? now.subtract(const Duration(minutes: 30));

    final metrics = await service.fetchLiveMetrics(
      startTime: start,
      endTime: now,
    );
    if (!_mounted) return;

    final rawCalories = metrics['calories'];
    final double? newCalories =
        rawCalories != null ? (rawCalories as num).toDouble() : null;

    final rawHr = metrics['heartRate'];
    final int? newHeartRate =
        rawHr != null ? (rawHr as num).toInt() : null;

    final updatedCalorieHistory = List<double>.from(state.calorieHistory);
    if (newCalories != null) {
      updatedCalorieHistory.add(newCalories);
      if (updatedCalorieHistory.length > kMaxRecentSamples) {
        updatedCalorieHistory.removeAt(0);
      }
    }

    final updatedHeartRateHistory = List<double>.from(state.heartRateHistory);
    if (newHeartRate != null) {
      updatedHeartRateHistory.add(newHeartRate.toDouble());
      if (updatedHeartRateHistory.length > kMaxRecentSamples) {
        updatedHeartRateHistory.removeAt(0);
      }
    }

    state = state.copyWith(
      hasPermission: true,
      canReadHeartRate: canReadHr,
      calories: newCalories,
      heartRate: newHeartRate,
      calorieHistory: updatedCalorieHistory,
      heartRateHistory: updatedHeartRateHistory,
      isLoading: false,
    );
  }

  /// Richiede all'utente i permessi per accedere ai dati sanitari.
  Future<void> requestPermissions() async {
    if (!_mounted) return;
    final service = ref.read(healthServiceProvider);
    final granted = await service.requestPermissions();
    if (!_mounted) return;
    if (granted) {
      state = state.copyWith(hasPermission: true);
      await _init();
    }
  }
}
