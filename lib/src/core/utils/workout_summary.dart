import '../../models/session.dart';

/// Un esercizio della sessione, con quante serie sono finite sul totale.
///
/// Non porta pesi o ripetizioni: fino a US-083 una serie pianificata non ha
/// un formato unico da riassumere in una riga (a cedimento, per lato, a
/// piramide), e un numero sbagliato sullo scontrino sarebbe peggio di non
/// mostrarlo. Il conteggio delle serie invece e sempre corretto, per ogni
/// tipo di esercizio.
class ExerciseLine {
  const ExerciseLine({
    required this.name,
    required this.completedSets,
    required this.totalSets,
  });

  final String name;
  final int completedSets;
  final int totalSets;
}

/// Dati aggregati di una sessione di allenamento per la schermata di riepilogo.
///
/// Calcola volume totale, serie completate su totale, sforzo medio (RPE),
/// calorie e frequenza cardiaca media.
class WorkoutSummary {
  const WorkoutSummary({
    required this.workoutName,
    required this.startTime,
    this.endTime,
    required this.totalVolume,
    required this.completedSets,
    required this.totalSets,
    this.averageRpe,
    this.calories,
    this.avgHeartRate,
    this.exercises = const [],
  });

  final String workoutName;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalVolume;
  final int completedSets;
  final int totalSets;
  final double? averageRpe;
  final int? calories;
  final int? avgHeartRate;

  /// Gli esercizi della sessione, nell'ordine in cui sono stati eseguiti —
  /// l'elenco che fa riconoscere l'allenamento sullo scontrino, non solo
  /// quattro numeri aggregati.
  final List<ExerciseLine> exercises;

  /// Durata in minuti dell'allenamento.
  int get durationMinutes {
    if (endTime == null) return 0;
    final diff = endTime!.difference(startTime).inMinutes;
    return diff > 0 ? diff : 0;
  }

  /// Calcola il riepilogo da una [WorkoutSession].
  ///
  /// Regole:
  /// - Volume: somma di `peso × ripetizioni` per le sole serie completate (`isCompleted == true`).
  /// - Serie completate / totale: conta le serie con `isCompleted` su tutte le serie.
  /// - Sforzo medio: media degli RPE registrati (> 0); le serie senza RPE non abbassano la media.
  /// - Calorie e battito: se non presenti o zero, restituisce `null` (nessuna riga a zero).
  factory WorkoutSummary.of(
    WorkoutSession session, {
    int? calories,
    int? avgHeartRate,
  }) {
    double volume = 0;
    int completed = 0;
    int total = 0;
    double rpeSum = 0;
    int rpeCount = 0;
    double setCaloriesSum = 0;
    bool hasSetCalories = false;

    final exerciseLines = <ExerciseLine>[];

    for (final exercise in session.exercises) {
      var completedPerEsercizio = 0;
      for (final set in exercise.sets) {
        total++;
        if (set.isCompleted) {
          completed++;
          completedPerEsercizio++;
          if (set.weight > 0 && set.reps > 0) {
            // In `double` e arrotondato una volta sola alla fine: con `toInt()`
            // a ogni serie, 62,5 kg per 7 diventava 437 invece di 437,5. Con il
            // passo da 2,5 kg di US-046 i mezzi chili sono la norma, e su
            // diciotto serie si perdevano fino a nove chili.
            volume += set.weight * set.reps;
          }
        }
        if (set.rpe != null && set.rpe! > 0) {
          rpeSum += set.rpe!;
          rpeCount++;
        }
        if (set.calories != null && set.calories! > 0) {
          setCaloriesSum += set.calories!;
          hasSetCalories = true;
        }
      }
      if (exercise.sets.isNotEmpty) {
        exerciseLines.add(
          ExerciseLine(
            name: exercise.exerciseName,
            completedSets: completedPerEsercizio,
            totalSets: exercise.sets.length,
          ),
        );
      }
    }

    final computedCalories =
        calories ?? (hasSetCalories ? setCaloriesSum.round() : null);

    return WorkoutSummary(
      // Nessun ripiego qui: e un file di calcolo e non conosce la lingua.
      // Il nome mancante lo risolve chi disegna, con una chiave tradotta.
      workoutName: session.workoutName,
      startTime: session.startTime,
      endTime: session.endTime,
      totalVolume: volume.round(),
      completedSets: completed,
      totalSets: total,
      averageRpe: rpeCount > 0 ? (rpeSum / rpeCount) : null,
      calories:
          (computedCalories != null && computedCalories > 0)
              ? computedCalories
              : null,
      avgHeartRate:
          (avgHeartRate != null && avgHeartRate > 0) ? avgHeartRate : null,
      exercises: exerciseLines,
    );
  }
}
