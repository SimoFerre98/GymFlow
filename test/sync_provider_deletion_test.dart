import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/core/providers/database_provider.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart' as fp;
import 'package:gymflow/src/core/providers/sync_provider.dart';
import 'package:gymflow/src/models/local/local_body_measurement.dart';
import 'package:gymflow/src/models/local/local_scheduled_workout.dart';
import 'package:gymflow/src/models/local/local_workout_program.dart';
import 'package:gymflow/src/models/local/local_workout_session.dart';
import 'package:gymflow/src/models/local/local_workout_template.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/services/firestore_service.dart' as svc;

/// Un [FirestoreService] finto la cui lista di programmi cambia nel tempo,
/// per osservare come [ProgramSync] reagisce a un documento **sparito**
/// da Firestore — il caso che `SessionSync` non gestiva prima di US-111.
class _FakeStreamingFirestoreService implements svc.FirestoreService {
  final _controller = StreamController<List<WorkoutProgram>>.broadcast();

  void emit(List<WorkoutProgram> programs) => _controller.add(programs);

  @override
  Stream<List<WorkoutProgram>> getUserPrograms(String userId) => _controller.stream;

  @override
  Stream<List<WorkoutSession>> getUserSessions(String userId) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestoreNotifier extends fp.FirestoreService {
  _FakeFirestoreNotifier(this._service);
  final svc.FirestoreService _service;
  @override
  svc.FirestoreService build() => _service;
}

class _FakeCurrentUserId extends CurrentUserId {
  _FakeCurrentUserId(this._id);
  final String _id;
  @override
  String? build() => _id;
}

class _FakeIsarDatabase extends IsarDatabase {
  _FakeIsarDatabase(this._directory);
  final Directory _directory;
  @override
  Future<Isar> build() async {
    return Isar.open(
      [
        LocalWorkoutSessionSchema,
        LocalWorkoutTemplateSchema,
        LocalWorkoutProgramSchema,
        LocalScheduledWorkoutSchema,
        LocalBodyMeasurementSchema,
      ],
      directory: _directory.path,
      name: 'test_${_directory.path.hashCode}',
    );
  }
}

WorkoutProgram _program(String id) => WorkoutProgram(
      id: id,
      userId: 'test-user',
      name: 'Programma $id',
      workoutIds: const [],
      createdAt: DateTime.utc(2026, 1, 1),
    );

Future<List<LocalWorkoutProgram>> _readIsar(Isar isar) => isar.localWorkoutPrograms
    .filter()
    .userIdEqualTo('test-user')
    .findAll();

void main() {
  test(
    'ProgramSync rimuove da Isar un programma non più presente su Firestore',
    () async {
      await Isar.initializeIsarCore(download: true);
      final tempDir = await Directory.systemTemp.createTemp('gymflow_sync_test');
      addTearDown(() => tempDir.delete(recursive: true));

      final fakeFirestore = _FakeStreamingFirestoreService();
      addTearDown(fakeFirestore._controller.close);

      final container = ProviderContainer(
        overrides: [
          fp.firestoreServiceProvider.overrideWith(() => _FakeFirestoreNotifier(fakeFirestore)),
          currentUserIdProvider.overrideWith(() => _FakeCurrentUserId('test-user')),
          isarDatabaseProvider.overrideWith(() => _FakeIsarDatabase(tempDir)),
        ],
      );
      addTearDown(container.dispose);

      final isar = await container.read(isarDatabaseProvider.future);
      // `programSyncProvider` è autoDispose: un `container.read()` isolato
      // verrebbe smontato (e la sottoscrizione a Firestore cancellata) al
      // prossimo microtask, perché nessuno lo osserva davvero. Nell'app vera
      // resta vivo perché `LocalPrograms` lo guarda con `ref.watch()` finché
      // la UI lo osserva; qui lo si tiene vivo esplicitamente per la durata
      // del test con un listener che non fa nulla.
      container.listen(programSyncProvider, (_, _) {});

      // Prima emissione: due programmi. ProgramSync li scrive entrambi.
      fakeFirestore.emit([_program('a'), _program('b')]);
      await _waitUntil(() async => (await _readIsar(isar)).length == 2);
      expect((await _readIsar(isar)).map((p) => p.firestoreId).toSet(), {'a', 'b'});

      // Seconda emissione: "b" è sparito da Firestore (cancellato altrove).
      // Senza la correzione di US-111, "b" sarebbe rimasto per sempre in Isar.
      fakeFirestore.emit([_program('a')]);
      await _waitUntil(() async => (await _readIsar(isar)).length == 1);
      final remaining = await _readIsar(isar);
      expect(remaining.map((p) => p.firestoreId).toSet(), {'a'},
          reason: '"b" non è più su Firestore: deve sparire anche da Isar');
    },
  );
}

/// Il write della sync è una `writeTxn` asincrona: attende una condizione
/// invece di un ritardo fisso, con un limite per non appendersi se qualcosa
/// si rompe davvero.
Future<void> _waitUntil(Future<bool> Function() condition) async {
  for (var i = 0; i < 50; i++) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('condizione mai soddisfatta entro il timeout');
}
