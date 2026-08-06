// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timerNotifierHash() => r'68760cde716d0bec36110a4f55ca17d829793938';

/// Cronometro e timer da conto alla rovescia, condivisi da tutta l'app.
///
/// keepAlive perche devono continuare a scorrere anche quando l'utente lascia
/// la schermata degli strumenti: e il presupposto dell'overlay flottante.
///
/// Il ticker gira a 30 ms ed e sempre attivo, come nella versione precedente.
/// Fermarlo quando cronometro e timer sono inattivi e compito di US-013:
/// cambiarlo qui renderebbe indistinguibile una regressione della migrazione
/// da un cambio voluto di comportamento.
///
/// Copied from [TimerNotifier].
@ProviderFor(TimerNotifier)
final timerNotifierProvider =
    NotifierProvider<TimerNotifier, TimerState>.internal(
  TimerNotifier.new,
  name: r'timerNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timerNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TimerNotifier = Notifier<TimerState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
