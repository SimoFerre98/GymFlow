import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/local/local_workout_session.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
class IsarDatabase extends _$IsarDatabase {
  @override
  Future<Isar> build() async {
    final dir = await getApplicationDocumentsDirectory();

    // Check if default instance is already open
    final existingInstance = Isar.getInstance('default');
    if (existingInstance != null) {
      return existingInstance;
    }

    return await Isar.open(
      [LocalWorkoutSessionSchema],
      directory: dir.path,
      inspector: true,
    );
  }
}
