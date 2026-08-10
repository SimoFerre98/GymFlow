import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/screens/program_list_screen.dart';
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
class _FakeFirestoreService implements FirestoreService {
  bool getUserProgramsCalled = false;

  @override
  Stream<List<WorkoutProgram>> getUserPrograms(String userId) {
    getUserProgramsCalled = true;
    return Stream.value([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  // ---- B. Montaggio con servizio finto ------------------------------------
  //
  // ⭐ Questo è il criterio che dimostra la storia: un servizio finto
  // sostituisce quello vero, e la schermata lo usa.

  group('montaggio con servizio finto', () {
    testWidgets(
      'ProgramListScreen usa il FirestoreService iniettato',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final fakeFirestore = _FakeFirestoreService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firestoreServiceProvider.overrideWithValue(fakeFirestore),
              currentUserIdProvider.overrideWithValue('test-user'),
            ],
            child: MaterialApp(
              theme: ThemeData(
                extensions: const [ExpressiveTokens()],
              ),
              home: const ProgramListScreen(),
            ),
          ),
        );

        // Primo frame: la schermata è in attesa dello stream
        await tester.pump();

        // Lo stream vuoto emette []: la schermata mostra lo stato vuoto
        await tester.pump();

        // Verifica che il servizio finto sia stato effettivamente chiamato:
        // è la prova che l'iniezione funziona.
        expect(fakeFirestore.getUserProgramsCalled, isTrue,
            reason: 'il servizio finto non è stato chiamato — '
                "l'iniezione non funziona");

        // Verifica che la schermata si sia montata senza errori
        expect(find.byType(ProgramListScreen), findsOneWidget);
      },
    );
  });
}
