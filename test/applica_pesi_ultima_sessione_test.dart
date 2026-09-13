import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/ui/screens/active_session_screen.dart';

/// Precompilare peso/ripetizioni dall'ultima volta non deve toccare una
/// serie già spuntata in questa sessione.
///
/// Segnalato rivedendo il codice: la lettura da Firestore che porta i dati
/// dell'ultima volta è più lenta di un tocco — se nel frattempo l'utente ha
/// già segnato una serie come fatta (o riprende una sessione lasciata attiva
/// in background, che rimonta la schermata da capo), sovrascrivere comunque
/// rimpiazzava in silenzio il numero appena sollevato con quello vecchio,
/// spunta verde compresa.
///
/// Sta fuori dalla schermata per lo stesso motivo di `esercizioFinito`:
/// `ActiveSessionScreen` non si monta in un test — istanzia `FirestoreService`
/// nel proprio `State`, debito di US-008.
void main() {
  WorkoutSet serie({
    double peso = 0,
    int ripetizioni = 0,
    bool completata = false,
  }) =>
      WorkoutSet(weight: peso, reps: ripetizioni, isCompleted: completata);

  WorkoutSession ultimaSessione(List<WorkoutSet> serie) => WorkoutSession(
        id: 'prev',
        userId: 'u1',
        workoutTemplateId: 'w1',
        workoutName: 'Push Day',
        startTime: DateTime(2026, 9, 1),
        exercises: [
          WorkoutExercise(exerciseId: 'e1', exerciseName: 'Panca piana', sets: serie),
        ],
      );

  test('una serie già spuntata non viene toccata', () {
    final correnti = [
      WorkoutExercise(
        exerciseId: 'e1',
        exerciseName: 'Panca piana',
        sets: [serie(peso: 82.5, ripetizioni: 6, completata: true)],
      ),
    ];

    applicaPesiUltimaSessione(
      correnti,
      ultimaSessione([serie(peso: 60, ripetizioni: 10)]),
    );

    expect(correnti.first.sets.first.weight, 82.5);
    expect(correnti.first.sets.first.reps, 6);
  });

  test('una serie non ancora spuntata viene precompilata', () {
    final correnti = [
      WorkoutExercise(
        exerciseId: 'e1',
        exerciseName: 'Panca piana',
        sets: [serie(peso: 0, ripetizioni: 0, completata: false)],
      ),
    ];

    applicaPesiUltimaSessione(
      correnti,
      ultimaSessione([serie(peso: 60, ripetizioni: 10)]),
    );

    expect(correnti.first.sets.first.weight, 60);
    expect(correnti.first.sets.first.reps, 10);
  });

  test('serie miste: solo quella non spuntata cambia', () {
    final correnti = [
      WorkoutExercise(
        exerciseId: 'e1',
        exerciseName: 'Panca piana',
        sets: [
          serie(peso: 82.5, ripetizioni: 6, completata: true),
          serie(peso: 0, ripetizioni: 0, completata: false),
        ],
      ),
    ];

    applicaPesiUltimaSessione(
      correnti,
      ultimaSessione([
        serie(peso: 60, ripetizioni: 10),
        serie(peso: 65, ripetizioni: 8),
      ]),
    );

    expect(correnti.first.sets[0].weight, 82.5, reason: 'la serie fatta resta com era');
    expect(correnti.first.sets[1].weight, 65, reason: 'la serie non fatta si precompila');
    expect(correnti.first.sets[1].reps, 8);
  });

  test('più serie ora che l ultima volta: le nuove prendono il peso dell ultima serie di allora', () {
    final correnti = [
      WorkoutExercise(
        exerciseId: 'e1',
        exerciseName: 'Panca piana',
        sets: [
          serie(),
          serie(),
          serie(),
        ],
      ),
    ];

    applicaPesiUltimaSessione(
      correnti,
      ultimaSessione([serie(peso: 60, ripetizioni: 10)]),
    );

    expect(correnti.first.sets[1].weight, 60);
    expect(correnti.first.sets[2].weight, 60);
  });

  test('esercizio non presente nell ultima sessione: resta invariato', () {
    final correnti = [
      WorkoutExercise(
        exerciseId: 'altro',
        exerciseName: 'Stacco',
        sets: [serie(peso: 0, ripetizioni: 0)],
      ),
    ];

    applicaPesiUltimaSessione(
      correnti,
      ultimaSessione([serie(peso: 60, ripetizioni: 10)]),
    );

    expect(correnti.first.sets.first.weight, 0);
    expect(correnti.first.sets.first.reps, 0);
  });
}
