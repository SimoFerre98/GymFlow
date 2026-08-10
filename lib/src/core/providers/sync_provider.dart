import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';
import 'database_provider.dart';
import '../../models/mappers/session_mapper.dart';
import '../../models/local/local_workout_session.dart';

part 'sync_provider.g.dart';

@riverpod
void sessionSync(SessionSyncRef ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return;

  final firestore = ref.watch(firestoreServiceProvider);
  final isarAsync = ref.watch(isarDatabaseProvider);

  // We only subscribe if Isar is ready
  if (isarAsync.hasValue) {
    final isar = isarAsync.value!;

    // Listen to Firestore updates
    final sub = firestore.getUserSessions(userId).listen((sessions) async {
      await isar.writeTxn(() async {
        final locals = sessions.map((s) => s.toLocal()).toList();
        await isar.localWorkoutSessions.putAll(locals);
      });
    });

    ref.onDispose(() {
      sub.cancel();
    });
  }
}
