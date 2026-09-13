import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/local/local_workout_program.dart';
import 'package:gymflow/src/models/mappers/program_mapper.dart';
import 'database_provider.dart';
import 'auth_provider.dart';
import 'sync_provider.dart';
part 'program_provider.g.dart';
@riverpod
class LocalPrograms extends _$LocalPrograms {
  @override
  Stream<List<WorkoutProgram>> build() async* {
    ref.watch(programSyncProvider);
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      yield [];
      return;
    }
    final isar = await ref.watch(isarDatabaseProvider.future);
    final stream = isar.localWorkoutPrograms
        .filter()
        .userIdEqualTo(userId)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
    await for (final programs in stream) {
      yield programs.map((p) => p.toDomain()).toList();
    }
  }
}
