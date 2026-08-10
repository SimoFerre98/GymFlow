import '../../models/session.dart';

class StatisticsHelper {
  /// Restituisce una mappa `{indice del giorno (1-7): conteggio}` per la
  /// settimana corrente, da lunedi a domenica.
  static Map<int, int> getWeeklyWorkoutCounts(List<WorkoutSession> sessions) {
    // Get the start of the current week (Monday)
    final now = DateTime.now();
    // Monday = 1, Sunday = 7
    final startOfWeek = now
        .subtract(Duration(days: now.weekday - 1))
        .copyWith(
          hour: 0,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    // Initialize counts for Mon(1) to Sun(7)
    final Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

    for (var session in sessions) {
      if (session.startTime.isAfter(startOfWeek) &&
          session.startTime.isBefore(endOfWeek)) {
        final day = session.startTime.weekday;
        counts[day] = (counts[day] ?? 0) + 1;
      }
    }
    return counts;
  }

  static int calculateCurrentStreak(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 0;

    // Sort sessions by date descending
    final sorted = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    int streak = 0;
    final today = DateTime.now();
    // Normalize to date only
    DateTime lastDate = DateTime(today.year, today.month, today.day);

    // Check if we worked out today
    final latestSessionDate = DateTime(
      sorted.first.startTime.year,
      sorted.first.startTime.month,
      sorted.first.startTime.day,
    );

    if (latestSessionDate.isAtSameMomentAs(lastDate)) {
      // Worked out today
    } else {
      // If no workout today, check if the last workout was yesterday to keep streak alive
      final yesterday = lastDate.subtract(const Duration(days: 1));
      if (latestSessionDate.isAtSameMomentAs(yesterday)) {
        // Continue
      } else if (latestSessionDate.isBefore(yesterday)) {
        return 0; // Streak broken
      }
    }

    DateTime? previousDate;

    for (var session in sorted) {
      final date = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );

      if (previousDate == null) {
        // First one
        streak = 1;
        previousDate = date;
        continue;
      }

      if (date.isAtSameMomentAs(previousDate)) {
        continue; // Same day, ignore
      }

      final diff = previousDate.difference(date).inDays;
      if (diff == 1) {
        streak++;
        previousDate = date;
      } else {
        break; // Streak broken
      }
    }

    return streak;
  }

  static int calculateTotalVolume(List<WorkoutSession> sessions) {
    // Si somma in `double` e si arrotonda **una volta sola**, alla fine.
    //
    // Prima il `toInt()` stava dentro il ciclo, quindi troncava a ogni serie: con
    // il passo da 2,5 kg dei cursori di US-046 i mezzi chili sono la norma, non
    // l'eccezione, e 62,5 x 3 contava 187 invece di 187,5. L'errore si accumulava
    // su tutto lo storico, sempre verso il basso.
    //
    // E il troncamento per serie che la review di US-049 aveva corretto nel
    // riepilogo di fine allenamento: qui era sopravvissuto perche sono due
    // calcoli diversi, e nessun test lo prendeva perche usano tutti pesi interi.
    double volume = 0;
    for (var session in sessions) {
      for (var exercise in session.exercises) {
        for (var set in exercise.sets) {
          if (set.isCompleted && set.weight != null && set.reps != null) {
            volume += set.weight * set.reps;
          }
        }
      }
    }
    return volume.round();
  }

  static double calculateAverageRPE(List<WorkoutSession> sessions) {
    double totalRPE = 0;
    int rpeCount = 0;

    for (var session in sessions) {
      for (var exercise in session.exercises) {
        for (var set in exercise.sets) {
          if (set.rpe != null && set.rpe! > 0) {
            totalRPE += set.rpe!;
            rpeCount++;
          }
        }
      }
    }

    if (rpeCount == 0) return 0.0;
    return totalRPE / rpeCount;
  }

  static Map<String, int> getWorkoutTypeDistribution(
    List<WorkoutSession> sessions,
  ) {
    final Map<String, int> distribution = {};
    for (var session in sessions) {
      final type = session.workoutType;
      // Capitalize first letter
      final key = type.isNotEmpty
          ? '${type[0].toUpperCase()}${type.substring(1)}'
          : 'Other';

      distribution[key] = (distribution[key] ?? 0) + 1;
    }
    return distribution;
  }
}
