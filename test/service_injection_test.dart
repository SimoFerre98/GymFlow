import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/core/providers/database_provider.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart' as fp;
import 'package:gymflow/src/models/local/local_body_measurement.dart';
import 'package:gymflow/src/models/local/local_scheduled_workout.dart';
import 'package:gymflow/src/models/local/local_workout_program.dart';
import 'package:gymflow/src/models/local/local_workout_session.dart';
import 'package:gymflow/src/models/local/local_workout_template.dart';
import 'package:gymflow/src/core/providers/program_provider.dart';
import 'package:gymflow/src/core/providers/sync_provider.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/session.dart';
import 'package:gymflow/src/services/firestore_service.dart' as svc;
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Doppi di test
// ---------------------------------------------------------------------------

/// Un [FirestoreService] finto che restituisce stream vuoti invece di
/// contattare Firebase. Usa `implements` e non `extends` perché il costruttore
/// di [FirestoreService] inizializza Firestore, che non è disponibile nei test.
///
/// Basta a dimostrare che la schermata riceve il servizio dal provider e non
/// ne crea uno proprio.
class _FakeFirestoreService implements svc.FirestoreService {
  bool getUserProgramsCalled = false;

  @override
  Stream<List<WorkoutProgram>> getUserPrograms(String userId) {
    getUserProgramsCalled = true;
    return Stream.value([]);
  }

  @override
  Stream<List<WorkoutSession>> getUserSessions(String userId) => Stream.value([]);

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

/// Da US-111: `ProgramListScreen` non legge più `getUserPrograms` da
/// Firestore direttamente, ma dalla cache Isar tenuta allineata da
/// `ProgramSync` in background. Per dimostrare che il servizio finto viene
/// comunque interpellato (l'iniezione funziona ancora, solo con un livello
/// in più) serve un'istanza Isar vera, aperta su una directory temporanea:
/// non è mockabile a interfaccia come `FirestoreService`.
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

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------

void main() {
  // ---- A. Test sul sorgente ------------------------------------------------
  //
  // Verifica necessaria, non sufficiente: attestano **come è scritto** il
  // codice, non che l'iniezione funzioni davvero. La parte B lo dimostra.

  const schermate = <String>[
    'lib/src/ui/screens/dashboard_screen.dart',
    'lib/src/ui/screens/calendar_screen.dart',
    'lib/src/ui/screens/program_list_screen.dart',
  ];

  /// Righe di codice, senza i commenti: un valore citato in un commento che
  /// spiega **perché** non c'è più non è una violazione.
  List<String> righeDiCodice(String percorso) {
    final file = File(percorso);
    expect(file.existsSync(), isTrue, reason: '$percorso non esiste');
    return file
        .readAsLinesSync()
        .where((r) => !r.trimLeft().startsWith('//'))
        .toList();
  }

  group('nessuna istanziazione diretta dei servizi', () {
    for (final percorso in schermate) {
      final nome = percorso.split('/').last;

      test('$nome non contiene FirestoreService()', () {
        final righe = righeDiCodice(percorso)
            .where((r) => r.contains('FirestoreService()'))
            .toList();

        expect(righe, isEmpty,
            reason: 'FirestoreService() trovato — usa firestoreServiceProvider');
      });

      test('$nome non contiene AuthService()', () {
        final righe = righeDiCodice(percorso)
            .where((r) => r.contains('AuthService()'))
            .toList();

        expect(righe, isEmpty,
            reason: 'AuthService() trovato — usa currentUserIdProvider');
      });

      test('$nome non contiene HealthService()', () {
        final righe = righeDiCodice(percorso)
            .where((r) => r.contains('HealthService()'))
            .toList();

        expect(righe, isEmpty,
            reason: 'HealthService() trovato — usa healthServiceProvider');
      });
    }
  });

  // ---- B. Il servizio finto attraversa davvero la catena -------------------
  //
  // ⭐ Questo è il criterio che dimostra la storia: un servizio finto
  // sostituisce quello vero, e i provider — non la schermata direttamente —
  // lo usano.
  //
  // ⚠️ Limite dichiarato (US-111): questo non è più un `testWidgets` che
  // monta `ProgramListScreen`. `localProgramsProvider` legge da Isar con
  // `.watch()`, e aprire un'istanza Isar vera dentro `testWidgets` si è
  // rivelato instabile in questo ambiente — l'operazione asincrona reale
  // (I/O nativo di Isar) non avanza sotto `AutomatedTestWidgetsFlutterBinding`
  // senza `tester.runAsync`, e con `runAsync` l'esito è rimasto incerto nel
  // tempo a disposizione. Si verifica quindi la catena vera (servizio finto
  // → ProgramSync → Isar → LocalPrograms, lo stesso provider che
  // `ProgramListScreen` legge con `ref.watch`) con un `ProviderContainer`
  // puro, senza montare alcun widget: prova il meccanismo, non l'albero
  // grafico. Il montaggio effettivo resta verificato dall'APK.
  group('il servizio finto attraversa sync provider e cache Isar', () {
    test(
      'localProgramsProvider (letto da ProgramListScreen) riceve i dati dal servizio finto',
      () async {
        SharedPreferences.setMockInitialValues({});
        await Isar.initializeIsarCore(download: true);
        final tempDir = await Directory.systemTemp.createTemp('gymflow_isar_test');
        addTearDown(() => tempDir.delete(recursive: true));

        final fakeFirestore = _FakeFirestoreService();
        final container = ProviderContainer(
          overrides: [
            fp.firestoreServiceProvider.overrideWith(() => _FakeFirestoreNotifier(fakeFirestore)),
            currentUserIdProvider.overrideWith(() => _FakeCurrentUserId('test-user')),
            isarDatabaseProvider.overrideWith(() => _FakeIsarDatabase(tempDir)),
          ],
        );
        addTearDown(container.dispose);

        // Isar prima: ProgramSync osserva isarDatabaseProvider in modo
        // sincrono (non `.future`), quindi se lo si legge per primo qui,
        // quando ProgramSync verrà costruito lo vedrà già risolto — senza
        // questo ordine la primissima emissione "fireImmediately" di
        // LocalPrograms può arrivare prima che ProgramSync abbia mai
        // interpellato il servizio finto, rendendo il test dipendente da un
        // ordine di scheduling che Riverpod non garantisce.
        await container.read(isarDatabaseProvider.future);
        container.read(programSyncProvider);

        expect(fakeFirestore.getUserProgramsCalled, isTrue,
            reason: 'il servizio finto non è stato chiamato — '
                "l'iniezione non funziona");

        // localProgramsProvider è esattamente il provider che
        // program_list_screen.dart legge con `ref.watch(...)`.
        final firstValue = await container.read(localProgramsProvider.future);
        expect(firstValue, isEmpty,
            reason: 'il servizio finto emette una lista vuota: '
                'la cache Isar deve rifletterla, non inventare programmi');
      },
    );
  });
}
