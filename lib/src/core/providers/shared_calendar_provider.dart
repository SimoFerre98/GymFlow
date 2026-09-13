import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';
part 'shared_calendar_provider.g.dart';
/// Sessioni e programmazione **condivise dagli amici**, per il calendario.
///
/// Restano lette da Firestore direttamente — non sono dati dell'utente
/// corrente, non entrano nella cache Isar (US-111) — ma passano da un
/// provider Riverpod invece che da uno stream ricostruito dentro `build()`:
/// altrimenti un aggiornamento dei dati propri (ora riletti da Isar)
/// avrebbe fatto ripartire anche questa sottoscrizione ad ogni rebuild
/// della schermata, non solo al cambio di mese.
@riverpod
class SharedCalendarEvents extends _$SharedCalendarEvents {
  @override
  Stream<({List<WorkoutSession> sessions, List<ScheduledWorkout> schedules})> build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return Stream.value((sessions: const <WorkoutSession>[], schedules: const <ScheduledWorkout>[]));
    }
    final firestore = ref.watch(firestoreServiceProvider);
    return Rx.combineLatest2(
      firestore.getSharedSessions(userId),
      firestore.getSharedScheduledWorkouts(userId),
      (sessions, schedules) => (sessions: sessions, schedules: schedules),
    );
  }
}
