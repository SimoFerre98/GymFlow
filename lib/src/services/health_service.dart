import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  // Define data types to access
  static final List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType
        .BASAL_ENERGY_BURNED, // Added to ensure we capture all calories
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WEIGHT,
    HealthDataType.WATER,
  ];

  // Configure Health (Android specific mostly)
  Future<void> configure() async {
    await _health.configure();
  }

  Future<bool> requestPermissions() async {
    // Request permissions
    bool requested = await _health.requestAuthorization(_dataTypes);
    return requested;
  }

  /// I tipi che servono al pannello della sessione, calorie a parte il battito.
  static final List<HealthDataType> _liveCalorieTypes = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
  ];

  /// Se le calorie sono leggibili, cioe se il pannello dal vivo ha qualcosa da
  /// mostrare.
  ///
  /// Chiede solo i tipi che gli servono e non tutti e otto di [_dataTypes]: il
  /// pannello non deve invitare a concedere i permessi perche manca quello sul
  /// sonno o sul peso, che non mostra.
  Future<bool> hasLiveMetricsPermissions() async {
    try {
      final hasPerm = await _health.hasPermissions(_liveCalorieTypes);
      return hasPerm == true;
    } catch (_) {
      return false;
    }
  }

  /// Se il battito e leggibile.
  ///
  /// **Non dice se il dispositivo ha un sensore di battito**, e non e un
  /// dettaglio: `health` 13.3.0 non lo espone. `isDataTypeAvailable` risponde
  /// per la piattaforma e non per il dispositivo, e su Android `HEART_RATE` e
  /// sempre nell'elenco, quindi direbbe sempre si. Verificato nel sorgente del
  /// pacchetto, non dedotto.
  ///
  /// Quello che si puo sapere da Dart e se il permesso sul battito c'e. Un
  /// dispositivo senza sensore ma con il permesso concesso mostra la tessera
  /// con «—», cioe «non lo so»: non mostra mai uno zero, che e il caso che il
  /// criterio della storia vuole evitare.
  Future<bool> hasHeartRateAccess() async {
    try {
      final hasPerm = await _health.hasPermissions([HealthDataType.HEART_RATE]);
      return hasPerm == true;
    } catch (_) {
      return false;
    }
  }

  /// Legge i campioni di calorie e battito cardiaco nell'intervallo specificato.
  Future<Map<String, dynamic>> fetchLiveMetrics({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        startTime: startTime,
        endTime: endTime,
        types: [
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.BASAL_ENERGY_BURNED,
          HealthDataType.HEART_RATE,
        ],
      );

      double? calories;
      int? lastHeartRate;

      for (var point in healthData) {
        if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED ||
            point.type == HealthDataType.BASAL_ENERGY_BURNED) {
          if (point.value is NumericHealthValue) {
            final val =
                (point.value as NumericHealthValue).numericValue.toDouble();
            calories = (calories ?? 0) + val;
          }
        } else if (point.type == HealthDataType.HEART_RATE) {
          if (point.value is NumericHealthValue) {
            lastHeartRate =
                (point.value as NumericHealthValue).numericValue.toInt();
          }
        }
      }

      return {
        'calories': calories,
        'heartRate': lastHeartRate,
      };
    } catch (_) {
      return {
        'calories': null,
        'heartRate': null,
      };
    }
  }

  Future<Map<String, dynamic>> fetchDailySummary() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    // Fetch data

    // 1. Steps (Cumulative for today)
    int? steps = await _health.getTotalStepsInInterval(midnight, now);

    // Others
    List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
      startTime: midnight,
      endTime: now,
      types: [
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.WATER,
        HealthDataType.HEART_RATE,
      ],
    );

    double calories = 0;
    double distance = 0;
    double water = 0;
    int heartRateSum = 0;
    int heartRateCount = 0;
    int lastHeartRate = 0;

    for (var point in healthData) {
      if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        final val = point.value as NumericHealthValue;
        calories += val.numericValue.toDouble();
      } else if (point.type == HealthDataType.BASAL_ENERGY_BURNED) {
        final val = point.value as NumericHealthValue;
        calories += val.numericValue.toDouble();
      } else if (point.type == HealthDataType.DISTANCE_DELTA) {
        final val = point.value as NumericHealthValue;
        distance += val.numericValue.toDouble();
      } else if (point.type == HealthDataType.WATER) {
        final val = point.value as NumericHealthValue;
        water += val.numericValue.toDouble();
      } else if (point.type == HealthDataType.HEART_RATE) {
        final val = point.value as NumericHealthValue;
        heartRateSum += val.numericValue.toInt();
        heartRateCount++;
        lastHeartRate = val.numericValue.toInt();
      }
    }

    // Weight (Fetch latest available)
    List<HealthDataPoint> weightData = await _health.getHealthDataFromTypes(
      startTime: now.subtract(const Duration(days: 30)),
      endTime: now,
      types: [HealthDataType.WEIGHT],
    );
    double? lastWeight;
    if (weightData.isNotEmpty) {
      weightData.sort((a, b) => b.dateTo.compareTo(a.dateTo)); // Newest first
      lastWeight = (weightData.first.value as NumericHealthValue).numericValue
          .toDouble();
    }

    // Sleep
    final sleepStart = now.subtract(const Duration(hours: 24));
    List<HealthDataPoint> sleepData = await _health.getHealthDataFromTypes(
      startTime: sleepStart,
      endTime: now,
      types: [HealthDataType.SLEEP_SESSION],
    );

    int sleepMinutes = 0;
    for (var point in sleepData) {
      final duration = point.dateTo.difference(point.dateFrom).inMinutes;
      sleepMinutes += duration;
    }

    return {
      'steps': steps ?? 0,
      'calories': calories,
      'distance': distance, // Meters
      'heartRate': lastHeartRate, // Last recorded
      'avgHeartRate': heartRateCount > 0
          ? (heartRateSum / heartRateCount).round()
          : 0,
      'water': water, // Liters
      'weight': lastWeight,
      'sleepMinutes': sleepMinutes,
    };
  }

  /// Fetches historical data for a specific type and range, aggregated by day.
  /// Returns a Map where key is DateTime (midnight) and value is the aggregated value (double).
  Future<Map<DateTime, double>> fetchHistoricalData(
    HealthDataType type,
    DateTime start,
    DateTime end,
  ) async {
    // Ensure we fetch generic data points
    List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end.add(const Duration(days: 1)), // Add 1 day buffer to be safe
      types: [type],
    );

    // Filter duplicates via Health library internal logic usually handles it, but verify
    // data = HealthFactory.removeDuplicates(data); // Removed as HealthFactory is undefined in this version

    Map<DateTime, double> dailyData = {};
    Map<DateTime, int> dailyCounts = {}; // For averaging

    for (var point in data) {
      // Normalize to midnight
      DateTime date = point.dateTo;
      // Use dateTo usually better for "when did it happen"
      DateTime midnight = DateTime(date.year, date.month, date.day);

      // If outside requested range, skip (buffer checking)
      if (midnight.isBefore(DateTime(start.year, start.month, start.day)) ||
          midnight.isAfter(end)) {
        continue;
      }

      double value = 0.0;
      if (point.value is NumericHealthValue) {
        value = (point.value as NumericHealthValue).numericValue.toDouble();
      }

      if (type == HealthDataType.STEPS ||
          type == HealthDataType.ACTIVE_ENERGY_BURNED ||
          type == HealthDataType.BASAL_ENERGY_BURNED ||
          type == HealthDataType.DISTANCE_DELTA ||
          type == HealthDataType.WATER) {
        // SUM
        dailyData[midnight] = (dailyData[midnight] ?? 0) + value;
      } else if (type == HealthDataType.SLEEP_SESSION) {
        // SUM minutes
        final duration = point.dateTo.difference(point.dateFrom).inMinutes;
        dailyData[midnight] = (dailyData[midnight] ?? 0) + duration;
      } else if (type == HealthDataType.HEART_RATE ||
          type == HealthDataType.WEIGHT) {
        // AVERAGE (Accumulate sum and count)
        dailyData[midnight] = (dailyData[midnight] ?? 0) + value;
        dailyCounts[midnight] = (dailyCounts[midnight] ?? 0) + 1;
      }
    }

    // Post-process Average
    if (type == HealthDataType.HEART_RATE || type == HealthDataType.WEIGHT) {
      dailyData.forEach((key, value) {
        if (dailyCounts.containsKey(key) && dailyCounts[key]! > 0) {
          dailyData[key] = value / dailyCounts[key]!;
        }
      });
    }

    return dailyData;
  }
}
