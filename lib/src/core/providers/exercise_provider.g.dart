// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$exercisesHash() => r'e254ee284aa1ad83fcce96dccd0b0f9afdfdc9af';

/// Gli esercizi visibili all'utente: quelli forniti col prodotto piu i suoi.
///
/// Espone lo stream che il servizio ha sempre avuto, ma da un provider: le
/// schermate non devono istanziare `FirestoreService` per averlo, e chi lo
/// guarda in due punti diversi condivide un solo ascolto.
///
/// Scritto come notifier di classe e non come funzione perche il generatore, per
/// i provider da funzione, emette ancora un typedef deprecato: due avvisi in piu
/// sull'analyzer, e questo progetto tiene il conto degli avvisi.
///
/// Copied from [Exercises].
@ProviderFor(Exercises)
final exercisesProvider =
    AutoDisposeStreamNotifierProvider<Exercises, List<Exercise>>.internal(
  Exercises.new,
  name: r'exercisesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$exercisesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Exercises = AutoDisposeStreamNotifier<List<Exercise>>;
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
/// Finche lo stream non ha risposto la mappa e vuota, non nulla: una cella non
/// deve saper distinguere "sto caricando" da "non c'e", perche in entrambi i
/// casi disegna il segnaposto.
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
