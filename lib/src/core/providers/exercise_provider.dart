import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/exercise.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

part 'exercise_provider.g.dart';

/// Gli esercizi visibili all'utente: quelli forniti col prodotto piu i suoi.
///
/// Espone lo stream che il servizio ha sempre avuto, ma da un provider: le
/// schermate non devono istanziare `FirestoreService` per averlo, e chi lo
/// guarda in due punti diversi condivide un solo ascolto.
///
/// Scritto come notifier di classe e non come funzione perche il generatore, per
/// i provider da funzione, emette ancora un typedef deprecato: due avvisi in piu
/// sull'analyzer, e questo progetto tiene il conto degli avvisi.
@riverpod
class Exercises extends _$Exercises {
  @override
  Stream<List<Exercise>> build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return Stream.value(const []);

    return ref.watch(firestoreServiceProvider).getExercises(userId);
  }
}

/// Gli esercizi per identificativo.
///
/// Esiste per un motivo preciso: schede e sessioni salvano `exerciseId` e
/// `exerciseName` e nient'altro — vedi `WorkoutTemplateExercise` in
/// `models/workout.dart`. Sanno *quale* esercizio, non *com'e fatto*, quindi per
/// mostrarne l'immagine serve risalire all'esercizio completo.
///
/// La forma e una mappa e non una ricerca lineare perche chi la consulta e una
/// cella di lista: cento celle che cercano in una lista di cento sono diecimila
/// confronti a ogni ricostruzione, cento celle che leggono una mappa sono cento
/// accessi.
///
/// Finche lo stream non ha risposto la mappa e vuota, non nulla: una cella non
/// deve saper distinguere "sto caricando" da "non c'e", perche in entrambi i
/// casi disegna il segnaposto.
@riverpod
class ExerciseIndex extends _$ExerciseIndex {
  @override
  Map<String, Exercise> build() {
    final exercises = ref.watch(exercisesProvider).value ?? const <Exercise>[];
    return {for (final exercise in exercises) exercise.id: exercise};
  }
}
