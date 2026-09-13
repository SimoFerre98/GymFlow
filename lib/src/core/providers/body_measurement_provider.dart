import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar/isar.dart';
import 'package:gymflow/src/models/body_measurement.dart';
import 'package:gymflow/src/models/local/local_body_measurement.dart';
import 'package:gymflow/src/models/mappers/body_measurement_mapper.dart';
import 'database_provider.dart';
import 'auth_provider.dart';
import 'sync_provider.dart';
part 'body_measurement_provider.g.dart';
@riverpod
class LocalBodyMeasurements extends _$LocalBodyMeasurements {
  @override
  Stream<List<BodyMeasurement>> build() async* {
    ref.watch(bodyMeasurementSyncProvider);
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      yield [];
      return;
    }
    final isar = await ref.watch(isarDatabaseProvider.future);
    final stream = isar.localBodyMeasurements
        .filter()
        .userIdEqualTo(userId)
        .sortByDateDesc()
        .watch(fireImmediately: true);
    await for (final measurements in stream) {
      yield measurements.map((m) => m.toDomain()).toList();
    }
  }
}
