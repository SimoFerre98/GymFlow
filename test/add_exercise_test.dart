import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/ui/widgets/add_exercise_dialog.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/ui/screens/exercise_library_screen.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';

void main() {
  group('handleAddExerciseSubmit - Validazione nome', () {
    test('nome vuoto viene rifiutato con messaggio di errore e non chiude il dialogo', () async {
      var saveCalled = false;
      final result = await handleAddExerciseSubmit(
        rawName: '',
        type: ExerciseType.strength,
        userId: 'user123',
        saveExercise: (exercise) async {
          saveCalled = true;
        },
      );

      expect(result.outcome, equals(AddExerciseOutcome.validationError));
      expect(result.errorKey, equals('add_exercise_name_empty'));
      expect(result.shouldCloseDialog, isFalse);
      expect(saveCalled, isFalse);
    });

    test('nome di soli spazi viene rifiutato come nome vuoto', () async {
      var saveCalled = false;
      final result = await handleAddExerciseSubmit(
        rawName: '   ',
        type: ExerciseType.cardio,
        userId: 'user123',
        saveExercise: (exercise) async {
          saveCalled = true;
        },
      );

      expect(result.outcome, equals(AddExerciseOutcome.validationError));
      expect(result.errorKey, equals('add_exercise_name_empty'));
      expect(result.shouldCloseDialog, isFalse);
      expect(saveCalled, isFalse);
    });
  });

  group('handleAddExerciseSubmit - Gestione errori di salvataggio', () {
    test('fallimento di salvataggio restituisce saveError e non chiude il dialogo', () async {
      final result = await handleAddExerciseSubmit(
        rawName: 'Panca Piana',
        type: ExerciseType.strength,
        userId: 'user123',
        saveExercise: (exercise) async {
          throw Exception('Firestore write denied');
        },
      );

      expect(result.outcome, equals(AddExerciseOutcome.saveError));
      expect(result.errorKey, equals('add_exercise_error_saving'));
      expect(result.shouldCloseDialog, isFalse);
    });
  });

  group('handleAddExerciseSubmit - Salvataggio con successo', () {
    test('salvataggio riuscito restituisce success e chiude il dialogo', () async {
      Exercise? savedExercise;
      final result = await handleAddExerciseSubmit(
        rawName: '  Panca Inclinata  ',
        type: ExerciseType.strength,
        userId: 'user123',
        saveExercise: (exercise) async {
          savedExercise = exercise;
        },
      );

      expect(result.outcome, equals(AddExerciseOutcome.success));
      expect(result.errorKey, isNull);
      expect(result.shouldCloseDialog, isTrue);
      expect(savedExercise, isNotNull);
      expect(savedExercise!.name, equals('Panca Inclinata'));
      expect(savedExercise!.userId, equals('user123'));
      expect(savedExercise!.isCustom, isTrue);
      expect(savedExercise!.type, equals(ExerciseType.strength));
    });
  });

  group('Il fallimento e visibile a schermo', () {
    // `handleAddExerciseSubmit` restituisce una chiave: dimostra la *decisione*,
    // non che qualcosa compaia. Il pezzo che restava senza prova e l'anello
    // successivo — un toast alzato col contesto del dialogo. `ToastUtils` usa
    // `Overlay.of`, e da dentro una rotta di dialogo quello e l'overlay del
    // Navigator: se non lo fosse, l'errore non si vedrebbe e questa storia
    // sarebbe finta.
    testWidgets('un toast alzato dal contesto del dialogo compare, e il dialogo resta aperto',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Nuovo esercizio'),
                    actions: [
                      TextButton(
                        onPressed: () => ToastUtils.showError(
                          dialogContext,
                          'errore di salvataggio',
                        ),
                        child: const Text('Salva'),
                      ),
                    ],
                  ),
                ),
                child: const Text('apri'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();
      expect(find.text('Nuovo esercizio'), findsOneWidget);

      await tester.tap(find.text('Salva'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('errore di salvataggio'),
        findsOneWidget,
        reason: 'il messaggio d\'errore deve essere presente nell\'albero',
      );
      expect(
        find.text('Nuovo esercizio'),
        findsOneWidget,
        reason: 'il dialogo non deve chiudersi quando il salvataggio fallisce',
      );

      // L'OverlayEntry si rimuove da sola dopo tre secondi: senza aspettarla il
      // test si chiude con un timer pendente.
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('AddExerciseDialog — il widget vero, montato', () {
    // Questo gruppo esiste perche la review di US-079 aveva dovuto dichiarare
    // come limite che la catena «errore → il dialogo resta aperto» era **letta e
    // non eseguita**: la schermata non si monta, e i test provavano la funzione
    // e un dialogo costruito nel file di test. Estraendo il dialogo in un widget
    // proprio — cosa fatta per correggere il ciclo di vita del controller — quel
    // limite si chiude.

    Future<void> apri(
      WidgetTester tester, {
      required Future<void> Function(Exercise) saveExercise,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [ExpressiveTokens()]),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AddExerciseDialog(
                    loc: const Localization(Locale('it')),
                    userId: 'utente-di-prova',
                    saveExercise: saveExercise,
                  ),
                ),
                child: const Text('apri'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();
    }

    testWidgets(
        '⭐ salvando, il dialogo si chiude senza usare il controller dopo il rilascio',
        (tester) async {
      // E la riproduzione del difetto. Prima della correzione questo test era
      // rosso con «A TextEditingController was used after being disposed»,
      // seguita da altre due eccezioni a cascata: in debug, schermata rossa.
      // Il controller veniva rilasciato subito dopo `await showDialog`, che si
      // completa alla chiusura della rotta e **non** a fine animazione.
      Exercise? salvato;
      await apri(tester, saveExercise: (e) async => salvato = e);

      await tester.enterText(find.byType(TextField), 'Panca piana');
      await tester.pump();
      await tester.tap(find.text('Salva'));

      // Senza `pumpAndSettle` per fermarsi **dentro** l'animazione di uscita,
      // che e la finestra in cui il difetto si manifestava.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull,
          reason: 'nessuna eccezione mentre il dialogo sfuma');

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'ne a transizione finita');

      expect(salvato?.name, 'Panca piana');
      expect(find.byType(AddExerciseDialog), findsNothing,
          reason: 'salvato, il dialogo si chiude');
    });

    testWidgets('con il servizio che solleva, il dialogo RESTA aperto e mostra l errore',
        (tester) async {
      await apri(tester,
          saveExercise: (_) async => throw Exception('permission-denied'));

      await tester.enterText(find.byType(TextField), 'Stacco');
      await tester.pump();
      await tester.tap(find.text('Salva'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byType(AddExerciseDialog),
        findsOneWidget,
        reason: 'il dialogo non deve chiudersi buttando il nome appena scritto',
      );
      expect(
        find.text("Errore durante il salvataggio dell'esercizio"),
        findsOneWidget,
        reason: 'e il fallimento deve essere visibile a schermo',
      );

      // Si lascia scadere l'OverlayEntry del toast, o resta un timer pendente.
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('il nome vuoto mostra l errore sotto il campo, e non salva',
        (tester) async {
      var chiamato = false;
      await apri(tester, saveExercise: (_) async => chiamato = true);

      await tester.tap(find.text('Salva'));
      await tester.pump();

      expect(chiamato, isFalse);
      expect(find.byType(AddExerciseDialog), findsOneWidget);
      expect(find.text("Inserisci un nome per l'esercizio"), findsOneWidget);

      // E scrivendo, l'errore se ne va.
      await tester.enterText(find.byType(TextField), 'P');
      await tester.pump();
      expect(find.text("Inserisci un nome per l'esercizio"), findsNothing);
    });
  });

  group('Verifica sorgente - Nessun catch inghiotte errori', () {
    test('in exercise_library_screen.dart nessun catch e muto o solo di log', () {
      final file = File('lib/src/ui/screens/exercise_library_screen.dart');
      expect(file.existsSync(), isTrue, reason: 'Il file exercise_library_screen.dart deve esistere');

      final source = file.readAsStringSync();

      // Cercare il solo `debugPrint` lascia passare il caso peggiore: un
      // `catch (e) {}` vuoto, o con dentro un commento, inghiotte piu di un
      // log e resterebbe verde. Quindi la regola e rovesciata: il corpo di un
      // catch deve *fare* qualcosa dell'errore — restituirlo, rilanciarlo, o
      // mostrarlo — e non solo registrarlo o tacere.
      final blocchiCatch = RegExp(
        r'catch\s*\([^)]*\)\s*\{([^{}]*)\}',
        dotAll: true,
      ).allMatches(source);

      // I corpi con graffe annidate non vengono esaminati: contengono per
      // definizione un blocco, e non sono il caso del catch muto.
      final muti = <String>[];
      for (final blocco in blocchiCatch) {
        final corpo = blocco
            .group(1)!
            .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
            .replaceAll(RegExp(r'//[^\n]*'), '')
            .trim();

        final faQualcosa = corpo.contains('return') ||
            corpo.contains('rethrow') ||
            corpo.contains('throw') ||
            corpo.contains('ToastUtils');

        if (!faQualcosa) {
          muti.add(corpo.isEmpty ? '(corpo vuoto)' : corpo);
        }
      }

      expect(
        muti,
        isEmpty,
        reason:
            'In exercise_library_screen.dart un catch non deve limitarsi a '
            'registrare l\'errore o a tacere. Trovati:\n${muti.join('\n---\n')}',
      );
    });
  });
}
