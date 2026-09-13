import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/ui/screens/active_session_screen.dart';

/// Il recupero di una serie quando lo stesso esercizio compare due volte
/// nella scheda (riscaldamento leggero e blocco pesante a fine seduta, per
/// esempio), con recuperi diversi.
///
/// Trovato rivedendo il codice: la ricerca cercava lo slot della scheda per
/// `exerciseId`, che trova sempre il **primo** slot con quell'id — chi
/// completava una serie del secondo slot otteneva comunque il recupero del
/// primo. `recuperoDellaSerie` cerca per posizione invece, sfruttando che
/// `_sessionExercises` e `widget.workout.exercises` sono costruite l'una
/// dall'altra con una `.map()` 1:1.
///
/// Sta fuori dalla schermata per lo stesso motivo di `esercizioFinito`:
/// `ActiveSessionScreen` non si monta in un test, debito di US-008.
void main() {
  WorkoutExercise esercizioSessione(String id) => WorkoutExercise(
        exerciseId: id,
        exerciseName: 'Squat',
        sets: [WorkoutSet(weight: 60, reps: 10)],
      );

  WorkoutTemplateExercise esercizioScheda(String id, {int? restSeconds}) =>
      WorkoutTemplateExercise(
        exerciseId: id,
        exerciseName: 'Squat',
        targetSets: 1,
        restSeconds: restSeconds,
      );

  test('due slot dello stesso esercizio: il recupero è quello del secondo slot, non del primo', () {
    final riscaldamento = esercizioSessione('squat');
    final pesante = esercizioSessione('squat');
    final sessionExercises = [riscaldamento, pesante];
    final templateExercises = [
      esercizioScheda('squat', restSeconds: 60),
      esercizioScheda('squat', restSeconds: 180),
    ];

    final recupero = recuperoDellaSerie(
      sessionExercises: sessionExercises,
      templateExercises: templateExercises,
      exercise: pesante,
      set: pesante.sets.first,
    );

    expect(recupero, 180, reason: 'e il secondo slot che ha completato la serie, non il primo');
  });

  test('un recupero specifico della serie (plannedSets) vince su quello dell esercizio', () {
    final exercise = esercizioSessione('squat');
    final template = WorkoutTemplateExercise(
      exerciseId: 'squat',
      exerciseName: 'Squat',
      restSeconds: 90,
      plannedSets: [PlannedSet(reps: 10, restSeconds: 45)],
    );

    final recupero = recuperoDellaSerie(
      sessionExercises: [exercise],
      templateExercises: [template],
      exercise: exercise,
      set: exercise.sets.first,
    );

    expect(recupero, 45);
  });

  test('nessun recupero specifico: null, chi chiama ricade sul generico', () {
    final exercise = esercizioSessione('squat');
    final template = esercizioScheda('squat');

    final recupero = recuperoDellaSerie(
      sessionExercises: [exercise],
      templateExercises: [template],
      exercise: exercise,
      set: exercise.sets.first,
    );

    expect(recupero, isNull);
  });

  test('esercizio non trovato nella scheda: null', () {
    final exercise = esercizioSessione('squat');

    final recupero = recuperoDellaSerie(
      sessionExercises: [exercise],
      templateExercises: const [],
      exercise: exercise,
      set: exercise.sets.first,
    );

    expect(recupero, isNull);
  });
}
