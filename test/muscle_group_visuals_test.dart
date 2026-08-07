import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/muscle_group_visuals.dart';

void main() {
  group('normalizzazione del nome del gruppo', () {
    test('minuscole e spazi ai lati non contano', () {
      expect(MuscleGroupVisuals.normalize('  Chest '), 'chest');
      expect(MuscleGroupVisuals.normalize('SPALLE'), 'spalle');
    });

    test('gli spazi ripetuti diventano uno', () {
      expect(
        MuscleGroupVisuals.normalize('spalle   posteriori'),
        'spalle posteriori',
      );
    });

    test('trattini e trattini bassi valgono uno spazio', () {
      expect(MuscleGroupVisuals.normalize('lower-back'), 'lower back');
      expect(MuscleGroupVisuals.normalize('lower_back'), 'lower back');
    });

    test('gli accenti vengono appiattiti', () {
      expect(MuscleGroupVisuals.normalize('Glutèi'), 'glutei');
    });

    test('una stringa di soli spazi diventa vuota', () {
      expect(MuscleGroupVisuals.normalize('   '), isEmpty);
    });
  });

  group('copertura dei due vocabolari', () {
    // I nomi che stanno davvero nei dati: a sinistra la libreria curata
    // (assets/data/exercises_seed.json), a destra gli esercizi gia in Firestore
    // (firestore_service.dart). Se una di queste righe smette di passare, meta
    // della libreria e finita sul ripiego generico.
    const italiano = <String, BodyRegion>{
      'petto': BodyRegion.chest,
      'dorso': BodyRegion.back,
      'trapezio': BodyRegion.back,
      'spalle': BodyRegion.shoulders,
      'spalle posteriori': BodyRegion.shoulders,
      'bicipiti': BodyRegion.arms,
      'tricipiti': BodyRegion.arms,
      'quadricipiti': BodyRegion.legs,
      'femorali': BodyRegion.legs,
      'glutei': BodyRegion.legs,
      'polpacci': BodyRegion.legs,
      'addome': BodyRegion.core,
    };

    const inglese = <String, BodyRegion>{
      'Chest': BodyRegion.chest,
      'Back': BodyRegion.back,
      'Shoulders': BodyRegion.shoulders,
      'Biceps': BodyRegion.arms,
      'Triceps': BodyRegion.arms,
      'Quads': BodyRegion.legs,
      'Hamstrings': BodyRegion.legs,
      'Glutes': BodyRegion.legs,
      'Legs': BodyRegion.legs,
      'Heart': BodyRegion.cardio,
    };

    italiano.forEach((group, expected) {
      test('$group e ${expected.name}', () {
        expect(MuscleGroupVisuals.regionOfGroup(group), expected);
      });
    });

    inglese.forEach((group, expected) {
      test('$group e ${expected.name}', () {
        expect(MuscleGroupVisuals.regionOfGroup(group), expected);
      });
    });

    test('i dodici gruppi della libreria curata sono tutti riconosciuti', () {
      expect(italiano.keys.map(MuscleGroupVisuals.regionOfGroup), isNot(contains(null)));
    });

    test('un gruppo che non conosciamo si dichiara tale', () {
      // regionOfGroup non ripiega: e cio che permette a questo test di
      // misurare quanto vocabolario copriamo, invece di vedere sempre una
      // regione e crederla giusta.
      expect(MuscleGroupVisuals.regionOfGroup('sopracciglia'), isNull);
    });
  });

  group('scelta della regione di un esercizio', () {
    test('vince il primo gruppo della lista', () {
      expect(
        MuscleGroupVisuals.resolve(muscleGroups: const ['Chest', 'Triceps']),
        BodyRegion.chest,
      );
    });

    test('un primo gruppo ignoto non nasconde il secondo', () {
      expect(
        MuscleGroupVisuals.resolve(muscleGroups: const ['qualcosa', 'dorso']),
        BodyRegion.back,
      );
    });

    test('senza gruppi si ottiene comunque una regione', () {
      // Il criterio dice che il segnaposto non e mai un rettangolo vuoto:
      // vale anche per un esercizio personalizzato senza gruppi.
      expect(
        MuscleGroupVisuals.resolve(
          muscleGroups: const [],
          fallbackSeed: 'Trazioni alla sbarra',
        ),
        isA<BodyRegion>(),
      );
    });

    test('la lista vuota senza nemmeno un nome non fa cadere nulla', () {
      expect(
        MuscleGroupVisuals.resolve(muscleGroups: const []),
        isA<BodyRegion>(),
      );
    });

    test('i gruppi vuoti vengono ignorati', () {
      expect(
        MuscleGroupVisuals.resolve(muscleGroups: const ['', '  ', 'petto']),
        BodyRegion.chest,
      );
    });

    test('il ripiego e stabile: lo stesso esercizio ha sempre lo stesso aspetto', () {
      // Un segnaposto che cambia colore fra due aperture dell'app non e piu un
      // modo per riconoscere l'esercizio.
      final first = MuscleGroupVisuals.resolve(
        muscleGroups: const ['collo'],
      );
      for (var i = 0; i < 5; i++) {
        expect(
          MuscleGroupVisuals.resolve(muscleGroups: const ['collo']),
          first,
        );
      }
    });

    test('il ripiego distingue esercizi diversi', () {
      // Se tutti gli sconosciuti finissero nella stessa regione, il segnaposto
      // smetterebbe di dire qualcosa.
      final regions = <BodyRegion>{
        for (final seed in ['Plank laterale', 'Face pull', 'Hip thrust', 'Burpees'])
          MuscleGroupVisuals.resolve(muscleGroups: const [], fallbackSeed: seed),
      };
      expect(regions.length, greaterThan(1));
    });
  });

  group('aspetto di ogni regione', () {
    for (final region in BodyRegion.values) {
      test('${region.name} ha una sagoma valida', () {
        expect(region.glyph, isNotNull);
      });
    }

    test('le sette sagome sono tutte diverse', () {
      expect(BodyRegion.values.map((r) => r.glyph).toSet().length, 7);
    });
  });
}
