import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  // Define data types to access
  static final List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
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
