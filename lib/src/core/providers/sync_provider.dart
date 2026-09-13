import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';
import 'database_provider.dart';
import '../../models/mappers/session_mapper.dart';
import '../../models/mappers/workout_mapper.dart';
import '../../models/mappers/program_mapper.dart';
import '../../models/mappers/scheduled_workout_mapper.dart';
import '../../models/mappers/body_measurement_mapper.dart';
import '../../models/local/local_workout_session.dart';
import '../../models/local/local_workout_template.dart';
import '../../models/local/local_workout_program.dart';
import '../../models/local/local_scheduled_workout.dart';
import '../../models/local/local_body_measurement.dart';
part 'sync_provider.g.dart';
@riverpod
class SessionSync extends _$SessionSync {
  @override
  void build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return;
    final firestore = ref.watch(firestoreServiceProvider);
    final isarAsync = ref.watch(isarDatabaseProvider);
    // We only subscribe if Isar is ready
    if (isarAsync.hasValue) {
      final isar = isarAsync.value!;
      // Listen to Firestore updates
      final sub = firestore.getUserSessions(userId).listen((sessions) async {
        final locals = sessions.map((s) => s.toLocal()).toList();
        final remoteIds = locals.map((l) => l.firestoreId).whereType<String>().toSet();
        await isar.writeTxn(() async {
          final existing = await isar.localWorkoutSessions
              .filter()
              .userIdEqualTo(userId)
              .findAll();
          final staleIds = existing
              .where((e) => !remoteIds.contains(e.firestoreId))
              .map((e) => e.id)
              .toList();
          if (staleIds.isNotEmpty) {
            await isar.localWorkoutSessions.deleteAll(staleIds);
          }
          await isar.localWorkoutSessions.putAll(locals);
        });
      });
      ref.onDispose(() {
        sub.cancel();
      });
    }
  }
}
@riverpod
class WorkoutSync extends _$WorkoutSync {
  @override
  void build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return;
    final firestore = ref.watch(firestoreServiceProvider);
    final isarAsync = ref.watch(isarDatabaseProvider);
    if (isarAsync.hasValue) {
      final isar = isarAsync.value!;
      final sub = firestore.getUserWorkouts(userId).listen((workouts) async {
        final locals = workouts.map((w) => w.toLocal()).toList();
        final remoteIds = locals.map((l) => l.firestoreId).whereType<String>().toSet();
        await isar.writeTxn(() async {
          final existing = await isar.localWorkoutTemplates
              .filter()
              .userIdEqualTo(userId)
              .findAll();
          final staleIds = existing
              .where((e) => !remoteIds.contains(e.firestoreId))
              .map((e) => e.id)
              .toList();
          if (staleIds.isNotEmpty) {
            await isar.localWorkoutTemplates.deleteAll(staleIds);
          }
          await isar.localWorkoutTemplates.putAll(locals);
        });
      });
      ref.onDispose(() {
        sub.cancel();
      });
    }
  }
}
@riverpod
class ProgramSync extends _$ProgramSync {
  @override
  void build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return;
    final firestore = ref.watch(firestoreServiceProvider);
    final isarAsync = ref.watch(isarDatabaseProvider);
    if (isarAsync.hasValue) {
      final isar = isarAsync.value!;
      final sub = firestore.getUserPrograms(userId).listen((programs) async {
        final locals = programs.map((p) => p.toLocal()).toList();
        final remoteIds = locals.map((l) => l.firestoreId).whereType<String>().toSet();
        await isar.writeTxn(() async {
          final existing = await isar.localWorkoutPrograms
              .filter()
              .userIdEqualTo(userId)
              .findAll();
          final staleIds = existing
              .where((e) => !remoteIds.contains(e.firestoreId))
              .map((e) => e.id)
              .toList();
          if (staleIds.isNotEmpty) {
            await isar.localWorkoutPrograms.deleteAll(staleIds);
          }
          await isar.localWorkoutPrograms.putAll(locals);
        });
      });
      ref.onDispose(() {
        sub.cancel();
      });
    }
  }
}
@riverpod
class ScheduledWorkoutSync extends _$ScheduledWorkoutSync {
  @override
  void build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return;
    final firestore = ref.watch(firestoreServiceProvider);
    final isarAsync = ref.watch(isarDatabaseProvider);
    if (isarAsync.hasValue) {
      final isar = isarAsync.value!;
      final sub = firestore.getUserScheduledWorkouts(userId).listen((scheduled) async {
        final locals = scheduled.map((s) => s.toLocal()).toList();
        final remoteIds = locals.map((l) => l.firestoreId).whereType<String>().toSet();
        await isar.writeTxn(() async {
          final existing = await isar.localScheduledWorkouts
              .filter()
              .userIdEqualTo(userId)
              .findAll();
          final staleIds = existing
              .where((e) => !remoteIds.contains(e.firestoreId))
              .map((e) => e.id)
              .toList();
          if (staleIds.isNotEmpty) {
            await isar.localScheduledWorkouts.deleteAll(staleIds);
          }
          await isar.localScheduledWorkouts.putAll(locals);
        });
      });
      ref.onDispose(() {
        sub.cancel();
      });
    }
  }
}
@riverpod
class BodyMeasurementSync extends _$BodyMeasurementSync {
  @override
  void build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return;
    final firestore = ref.watch(firestoreServiceProvider);
    final isarAsync = ref.watch(isarDatabaseProvider);
    if (isarAsync.hasValue) {
      final isar = isarAsync.value!;
      final sub = firestore.getBodyMeasurements(userId).listen((measurements) async {
        final locals = measurements.map((m) => m.toLocal()).toList();
        final remoteIds = locals.map((l) => l.firestoreId).whereType<String>().toSet();
        await isar.writeTxn(() async {
          final existing = await isar.localBodyMeasurements
              .filter()
              .userIdEqualTo(userId)
              .findAll();
          final staleIds = existing
              .where((e) => !remoteIds.contains(e.firestoreId))
              .map((e) => e.id)
              .toList();
          if (staleIds.isNotEmpty) {
            await isar.localBodyMeasurements.deleteAll(staleIds);
          }
          await isar.localBodyMeasurements.putAll(locals);
        });
      });
      ref.onDispose(() {
        sub.cancel();
      });
    }
  }
}
