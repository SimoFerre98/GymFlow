import 'package:flutter/foundation.dart';
import '../../models/session.dart';
import '../../models/workout.dart';

/// Periodo di filtro per il grafico di progressione.
enum ProgressionPeriod {
  oneMonth,
  threeMonths,
  all,
}

/// Punto nel grafico della progressione (carico massimo per sessione).
@immutable
class ProgressionPoint {
  const ProgressionPoint({
    required this.date,
    required this.weight,
    required this.reps,
    required this.sessionId,
  });

  final DateTime date;
  final double weight;
  final int reps;
  final String sessionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressionPoint &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          weight == other.weight &&
          reps == other.reps &&
          sessionId == other.sessionId;

  @override
  int get hashCode => Object.hash(date, weight, reps, sessionId);
}

/// Funzioni pure per calcolare l'andamento del carico massimo di un esercizio nel tempo.
abstract class ExerciseProgression {
  /// Filtra le sessioni e ricava i punti per il grafico di progressione dell'esercizio.
  ///
  /// Per ogni sessione contenente l'esercizio [exerciseId], seleziona la serie completata
  /// ([set.isCompleted == true], [set.weight > 0], [set.reps >= 1]) con il CARICO PIÙ ALTO.
  /// I pesi restano `double` senza perdere i decimali (es. 62.5 kg).
  ///
  /// Se [referenceDate] non è fornito, usa [DateTime.now()].
  static List<ProgressionPoint> calculateProgressionPoints({
    required List<WorkoutSession> sessions,
    required String exerciseId,
    required ProgressionPeriod period,
    DateTime? referenceDate,
  }) {
    final refDate = referenceDate ?? DateTime.now();

    final filteredByDate = sessions.where((session) {
      final startTime = session.startTime;
      return switch (period) {
        ProgressionPeriod.oneMonth =>
          startTime.isAfter(refDate.subtract(const Duration(days: 30))),
        ProgressionPeriod.threeMonths =>
          startTime.isAfter(refDate.subtract(const Duration(days: 90))),
        ProgressionPeriod.all => true,
      };
    });

    final points = <ProgressionPoint>[];

    for (final session in filteredByDate) {
      double maxWeight = 0.0;
      int maxReps = 0;
      bool foundValidSet = false;

      for (final ex in session.exercises) {
        if (ex.exerciseId == exerciseId) {
          for (final set in ex.sets) {
            if (set.isCompleted && set.weight > 0 && set.reps >= 1) {
              if (!foundValidSet ||
                  set.weight > maxWeight ||
                  (set.weight == maxWeight && set.reps > maxReps)) {
                maxWeight = set.weight;
                maxReps = set.reps;
                foundValidSet = true;
              }
            }
          }
        }
      }

      if (foundValidSet) {
        points.add(
          ProgressionPoint(
            date: session.startTime,
            weight: maxWeight,
            reps: maxReps,
            sessionId: session.id,
          ),
        );
      }
    }

    // Ordinati in ordine cronologico crescente
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// Trova l'ultima sessione (in ordine cronologico decrescente) che contiene l'esercizio.
  static WorkoutSession? getLastSession({
    required List<WorkoutSession> sessions,
    required String exerciseId,
  }) {
    final matchingSessions = sessions.where((session) {
      return session.exercises.any((ex) => ex.exerciseId == exerciseId);
    }).toList();

    if (matchingSessions.isEmpty) return null;

    matchingSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return matchingSessions.first;
  }

  /// Trova la combinazione di serie per l'esercizio nell'ultima sessione.
  static WorkoutExercise? getLastExerciseData({
    required WorkoutSession session,
    required String exerciseId,
  }) {
    for (final ex in session.exercises) {
      if (ex.exerciseId == exerciseId) {
        return ex;
      }
    }
    return null;
  }
}
