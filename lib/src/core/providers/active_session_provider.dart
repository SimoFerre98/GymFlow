import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gymflow/src/models/workout.dart';

part 'active_session_provider.g.dart';

/// Stato di una sessione di allenamento in corso.
@immutable
class ActiveSessionState {
  const ActiveSessionState({
    this.workout,
    this.sessionExercises = const [],
    this.startedAt,
    this.scheduledWorkoutId,
  });

  final WorkoutTemplate? workout;
  final List<WorkoutExercise> sessionExercises;
  final DateTime? startedAt;
  final String? scheduledWorkoutId;

  /// Restituisce true se c'è un allenamento avviato e in corso.
  bool get isActive => workout != null && startedAt != null;

  /// Tempo totale trascorso dall'inizio reale della sessione.
  Duration get elapsedDuration =>
      startedAt != null ? DateTime.now().difference(startedAt!) : Duration.zero;

  ActiveSessionState copyWith({
    WorkoutTemplate? workout,
    List<WorkoutExercise>? sessionExercises,
    DateTime? startedAt,
    String? scheduledWorkoutId,
  }) {
    return ActiveSessionState(
      workout: workout ?? this.workout,
      sessionExercises: sessionExercises ?? this.sessionExercises,
      startedAt: startedAt ?? this.startedAt,
      scheduledWorkoutId: scheduledWorkoutId ?? this.scheduledWorkoutId,
    );
  }
}

/// Provider globale che mantiene in memoria l'allenamento attivo.
@Riverpod(keepAlive: true)
class ActiveSessionNotifier extends _$ActiveSessionNotifier {
  @override
  ActiveSessionState build() {
    return const ActiveSessionState();
  }

  /// Avvia una nuova sessione di allenamento oppure riprende quella già in corso.
  void startOrResumeSession(
    WorkoutTemplate workout, {
    String? scheduledWorkoutId,
  }) {
    // Se c'è già una sessione attiva per questo allenamento, conserva lo stato e l'orario di inizio
    if (state.isActive && state.workout?.id == workout.id) {
      return;
    }

    // Inizializza gli esercizi della scheda
    final clonedExercises = workout.exercises.map((e) {
      return WorkoutExercise(
        exerciseId: e.exerciseId,
        exerciseName: e.exerciseName,
        type: e.type,
        sets: List.generate(e.targetSets, (index) {
          int startReps = 0;
          final repsStr = e.targetReps.replaceAll(
            RegExp(r'[^0-9-]'),
            '',
          );
          if (repsStr.contains('-')) {
            startReps = int.tryParse(repsStr.split('-')[0]) ?? 0;
          } else {
            startReps = int.tryParse(repsStr) ?? 0;
          }

          return WorkoutSet(
            weight: e.targetWeight ?? 0,
            reps: startReps,
            distance: e.targetDistance,
            durationSeconds: e.targetDurationSeconds,
          );
        }),
        notes: e.notes,
      );
    }).toList();

    state = ActiveSessionState(
      workout: workout,
      sessionExercises: clonedExercises,
      startedAt: DateTime.now(),
      scheduledWorkoutId: scheduledWorkoutId,
    );
  }

  /// Aggiorna gli esercizi e le serie della sessione corrente.
  void updateSessionExercises(List<WorkoutExercise> exercises) {
    if (!state.isActive) return;
    state = state.copyWith(sessionExercises: exercises);
  }

  /// Termina e resetta la sessione attiva.
  void endSession() {
    state = const ActiveSessionState();
  }
}
