import 'package:flutter/foundation.dart';
import '../../models/session.dart';
import '../../models/workout.dart';

/// Un record personale storico su un esercizio.
@immutable
class PersonalBest {
  const PersonalBest({
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
  });

  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalBest &&
          runtimeType == other.runtimeType &&
          exerciseId == other.exerciseId &&
          weight == other.weight &&
          reps == other.reps &&
          date == other.date;

  @override
  int get hashCode => Object.hash(exerciseId, weight, reps, date);
}

/// Il miglioramento rispetto al massimo storico precedente.
@immutable
class PersonalRecord {
  const PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.newWeight,
    required this.newReps,
    required this.previousWeight,
    this.previousReps,
    this.previousDate,
  });

  final String exerciseId;
  final String exerciseName;
  final double newWeight;
  final int newReps;
  final double previousWeight;
  final int? previousReps;
  final DateTime? previousDate;

  double get diffWeight => newWeight - previousWeight;

  /// Riconosce un record personale.
  ///
  /// Regola: è record il carico più alto mai sollevato per almeno una ripetizione.
  /// Non il volume, non il massimale stimato.
  ///
  /// Casi trattati:
  /// - storia vuota → non è un record (il primo allenamento non è un miglioramento)
  /// - pareggio → non è un record (stesso carico non supera)
  /// - stesso carico con più ripetizioni → non è un record di carico
  /// - carico a zero (corpo libero) → mai un record di carico
  /// - ripetizioni < 1 o serie non valida → mai un record
  static PersonalRecord? detect({
    required String exerciseId,
    String exerciseName = '',
    required WorkoutSet candidate,
    required List<WorkoutSet> history,
    DateTime? previousDate,
    int? previousReps,
  }) {
    if (candidate.weight <= 0 || candidate.reps < 1) return null;

    final validHistory =
        history.where((s) => s.weight > 0 && s.reps >= 1).toList();
    if (validHistory.isEmpty) return null;

    var maxWeight = 0.0;
    int? maxReps;
    for (final set in validHistory) {
      if (set.weight > maxWeight) {
        maxWeight = set.weight;
        maxReps = set.reps;
      }
    }

    if (maxWeight <= 0) return null;
    if (candidate.weight <= maxWeight) return null;

    return PersonalRecord(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      newWeight: candidate.weight,
      newReps: candidate.reps,
      previousWeight: maxWeight,
      previousReps: previousReps ?? maxReps,
      previousDate: previousDate,
    );
  }

  /// Riconosce un record partendo da un [PersonalBest] precedente.
  static PersonalRecord? detectFromBest({
    required String exerciseId,
    String exerciseName = '',
    required WorkoutSet candidate,
    required PersonalBest? previousBest,
  }) {
    if (previousBest == null) return null;
    if (candidate.weight <= 0 || candidate.reps < 1) return null;
    if (previousBest.weight <= 0) return null;
    if (candidate.weight <= previousBest.weight) return null;

    return PersonalRecord(
      exerciseId: exerciseId,
      exerciseName:
          exerciseName.isNotEmpty ? exerciseName : previousBest.exerciseName,
      newWeight: candidate.weight,
      newReps: candidate.reps,
      previousWeight: previousBest.weight,
      previousReps: previousBest.reps,
      previousDate: previousBest.date,
    );
  }

  /// Calcola i massimi storici per ogni esercizio da tutte le sessioni passate.
  static Map<String, PersonalBest> calculatePersonalBests(
    List<WorkoutSession> sessions,
  ) {
    final map = <String, PersonalBest>{};

    final sorted = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final session in sorted) {
      for (final ex in session.exercises) {
        for (final set in ex.sets) {
          if (set.isCompleted && set.weight > 0 && set.reps >= 1) {
            final current = map[ex.exerciseId];
            if (current == null || set.weight > current.weight) {
              map[ex.exerciseId] = PersonalBest(
                exerciseId: ex.exerciseId,
                exerciseName: ex.exerciseName,
                weight: set.weight,
                reps: set.reps,
                date: session.startTime,
              );
            }
          }
        }
      }
    }

    return map;
  }

  /// Riconosce tutti i record battuti in una specifica sessione rispetto allo storico precedente.
  static List<PersonalRecord> detectSessionRecords({
    required WorkoutSession session,
    required List<WorkoutSession> allSessions,
  }) {
    final priorSessions = allSessions
        .where(
          (s) =>
              s.id != session.id &&
              (s.startTime.isBefore(session.startTime) ||
                  (s.startTime.isAtSameMomentAs(session.startTime) &&
                      s.id.compareTo(session.id) < 0)),
        )
        .toList();

    final priorBests = calculatePersonalBests(priorSessions);
    final records = <PersonalRecord>[];

    for (final ex in session.exercises) {
      final priorBest = priorBests[ex.exerciseId];
      if (priorBest == null) continue;

      WorkoutSet? bestSet;
      for (final set in ex.sets) {
        if (set.isCompleted && set.weight > 0 && set.reps >= 1) {
          if (bestSet == null || set.weight > bestSet.weight) {
            bestSet = set;
          }
        }
      }

      if (bestSet != null) {
        final record = detectFromBest(
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          candidate: bestSet,
          previousBest: priorBest,
        );
        if (record != null) {
          records.add(record);
        }
      }
    }

    return records;
  }
}
