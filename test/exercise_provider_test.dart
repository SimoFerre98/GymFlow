import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/exercise_provider.dart';
import 'package:gymflow/src/models/exercise.dart';

Exercise custom(String id, {String name = 'Mio esercizio'}) {
  return Exercise(
    id: id,
    userId: 'utente1',
    name: name,
    description: '',
    type: ExerciseType.strength,
    musclesTargeted: const ['petto'],
    isCustom: true,
  );
}

/// Al posto dell'asset: i test non caricano `rootBundle`, che richiede il
/// binding e il file impacchettato. Cio che si verifica qui e **l'unione**, non
/// la lettura del JSON — quella ha gia 21 test suoi in `exercise_seed_test`.
class _FakeCurated extends CuratedExercises {
  _FakeCurated(this.items);

  final List<Exercise> items;

  @override
  Future<List<Exercise>> build() async => items;
}

/// Al posto di Firestore. Il costruttore `.offline` solleva un'eccezione, che e
/// cio che succede senza rete o senza permessi.
class _FakeCustom extends CustomExercises {
  _FakeCustom(this.items) : failing = false;
  _FakeCustom.offline() : items = const [], failing = true;

  final List<Exercise> items;
  final bool failing;

  @override
  Stream<List<Exercise>> build() {
    if (failing) {
      return Stream.error(Exception('permission-denied'));
    }
    return Stream.value(items);
  }
}

Exercise curated(String id, {String name = 'Panca piana'}) {
  return Exercise(
    id: id,
    name: name,
    description: '',
    type: ExerciseType.strength,
    musclesTargeted: const ['petto'],
    isCurated: true,
  );
}

void main() {
  Future<List<Exercise>> resolve(ProviderContainer container) async {
    // Le due sorgenti si attendono **prima** di leggere l'unione, altrimenti
    // si legge la prima passata, quando Firestore non ha ancora risposto.
    //
    // Non e un artificio del test: e il comportamento voluto nell'app. I curati
    // compaiono subito e gli esercizi dell'utente si aggiungono quando
    // arrivano, invece di tenere la libreria vuota ad aspettare la rete.
    await container.read(curatedExercisesProvider.future);
    try {
      await container.read(customExercisesProvider.future);
    } catch (_) {
      // Firestore ha rifiutato o la rete manca: e uno dei casi da verificare,
      // non un errore del test.
    }
    await container.read(exercisesProvider.future);
    return container.read(exercisesProvider).value ?? const [];
  }

  ProviderContainer containerWith({
    required List<Exercise> curatedItems,
    CustomExercises? customOverride,
  }) {
    final container = ProviderContainer(
      overrides: [
        curatedExercisesProvider.overrideWith(() => _FakeCurated(curatedItems)),
        if (customOverride != null)
          customExercisesProvider.overrideWith(() => customOverride),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('la libreria curata non passa da Firestore', () {
    test('senza nessun esercizio dell utente ci sono comunque i curati', () async {
      // E il primo avvio: nessuna scrittura, nessun pulsante premuto.
      final container = containerWith(
        curatedItems: [curated('ex_001'), curated('ex_002')],
        customOverride: _FakeCustom(const []),
      );

      final all = await resolve(container);
      expect(all, hasLength(2));
      expect(all.every((e) => e.isCurated), isTrue);
    });

    test('se Firestore rifiuta, i curati ci sono lo stesso', () async {
      // `permission-denied` e esattamente l'errore che l'utente ha visto
      // premendo il vecchio comando. La libreria non deve svuotarsi per questo.
      final container = containerWith(
        curatedItems: [curated('ex_001')],
        customOverride: _FakeCustom.offline(),
      );

      final all = await resolve(container);
      expect(all, hasLength(1));
      expect(all.single.id, 'ex_001');
    });
  });

  group('unione con gli esercizi dell utente', () {
    test('compaiono entrambi, e i personali restano personali', () async {
      final container = containerWith(
        curatedItems: [curated('ex_001'), curated('ex_002')],
        customOverride: _FakeCustom([custom('abc123')]),
      );

      final all = await resolve(container);
      expect(all, hasLength(3));

      final mine = all.firstWhere((e) => e.id == 'abc123');
      expect(mine.isCustom, isTrue);
      expect(mine.userId, 'utente1');
    });

    test('a parita di identificativo vince quello dell utente', () async {
      // L'unico dei due che qualcuno ha modificato di proposito.
      final container = containerWith(
        curatedItems: [curated('ex_001', name: 'Panca piana')],
        customOverride: _FakeCustom([custom('ex_001', name: 'La mia panca')]),
      );

      final all = await resolve(container);
      expect(all, hasLength(1), reason: 'un solo esercizio, non due');
      expect(all.single.name, 'La mia panca');
    });
  });

  group('indice per identificativo', () {
    test('contiene curati e personali', () async {
      final container = containerWith(
        curatedItems: [curated('ex_001')],
        customOverride: _FakeCustom([custom('abc123')]),
      );

      await resolve(container);
      // Letto dopo che l'elenco e pronto: l'indice lo segue.
      final index = container.read(exerciseIndexProvider);

      expect(index['ex_001'], isNotNull);
      expect(index['abc123'], isNotNull);
      expect(index['mai_visto'], isNull);
    });

    test('prima che l elenco sia pronto e vuoto, non nullo', () {
      // Una cella di lista non deve distinguere "sto caricando" da "non c'e":
      // in entrambi i casi disegna il segnaposto.
      final container = containerWith(
        curatedItems: [curated('ex_001')],
        customOverride: _FakeCustom(const []),
      );

      expect(container.read(exerciseIndexProvider), isEmpty);
    });
  });

  group('il percorso dell asset', () {
    test('punta al file della libreria curata', () {
      // Se il percorso cambiasse senza aggiornare `pubspec.yaml`, la libreria
      // sarebbe vuota su ogni dispositivo e nessun test se ne accorgerebbe.
      expect(kCuratedLibraryAsset, 'assets/data/exercises_seed.json');
    });
  });
}
