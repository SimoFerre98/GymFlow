import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/local/local_workout_session.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> isarDatabase(IsarDatabaseRef ref) async {
  final dir = await getApplicationDocumentsDirectory();

  if (Isar.instanceNames.isEmpty) {
    return await Isar.open([LocalWorkoutSessionSchema], directory: dir.path);
  }

  return Isar.getInstance()!;
}
