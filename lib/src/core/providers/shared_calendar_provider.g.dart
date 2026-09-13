// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_calendar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sharedCalendarEventsHash() =>
    r'35276beb6ec8afc122964294f8f5d2a7b82e0951';

/// Sessioni e programmazione **condivise dagli amici**, per il calendario.
///
/// Restano lette da Firestore direttamente — non sono dati dell'utente
/// corrente, non entrano nella cache Isar (US-111) — ma passano da un
/// provider Riverpod invece che da uno stream ricostruito dentro `build()`:
/// altrimenti un aggiornamento dei dati propri (ora riletti da Isar)
/// avrebbe fatto ripartire anche questa sottoscrizione ad ogni rebuild
/// della schermata, non solo al cambio di mese.
///
/// Copied from [SharedCalendarEvents].
@ProviderFor(SharedCalendarEvents)
final sharedCalendarEventsProvider = AutoDisposeStreamNotifierProvider<
    SharedCalendarEvents,
    ({
      List<WorkoutSession> sessions,
      List<ScheduledWorkout> schedules
    })>.internal(
  SharedCalendarEvents.new,
  name: r'sharedCalendarEventsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sharedCalendarEventsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SharedCalendarEvents = AutoDisposeStreamNotifier<
    ({List<WorkoutSession> sessions, List<ScheduledWorkout> schedules})>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
