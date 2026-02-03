import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/models/local/local_workout_session.dart';
import 'package:gymflow/src/models/mappers/session_mapper.dart';
import 'database_provider.dart';
import 'auth_provider.dart';
import 'sync_provider.dart';

part 'dashboard_provider.g.dart';

@riverpod
class DashboardSessions extends _$DashboardSessions {
  @override
  Stream<List<WorkoutSession>> build() async* {
    // Watch the sync provider to ensure it's active and keeping data fresh
    ref.watch(sessionSyncProvider);

    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      yield [];
      return;
    }

    final isar = await ref.watch(isarDatabaseProvider.future);

    // Watch local query for real-time updates from Isar
    final stream = isar.localWorkoutSessions
        .filter()
        .userIdEqualTo(userId)
        .sortByStartTimeDesc()
        .watch(fireImmediately: true);

    await for (final sessions in stream) {
      yield sessions.map((s) => s.toDomain()).toList();
    }
  }
}
