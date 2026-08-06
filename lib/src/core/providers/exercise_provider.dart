import 'package:flutter/services.dart' show rootBundle;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/exercise.dart';
import '../../models/exercise_seed.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

part 'exercise_provider.g.dart';

/// Percorso della libreria curata che viaggia dentro l'app.
const kCuratedLibraryAsset = 'assets/data/exercises_seed.json';

/// I 43 esercizi curati, letti dall'asset.
///
/// **Non stanno in Firestore, e non e un ripiego.** Le regole negano al client
/// la scrittura sulla collezione `exercises`, ed e la scelta giusta: quei
/// documenti hanno `userId` nullo e sono visibili a tutti gli utenti, quindi un
/// client che potesse scriverli cambierebbe la libreria di chiunque. US-045
/// aveva costruito un import che in produzione rispondeva
/// `The caller does not have permission`.
///
/// La libreria curata e materiale statico: uguale per tutti, immutabile
/// dall'utente, aggiornato da una versione dell'app. Un asset e esattamente
/// questo — e non ha bisogno di essere caricato, **c'e**: al primo avvio, senza
/// rete e senza permessi.
///
/// Se qualcuno in futuro pensasse di riportarli su Firestore: il problema non e
/// dove stanno, e chi puo scriverli.
@riverpod
class CuratedExercises extends _$CuratedExercises {
  @override
  Future<List<Exercise>> build() async {
    final source = await rootBundle.loadString(kCuratedLibraryAsset);
    return ExerciseSeed.parse(source).exercises;
  }
}

/// Gli esercizi creati dall'utente, da Firestore.
@riverpod
class CustomExercises extends _$CustomExercises {
  @override
  Stream<List<Exercise>> build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return Stream.value(const []);

    return ref.watch(firestoreServiceProvider).getExercises(userId);
  }
}

/// Tutti gli esercizi visibili all'utente: i curati piu i suoi.
///
/// A parita di identificativo vince quello dell'utente: e l'unico dei due che
/// qualcuno ha modificato di proposito. Oggi non puo succedere — Firestore
/// genera identificativi di venti caratteri e i curati sono `ex_001` — ma un
/// elenco che mostra due volte lo stesso esercizio e un difetto che si nota
/// tardi e si spiega male.
///
/// I curati arrivano per primi anche quando Firestore tace: se la rete manca o
/// l'utente non e autenticato, la libreria **non e vuota**.
@riverpod
class Exercises extends _$Exercises {
  @override
  Future<List<Exercise>> build() async {
    final curated = await ref.watch(curatedExercisesProvider.future);
    // `valueOrNull` e non `value`: su un `AsyncError`, `value` **rilancia**
    // l'errore. Con Firestore che risponde `permission-denied` — il caso reale
    // che ha aperto questa storia — la libreria si sarebbe svuotata invece di
    // mostrare i curati, che e esattamente cio che questa storia esiste per
    // evitare.
    final custom =
        ref.watch(customExercisesProvider).valueOrNull ?? const <Exercise>[];

    final byId = <String, Exercise>{for (final e in curated) e.id: e};
    for (final exercise in custom) {
      byId[exercise.id] = exercise;
    }
    return byId.values.toList();
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
/// Finche l'elenco non e pronto la mappa e vuota, non nulla: una cella non deve
/// saper distinguere "sto caricando" da "non c'e", perche in entrambi i casi
/// disegna il segnaposto.
@riverpod
class ExerciseIndex extends _$ExerciseIndex {
  @override
  Map<String, Exercise> build() {
    // Come sopra: un errore a monte deve dare un indice vuoto, non propagarsi
    // fino a far cadere ogni cella di lista che lo consulta.
    final exercises =
        ref.watch(exercisesProvider).valueOrNull ?? const <Exercise>[];
    return {for (final exercise in exercises) exercise.id: exercise};
  }
}
