import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/local/local_workout_template.dart';
import 'package:gymflow/src/models/mappers/workout_mapper.dart';
import 'database_provider.dart';
import 'auth_provider.dart';
import 'sync_provider.dart';
part 'workout_provider.g.dart';
@riverpod
class LocalWorkouts extends _$LocalWorkouts {
  @override
  Stream<List<WorkoutTemplate>> build() async* {
    // Watch the sync provider to ensure it's active and keeping data fresh
    ref.watch(workoutSyncProvider);
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      yield [];
      return;
    }
    final isar = await ref.watch(isarDatabaseProvider.future);
    final stream = isar.localWorkoutTemplates
        .filter()
        .userIdEqualTo(userId)
        .watch(fireImmediately: true);
    await for (final workouts in stream) {
      yield workouts.map((w) => w.toDomain()).toList();
    }
  }
}
