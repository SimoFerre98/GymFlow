import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/ui/screens/active_session_screen.dart';

/// Quando un esercizio risulta finito.
///
/// Segnalato provando l'app: «quando finisco un esercizio rimane sempre in
/// corso». La regola sta fuori dalla schermata perche `ActiveSessionScreen` non
/// si monta in un test — istanzia `FirestoreService` nel proprio `State`, debito
/// di US-008 — e una regola che decide cosa l'utente vede segnato come fatto
/// merita di essere provata invece che riscritta in un test.
///
/// **Limite dichiarato**: prova la regola, non il disegno. Che la spunta e il
/// barrato si vedano davvero resta da confermare sull'APK.
void main() {
  WorkoutSet serie({required bool completata}) => WorkoutSet(
    reps: 10,
    weight: 20,
    isCompleted: completata,
  );

  WorkoutExercise esercizio(List<WorkoutSet> serie) => WorkoutExercise(
    exerciseId: 'e1',
    exerciseName: 'Panca piana',
    sets: serie,
  );

  test('tutte le serie spuntate: finito', () {
    expect(
      esercizioFinito(
        esercizio([serie(completata: true), serie(completata: true)]),
      ),
      isTrue,
    );
  });

  test('una serie non spuntata: non finito', () {
    expect(
      esercizioFinito(
        esercizio([serie(completata: true), serie(completata: false)]),
      ),
      isFalse,
      reason: 'e il caso che conta: togliendo una spunta torna in corso',
    );
  });

  test('nessuna serie spuntata: non finito', () {
    expect(
      esercizioFinito(
        esercizio([serie(completata: false), serie(completata: false)]),
      ),
      isFalse,
    );
  });

  test('un esercizio senza serie non e finito', () {
    // `every` su una lista vuota e vero: senza questo caso, un esercizio a cui
    // non e stato fatto niente risulterebbe concluso.
    expect(esercizioFinito(esercizio([])), isFalse);
  });
}
