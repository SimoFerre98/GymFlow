import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/local/local_workout_program.dart';
import 'package:gymflow/src/models/local/local_workout_template.dart';
import 'package:gymflow/src/models/mappers/program_mapper.dart';
import 'package:gymflow/src/models/mappers/workout_mapper.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/workout_program.dart';

/// Chi ha scritto una scheda (US-113): `authorId` e `authorName`.
///
/// Il difetto da non innescare e uno solo, e non si vede in un round trip: le
/// schermate costruiscono un oggetto **nuovo** a ogni salvataggio e fanno
/// `update(toMap())`. Se `toMap()` scrivesse `authorId: null`, il cliente che
/// modifica una scheda ricevuta ne cancellerebbe l'autore — e le regole, che
/// vietano di cambiarlo, negherebbero il salvataggio. Per questo `toMap()`
/// **omette** la chiave quando e nulla.
void main() {
  WorkoutProgram programma({String? autore, String? nomeAutore, String nome = 'Forza'}) => WorkoutProgram(
    id: 'p1',
    userId: 'cliente',
    name: nome,
    workoutIds: const ['w1'],
    createdAt: DateTime.utc(2026, 10, 1),
    authorId: autore,
    authorName: nomeAutore,
  );

  WorkoutTemplate giorno({String? autore, String? nomeAutore}) => WorkoutTemplate(
    id: 'w1',
    userId: 'cliente',
    name: 'Lunedi',
    exercises: const [],
    category: ExerciseType.strength,
    authorId: autore,
    authorName: nomeAutore,
  );

  group('WorkoutProgram', () {
    test('senza autore toMap non scrive ne authorId ne authorName: nemmeno nulli', () {
      final mappa = programma().toMap();
      expect(mappa.containsKey('authorId'), isFalse, reason: 'una chiave nulla cancellerebbe l autore con update');
      expect(mappa.containsKey('authorName'), isFalse);
    });

    test('un nome senza autore non si scrive: il nome appartiene all autore', () {
      final mappa = programma(nomeAutore: 'Tina').toMap();
      expect(mappa.containsKey('authorName'), isFalse);
    });

    test('con l autore li scrive entrambi', () {
      final mappa = programma(autore: 't', nomeAutore: 'Tina').toMap();
      expect(mappa['authorId'], 't');
      expect(mappa['authorName'], 'Tina');
    });

    test('un documento senza i campi (scritto prima di US-113) si legge senza autore', () {
      final letto = WorkoutProgram.fromMap({'userId': 'c', 'name': 'Vecchia', 'workoutIds': []}, 'p1');
      expect(letto.authorId, isNull);
      expect(letto.authorName, isNull);
    });

    test('andata e ritorno su Firestore: l autore resta', () {
      final letto = WorkoutProgram.fromMap(programma(autore: 't', nomeAutore: 'Tina').toMap(), 'p1');
      expect(letto.authorId, 't');
      expect(letto.authorName, 'Tina');
    });

    test('copyWith non perde l autore', () {
      final copia = programma(autore: 't', nomeAutore: 'Tina').copyWith(name: 'Rinominata');
      expect(copia.name, 'Rinominata');
      expect(copia.authorId, 't');
      expect(copia.authorName, 'Tina');
    });

    test('il cliente che salva una scheda ricevuta ricostruendola da zero non tocca l autore sul documento', () {
      // Quello che fa `_saveProgram`: un oggetto nuovo, senza autore, e poi
      // `update(toMap())`. Firestore lascia intatti i campi che la mappa non
      // nomina: basta che `toMap()` non nomini `authorId`.
      final inviataAlCloud = programma(nome: 'Rinominata dal cliente').toMap();
      expect(inviataAlCloud.keys, isNot(contains('authorId')));
      expect(inviataAlCloud.keys, isNot(contains('authorName')));
    });
  });

  group('WorkoutTemplate', () {
    test('senza autore toMap non scrive le chiavi', () {
      final mappa = giorno().toMap();
      expect(mappa.containsKey('authorId'), isFalse);
      expect(mappa.containsKey('authorName'), isFalse);
    });

    test('con l autore li scrive, e si rileggono', () {
      final mappa = giorno(autore: 't', nomeAutore: 'Tina').toMap();
      expect(mappa['authorId'], 't');
      final letto = WorkoutTemplate.fromMap(mappa, 'w1');
      expect(letto.authorId, 't');
      expect(letto.authorName, 'Tina');
    });

    test('un documento senza i campi si legge senza autore', () {
      final letto = WorkoutTemplate.fromMap({'userId': 'c', 'name': 'Vecchio', 'exercises': [], 'category': 'strength'}, 'w1');
      expect(letto.authorId, isNull);
    });

    test('copyWith non perde l autore', () {
      final copia = giorno(autore: 't', nomeAutore: 'Tina').copyWith(name: 'Martedi');
      expect(copia.authorId, 't');
      expect(copia.authorName, 'Tina');
    });
  });

  group('cache locale (Isar): l autore sopravvive', () {
    test('programma: andata e ritorno con autore', () {
      final ripristinato = programma(autore: 't', nomeAutore: 'Tina').toLocal().toDomain();
      expect(ripristinato.authorId, 't');
      expect(ripristinato.authorName, 'Tina');
    });

    test('programma: senza autore resta senza', () {
      final ripristinato = programma().toLocal().toDomain();
      expect(ripristinato.authorId, isNull);
      expect(ripristinato.authorName, isNull);
    });

    test('il modello Isar del programma ha i due campi', () {
      final locale = programma(autore: 't', nomeAutore: 'Tina').toLocal();
      expect(locale.authorId, 't');
      expect(locale.authorName, 'Tina');
      expect(LocalWorkoutProgram().authorId, isNull, reason: 'nullabile: una collezione gia piena non si migra');
    });

    test('giorno: andata e ritorno con autore', () {
      final ripristinato = giorno(autore: 't', nomeAutore: 'Tina').toLocal().toDomain();
      expect(ripristinato.authorId, 't');
      expect(ripristinato.authorName, 'Tina');
    });

    test('giorno: senza autore resta senza, e il modello Isar e nullabile', () {
      final ripristinato = giorno().toLocal().toDomain();
      expect(ripristinato.authorId, isNull);
      expect(LocalWorkoutTemplate().authorId, isNull);
    });
  });
}
