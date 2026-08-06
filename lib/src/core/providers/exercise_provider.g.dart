// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$curatedExercisesHash() => r'e058720fbf16d48957c5f41d9e6c0b6f66c76aed';

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
///
/// Copied from [CuratedExercises].
@ProviderFor(CuratedExercises)
final curatedExercisesProvider =
    AutoDisposeAsyncNotifierProvider<CuratedExercises, List<Exercise>>.internal(
  CuratedExercises.new,
  name: r'curatedExercisesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$curatedExercisesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CuratedExercises = AutoDisposeAsyncNotifier<List<Exercise>>;
String _$customExercisesHash() => r'3862bde5c5034f4072b146dee2ac284d378e6414';

/// Gli esercizi creati dall'utente, da Firestore.
///
/// Copied from [CustomExercises].
@ProviderFor(CustomExercises)
final customExercisesProvider =
    AutoDisposeStreamNotifierProvider<CustomExercises, List<Exercise>>.internal(
  CustomExercises.new,
  name: r'customExercisesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$customExercisesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CustomExercises = AutoDisposeStreamNotifier<List<Exercise>>;
String _$exercisesHash() => r'd7f0fd9d61ff781798fff483ff8cff92b2da82e9';

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
///
/// Copied from [Exercises].
@ProviderFor(Exercises)
final exercisesProvider =
    AutoDisposeAsyncNotifierProvider<Exercises, List<Exercise>>.internal(
  Exercises.new,
  name: r'exercisesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$exercisesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Exercises = AutoDisposeAsyncNotifier<List<Exercise>>;
String _$exerciseIndexHash() => r'ca19823beb3664eacef21aff8c0b2f77447ef8b8';

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
///
/// Copied from [ExerciseIndex].
@ProviderFor(ExerciseIndex)
final exerciseIndexProvider =
    AutoDisposeNotifierProvider<ExerciseIndex, Map<String, Exercise>>.internal(
  ExerciseIndex.new,
  name: r'exerciseIndexProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exerciseIndexHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ExerciseIndex = AutoDisposeNotifier<Map<String, Exercise>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
