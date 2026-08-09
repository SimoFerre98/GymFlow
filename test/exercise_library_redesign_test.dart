import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/ui/screens/exercise_library_screen.dart';

void main() {
  group('US-065: Estrazione gruppi muscolari dai dati', () {
    test('estrate i gruppi muscolari ordinati per frequenza decrescente', () {
      final exercises = [
        Exercise(
          id: '1',
          name: 'Panca piana',
          description: '',
          type: ExerciseType.strength,
          musclesTargeted: const ['Petto', 'Tricipiti'],
        ),
        Exercise(
          id: '2',
          name: 'Panca inclinata',
          description: '',
          type: ExerciseType.strength,
          musclesTargeted: const ['Petto', 'Spalle'],
        ),
        Exercise(
          id: '3',
          name: 'Croci ai cavi',
          description: '',
          type: ExerciseType.strength,
          musclesTargeted: const ['Petto'],
        ),
        Exercise(
          id: '4',
          name: 'Military Press',
          description: '',
          type: ExerciseType.strength,
          musclesTargeted: const ['Spalle', 'Tricipiti'],
        ),
      ];

      final result = extractMuscleGroups(exercises);

      // Petto compare 3 volte, Spalle 2, Tricipiti 2.
      expect(result.first, 'Petto');
      expect(result.contains('Spalle'), isTrue);
      expect(result.contains('Tricipiti'), isTrue);
    });

    test('include gruppi muscolari inattesi senza lista fissa', () {
      final exercises = [
        Exercise(
          id: '1',
          name: 'Esercizio speciale',
          description: '',
          type: ExerciseType.strength,
          musclesTargeted: const ['GruppoInsolito'],
        ),
      ];

      final result = extractMuscleGroups(exercises);
      expect(result, contains('GruppoInsolito'));
    });
  });

  group('US-065: Filtro esercizi', () {
    final testExercises = [
      Exercise(
        id: '1',
        name: 'Panca piana',
        description: '',
        type: ExerciseType.strength,
        musclesTargeted: const ['Petto', 'Tricipiti'],
        isCustom: false,
        videoUrl: 'https://www.youtube.com/watch?v=12345678901',
      ),
      Exercise(
        id: '2',
        name: 'Panca inclinata custom',
        description: '',
        type: ExerciseType.strength,
        musclesTargeted: const ['Petto'],
        isCustom: true,
        videoUrl: 'https://www.youtube.com/watch?v=12345678901',
      ),
      Exercise(
        id: '3',
        name: 'Squat',
        description: '',
        type: ExerciseType.strength,
        musclesTargeted: const ['Gambe'],
        isCustom: false,
      ),
    ];

    test('filtra per gruppo muscolare selezionato', () {
      final filtered = filterExercises(
        exercises: testExercises,
        searchQuery: '',
        segment: ExerciseSegmentFilter.all,
        selectedMuscleGroup: 'Petto',
      );

      expect(filtered.length, 2);
      expect(filtered.every((e) => e.musclesTargeted.contains('Petto')), isTrue);
    });

    test('segmentato Miei restituisce solo esercizi custom', () {
      final filtered = filterExercises(
        exercises: testExercises,
        searchQuery: '',
        segment: ExerciseSegmentFilter.mine,
      );

      expect(filtered.length, 1);
      expect(filtered.first.name, 'Panca inclinata custom');
      expect(filtered.first.isCustom, isTrue);
    });

    test('segmentato Recenti restituisce lista vuota come dichiarato', () {
      final filtered = filterExercises(
        exercises: testExercises,
        searchQuery: '',
        segment: ExerciseSegmentFilter.recent,
      );

      expect(filtered, isEmpty);
    });

    test('combina ricerca testo, segmentato e gruppo muscolare', () {
      final filtered = filterExercises(
        exercises: testExercises,
        searchQuery: 'panca',
        segment: ExerciseSegmentFilter.mine,
        selectedMuscleGroup: 'Petto',
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, '2');
    });
  });

  group('US-065: Costruzione stringa di dettaglio', () {
    const locIT = Localization(Locale('it'));
    const locEN = Localization(Locale('en'));

    test('caso 1: con video e non tuo (solo gruppi muscolari)', () {
      final ex = Exercise(
        id: '1',
        name: 'Panca piana',
        description: '',
        type: ExerciseType.strength,
        musclesTargeted: const ['Petto', 'Tricipiti'],
        isCustom: false,
        videoUrl: 'https://www.youtube.com/watch?v=12345678901',
      );

      expect(buildExerciseSubtitleText(ex, locIT), 'Petto · Tricipiti');
      expect(buildExerciseSubtitleText(ex, locEN), 'Petto · Tricipiti');
    });

    test('caso 2: senza video e non tuo (gruppi + senza video)', () {
      final ex = Exercise(
        id: '2',
        name: 'Croci ai cavi',
        description: '',
        type: ExerciseType.strength,
        musclesTargeted: const ['Petto'],
        isCustom: false,
      );

      expect(buildExerciseSubtitleText(ex, locIT), 'Petto · senza video');
      expect(buildExerciseSubtitleText(ex, locEN), 'Petto · no video');
    });

    test('caso 3: con video e tuo (gruppi + tuo)', () {
      final ex = Exercise(
        id: '3',
        name: 'Panca inclinata',
        description: '',
        type: ExerciseType.strength,
        musclesTargeted: const ['Petto alto'],
        isCustom: true,
        videoUrl: 'https://www.youtube.com/watch?v=12345678901',
      );

      expect(buildExerciseSubtitleText(ex, locIT), 'Petto alto · tuo');
      expect(buildExerciseSubtitleText(ex, locEN), 'Petto alto · yours');
    });

    test('caso 4: senza video e tuo (gruppi + tuo + senza video)', () {
      final ex = Exercise(
        id: '4',
        name: 'Variante custom',
        description: '',
        type: ExerciseType.strength,
        musclesTargeted: const ['Spalle'],
        isCustom: true,
      );

      expect(
        buildExerciseSubtitleText(ex, locIT),
        'Spalle · tuo · senza video',
      );
      expect(
        buildExerciseSubtitleText(ex, locEN),
        'Spalle · yours · no video',
      );
    });
  });

  group('US-065: Ispezione statica sorgente per token e convenzioni', () {
    test('nessun colore letterale fuori da Colors.transparent', () {
      final file = File('lib/src/ui/screens/exercise_library_screen.dart');
      final source = file.readAsStringSync();

      final colorMatches = RegExp(r'Colors\.([a-zA-Z]+)').allMatches(source);
      for (final match in colorMatches) {
        final colorName = match.group(1);
        expect(
          colorName,
          'transparent',
          reason: 'Trovato colore letterale Colors.$colorName nel sorgente',
        );
      }
    });

    test('nessuna misura o padding scritti a mano con EdgeInsets.all/symmetric numerico', () {
      final file = File('lib/src/ui/screens/exercise_library_screen.dart');
      final source = file.readAsStringSync();

      final rawEdgeInsets = RegExp(r'EdgeInsets\.(all|symmetric|only)\(\s*[0-9]').hasMatch(source);
      expect(
        rawEdgeInsets,
        isFalse,
        reason: 'Trovato EdgeInsets con misura numerica hardcoded nel sorgente',
      );
    });
  });

  group('US-065: i tre vuoti dicono cose diverse', () {
    // Correzione di review. Con un filtro attivo che non trova niente la
    // schermata diceva «non ci sono ancora esercizi, caricali dalle
    // impostazioni»: falso, e manda l'utente a rifare una cosa gia fatta.
    const en = Localization(Locale('en'));
    const it = Localization(Locale('it'));

    test('i tre messaggi sono distinti e tradotti in EN e IT', () {
      for (final loc in [en, it]) {
        final vuoto = loc.t('exercises_empty');
        final nessunaCorrispondenza = loc.t('exercises_no_match');
        final nessunoStorico = loc.t('exercises_recent_empty');

        // Nessuna delle tre torna la chiave: `t` restituisce la chiave quando
        // la traduzione manca, ed e cosi che una stringa non tradotta finisce
        // a schermo.
        expect(vuoto, isNot('exercises_empty'));
        expect(nessunaCorrispondenza, isNot('exercises_no_match'));
        expect(nessunoStorico, isNot('exercises_recent_empty'));

        expect({vuoto, nessunaCorrispondenza, nessunoStorico}, hasLength(3),
            reason: 'i tre vuoti non devono dire la stessa cosa');
      }
    });

    test('solo il vuoto della libreria manda alle impostazioni', () {
      // E il messaggio che invita a caricare la libreria curata: deve comparire
      // soltanto quando di esercizi non ce n'e davvero nessuno.
      expect(en.t('exercises_empty').toLowerCase(), contains('settings'));
      expect(it.t('exercises_empty').toLowerCase(), contains('impostazioni'));

      expect(en.t('exercises_no_match').toLowerCase(), isNot(contains('settings')));
      expect(it.t('exercises_no_match').toLowerCase(),
          isNot(contains('impostazioni')));
    });
  });
}
