import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/exercise_seed.dart';

String seed(String exercises) => '{"version": 1, "exercises": $exercises}';

void main() {
  group('il file vero della libreria curata', () {
    // Questo e il test che conta piu di tutti gli altri di questo gruppo: non
    // verifica un caso inventato, verifica il materiale che finira davvero in
    // Firestore. Se qualcuno tocca il JSON e sbaglia un URL, si scopre qui.
    late ExerciseSeedResult result;

    setUpAll(() {
      final file = File('assets/data/exercises_seed.json');
      result = ExerciseSeed.parse(file.readAsStringSync());
    });

    test('contiene 43 esercizi, tutti leggibili', () {
      expect(result.exercises.length, 43);
    });

    test('nessuno viene scartato', () {
      expect(
        result.issues,
        isEmpty,
        reason: result.issues.map((i) => i.toString()).join('\n'),
      );
    });

    test('quindici hanno un video vero, ventotto la sola ricerca', () {
      // La proporzione dichiarata nel documento di passaggio. Se cambia senza
      // che nessuno lo sappia, questo test lo dice.
      expect(result.withVideo, 15);
      expect(result.withSearchOnly, 28);
    });

    test('ognuno ha nome, tipo e gruppi muscolari', () {
      for (final e in result.exercises) {
        expect(e.name.trim(), isNotEmpty, reason: e.id);
        expect(e.musclesTargeted, isNotEmpty, reason: e.id);
      }
    });

    test('tutti sono curati e nessuno appartiene a un utente', () {
      // E cio che li distingue dagli esercizi creati dagli utenti, ed e anche
      // cio che li fa comparire nella libreria di tutti.
      for (final e in result.exercises) {
        expect(e.isCurated, isTrue, reason: e.id);
        expect(e.isCustom, isFalse, reason: e.id);
        expect(e.userId, isNull, reason: e.id);
      }
    });

    test('gli identificativi sono univoci: l import non puo duplicare', () {
      final ids = result.exercises.map((e) => e.id).toSet();
      expect(ids.length, result.exercises.length);
    });

    test('due letture danno gli stessi identificativi', () {
      // L'idempotenza dell'import nasce qui: stesso file, stessi documenti.
      final again = ExerciseSeed.parse(
        File('assets/data/exercises_seed.json').readAsStringSync(),
      );
      expect(
        again.exercises.map((e) => e.id).toList(),
        result.exercises.map((e) => e.id).toList(),
      );
    });

    test('chi ha un video produce sempre una miniatura', () {
      // Da quando 39 esercizi hanno anche una foto bundlata, la foto vince
      // sulla miniatura del video — e un asset locale, non richiede rete.
      // Chi non ha ancora una foto ripiega sulla miniatura YouTube.
      final withVideo = result.exercises.where((e) => e.hasSpecificVideo);
      for (final e in withVideo) {
        expect(
          e.thumbnailUrl,
          anyOf(startsWith('assets/'), contains('img.youtube.com')),
          reason: e.id,
        );
      }
    });
  });

  group('validazione dei video', () {
    test('una ricerca messa nel campo del video viene scartata', () {
      // E l'errore piu probabile su questo file: il primo giro di materiale
      // conteneva 43 ricerche in videoUrl.
      final r = ExerciseSeed.parse(
        seed('''[{
          "id": "ex_001",
          "name": "Panca piana",
          "type": "strength",
          "muscleGroups": ["petto"],
          "videoUrl": "https://www.youtube.com/results?search_query=panca+piana"
        }]'''),
      );

      expect(r.exercises.single.videoUrl, isNull);
      expect(r.issues.single.field, 'videoUrl');
      expect(r.issues.single.reason, contains('ricerca'));
      // L'esercizio resta valido: si scarta il video, non l'esercizio.
      expect(r.exercises.single.name, 'Panca piana');
    });

    test('un dominio che non e YouTube viene scartato', () {
      final r = ExerciseSeed.parse(
        seed('''[{
          "id": "ex_001", "name": "Squat", "type": "strength",
          "muscleGroups": ["quadricipiti"],
          "videoUrl": "https://vimeo.com/123456789"
        }]'''),
      );

      expect(r.exercises.single.videoUrl, isNull);
      expect(r.issues.single.reason, contains('YouTube'));
    });

    test('lo scarto dice quale esercizio e quale valore', () {
      final r = ExerciseSeed.parse(
        seed('''[{
          "id": "ex_042", "name": "Plank", "type": "timed",
          "muscleGroups": ["addome"],
          "videoUrl": "non-un-url"
        }]'''),
      );

      final issue = r.issues.single;
      expect(issue.exerciseId, 'ex_042');
      expect(issue.value, 'non-un-url');
      // Senza il valore, correggere il file significherebbe cercarlo a mano.
      expect(issue.toString(), contains('ex_042'));
    });

    test('un video valido passa intatto', () {
      final r = ExerciseSeed.parse(
        seed('''[{
          "id": "ex_001", "name": "Panca piana", "type": "strength",
          "muscleGroups": ["petto"],
          "videoUrl": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        }]'''),
      );

      expect(r.issues, isEmpty);
      expect(r.exercises.single.hasSpecificVideo, isTrue);
    });
  });

  group('voci che non si possono importare', () {
    test('senza identificativo viene saltata: non ci sarebbe idempotenza', () {
      final r = ExerciseSeed.parse(
        seed('[{"name": "Senza id", "type": "strength", "muscleGroups": []}]'),
      );

      expect(r.exercises, isEmpty);
      expect(r.issues.single.field, 'id');
    });

    test('senza nome viene saltata', () {
      final r = ExerciseSeed.parse(
        seed('[{"id": "ex_001", "name": "  ", "type": "strength"}]'),
      );

      expect(r.exercises, isEmpty);
      expect(r.issues.any((i) => i.field == 'name'), isTrue);
    });

    test('un tipo sconosciuto viene saltato invece che indovinato', () {
      // Il modello ripiega su "strength" quando legge da Firestore, che va bene
      // per un documento gia salvato. In importazione no: inventare il tipo di
      // un esercizio significa sbagliare la schermata di registrazione.
      final r = ExerciseSeed.parse(
        seed('''[{
          "id": "ex_001", "name": "Qualcosa", "type": "pilates",
          "muscleGroups": ["addome"]
        }]'''),
      );

      expect(r.exercises, isEmpty);
      expect(r.issues.single.field, 'type');
      expect(r.issues.single.value, 'pilates');
    });

    test('un identificativo ripetuto non sovrascrive il primo', () {
      final r = ExerciseSeed.parse(
        seed('''[
          {"id": "ex_001", "name": "Primo", "type": "strength", "muscleGroups": ["petto"]},
          {"id": "ex_001", "name": "Secondo", "type": "strength", "muscleGroups": ["dorso"]}
        ]'''),
      );

      expect(r.exercises.single.name, 'Primo');
      expect(r.issues.single.reason, contains('ripetuto'));
    });

    test('senza gruppi muscolari si importa lo stesso, ma lo si dice', () {
      // Il segnaposto ripiega sul nome: l'esercizio e utilizzabile, solo meno
      // riconoscibile a colpo d'occhio.
      final r = ExerciseSeed.parse(
        seed('[{"id": "ex_001", "name": "Qualcosa", "type": "strength", "muscleGroups": []}]'),
      );

      expect(r.exercises.single.musclesTargeted, isEmpty);
      expect(r.issues.single.field, 'muscleGroups');
    });
  });

  group('file rotto', () {
    test('un file che non e JSON non fa cadere l app', () {
      final r = ExerciseSeed.parse('questo non e json');

      expect(r.exercises, isEmpty);
      expect(r.issues.single.field, 'file');
    });

    test('un file senza l elenco degli esercizi lo dice', () {
      final r = ExerciseSeed.parse('{"version": 1}');

      expect(r.exercises, isEmpty);
      expect(r.issues.single.field, 'exercises');
    });

    test('una voce che non e un oggetto viene saltata, le altre no', () {
      final r = ExerciseSeed.parse(
        seed('''[
          "una stringa",
          {"id": "ex_001", "name": "Buono", "type": "strength", "muscleGroups": ["petto"]}
        ]'''),
      );

      // Una riga sbagliata non deve far perdere le altre quarantadue.
      expect(r.exercises.single.name, 'Buono');
      expect(r.issues, hasLength(1));
    });
  });

  group('conversione verso Firestore', () {
    test('l esercizio importato sopravvive al viaggio di andata e ritorno', () {
      final r = ExerciseSeed.parse(
        seed('''[{
          "id": "ex_001", "name": "Panca piana", "type": "strength",
          "muscleGroups": ["petto", "tricipiti"],
          "videoUrl": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
          "videoSearchQuery": "panca piana bilanciere"
        }]'''),
      );

      final original = r.exercises.single;
      final back = Exercise.fromMap(original.toMap(), original.id);

      expect(back.name, original.name);
      expect(back.type, original.type);
      expect(back.musclesTargeted, original.musclesTargeted);
      expect(back.videoUrl, original.videoUrl);
      expect(back.videoSearchQuery, original.videoSearchQuery);
      expect(back.isCurated, isTrue);
    });
  });
}
