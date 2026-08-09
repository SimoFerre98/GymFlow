import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/ui/screens/exercise_library_screen.dart';

/// La funzione sotto esame e quella **della schermata**, non una sua copia.
///
/// Il primo tentativo di questo test montava un widget clone dentro il file di
/// test, perche la schermata istanzia `FirestoreService` nel proprio `State` e
/// non e montabile. Ma un test su una copia non sorveglia niente: verificato
/// rimettendo il difetto nel file vero, e il test restava verde. Da qui
/// l'estrazione della decisione in `exerciseLibraryViewFor`.
void main() {
  final esercizi = [
    Exercise(
      id: '1',
      name: 'Panca piana',
      description: '',
      type: ExerciseType.strength,
      musclesTargeted: const [],
    ),
  ];

  group('exerciseLibraryViewFor', () {
    test('caricamento senza nessun valore: la girella', () {
      expect(
        exerciseLibraryViewFor(const AsyncLoading<List<Exercise>>()),
        ExerciseLibraryView.loading,
      );
    });

    test('caricamento con un valore precedente: la lista resta', () {
      // E il cuore della storia. Uno `snapshots()` di Firestore emette due
      // volte all'apertura — cache e server — e a ogni emissione il provider
      // torna in caricamento pur avendo i dati. Con la condizione sbagliata la
      // lista veniva sostituita dalla girella e rimessa: lo sfarfallio.
      final ricarica = const AsyncLoading<List<Exercise>>().copyWithPrevious(
        AsyncData(esercizi),
      );

      expect(ricarica.isLoading, isTrue, reason: 'e davvero in caricamento');
      expect(ricarica.hasValue, isTrue, reason: 'e ha davvero un valore');
      expect(exerciseLibraryViewFor(ricarica), ExerciseLibraryView.list);
    });

    test('valore presente e non vuoto: la lista', () {
      expect(
        exerciseLibraryViewFor(AsyncData(esercizi)),
        ExerciseLibraryView.list,
      );
    });

    test('valore presente ma vuoto: il messaggio di lista vuota', () {
      expect(
        exerciseLibraryViewFor(const AsyncData<List<Exercise>>([])),
        ExerciseLibraryView.empty,
      );
    });

    test('errore con un valore precedente: la lista resta', () {
      // Non e un dettaglio: le regole Firestore negano al client la lettura
      // della collezione degli esercizi, e `permission-denied` e il caso reale
      // per cui US-072 esiste. La libreria curata deve restare visibile.
      final errore = AsyncError<List<Exercise>>('permission-denied', StackTrace.empty)
          .copyWithPrevious(AsyncData(esercizi));

      expect(exerciseLibraryViewFor(errore), ExerciseLibraryView.list);
    });
  });
}
