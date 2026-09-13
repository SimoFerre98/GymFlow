import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';
import 'package:gymflow/src/models/scheduled_workout.dart';
import 'package:gymflow/src/models/local/local_scheduled_workout.dart';
import 'package:gymflow/src/models/mappers/scheduled_workout_mapper.dart';
import 'database_provider.dart';
import 'auth_provider.dart';
import 'sync_provider.dart';
part 'scheduled_workout_provider.g.dart';
@riverpod
class LocalScheduledWorkouts extends _$LocalScheduledWorkouts {
  @override
  Stream<List<ScheduledWorkout>> build() async* {
    ref.watch(scheduledWorkoutSyncProvider);
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      yield [];
      return;
    }
    final isar = await ref.watch(isarDatabaseProvider.future);
    final stream = isar.localScheduledWorkouts
        .filter()
        .userIdEqualTo(userId)
        .watch(fireImmediately: true);
    await for (final scheduled in stream) {
      yield scheduled.map((s) => s.toDomain()).toList();
    }
  }
}
