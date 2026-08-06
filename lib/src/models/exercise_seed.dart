import 'dart:convert';

import 'exercise.dart';
import 'exercise_media.dart';

/// Lettura e validazione della libreria di esercizi curata.
///
/// Sta in un file a se, senza dipendenze da Flutter e da Firestore, per una
/// ragione pratica: cosi la validazione si prova leggendo il file vero in un
/// test da tre righe, invece che eseguendo un'importazione e guardando cosa e
/// finito nel database.
abstract final class ExerciseSeed {
  /// Legge il contenuto di `assets/data/exercises_seed.json`.
  ///
  /// Non solleva eccezioni per un esercizio malformato: lo **scarta e lo
  /// annota**. Un file con una riga sbagliata deve importare le altre
  /// quarantadue, non fallire per intero.
  static ExerciseSeedResult parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      return ExerciseSeedResult(
        exercises: const [],
        issues: [
          SeedIssue(
            exerciseId: '—',
            field: 'file',
            value: '',
            reason: 'il file non e JSON valido: ${e.message}',
          ),
        ],
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return ExerciseSeedResult(
        exercises: const [],
        issues: const [
          SeedIssue(
            exerciseId: '—',
            field: 'file',
            value: '',
            reason: 'la radice del file non e un oggetto',
          ),
        ],
      );
    }

    final raw = decoded['exercises'];
    if (raw is! List) {
      return ExerciseSeedResult(
        exercises: const [],
        issues: const [
          SeedIssue(
            exerciseId: '—',
            field: 'exercises',
            value: '',
            reason: 'manca l elenco degli esercizi',
          ),
        ],
      );
    }

    final exercises = <Exercise>[];
    final issues = <SeedIssue>[];
    final seenIds = <String>{};

    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) {
        issues.add(
          const SeedIssue(
            exerciseId: '—',
            field: 'esercizio',
            value: '',
            reason: 'la voce non e un oggetto',
          ),
        );
        continue;
      }

      final id = (entry['id'] as String?)?.trim() ?? '';
      final name = (entry['name'] as String?)?.trim() ?? '';

      // Senza identificativo non c'e idempotenza: l'import creerebbe un
      // documento nuovo a ogni esecuzione.
      if (id.isEmpty) {
        issues.add(
          SeedIssue(
            exerciseId: '—',
            field: 'id',
            value: name,
            reason: 'esercizio senza identificativo, saltato',
          ),
        );
        continue;
      }

      if (!seenIds.add(id)) {
        issues.add(
          SeedIssue(
            exerciseId: id,
            field: 'id',
            value: id,
            reason: 'identificativo ripetuto, la seconda voce e stata saltata',
          ),
        );
        continue;
      }

      if (name.isEmpty) {
        issues.add(
          SeedIssue(
            exerciseId: id,
            field: 'name',
            value: '',
            reason: 'esercizio senza nome, saltato',
          ),
        );
        continue;
      }

      final groups = _groupsOf(entry['muscleGroups']);
      if (groups.isEmpty) {
        // Non e un motivo per saltarlo: il segnaposto ripiega sul nome. Ma va
        // detto, perche significa una miniatura meno riconoscibile.
        issues.add(
          SeedIssue(
            exerciseId: id,
            field: 'muscleGroups',
            value: '',
            reason: 'nessun gruppo muscolare',
          ),
        );
      }

      final type = _typeOf(entry['type']);
      if (type == null) {
        issues.add(
          SeedIssue(
            exerciseId: id,
            field: 'type',
            value: '${entry['type']}',
            reason: 'tipo sconosciuto, esercizio saltato',
          ),
        );
        continue;
      }

      // Il video si accetta solo se e davvero un video. Un URL di ricerca
      // finito in questo campo produrrebbe una miniatura inesistente e un
      // indicatore che promette l'esecuzione senza averla.
      final rawVideo = (entry['videoUrl'] as String?)?.trim();
      String? videoUrl;
      if (rawVideo != null && rawVideo.isNotEmpty) {
        if (YouTubeVideo.isVideoUrl(rawVideo)) {
          videoUrl = rawVideo;
        } else {
          issues.add(
            SeedIssue(
              exerciseId: id,
              field: 'videoUrl',
              value: rawVideo,
              reason: YouTubeVideo.searchQueryOf(rawVideo) != null
                  ? 'e una ricerca, non un video: scartato'
                  : 'non e un indirizzo YouTube riconoscibile: scartato',
            ),
          );
        }
      }

      final searchQuery = (entry['videoSearchQuery'] as String?)?.trim();
      final imageUrl = (entry['imageUrl'] as String?)?.trim();

      exercises.add(
        Exercise(
          id: id,
          name: name,
          description: '',
          type: type,
          videoUrl: videoUrl,
          videoSearchQuery: (searchQuery == null || searchQuery.isEmpty)
              ? null
              : searchQuery,
          imageUrl: (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
          musclesTargeted: groups,
          // Curato: nessun utente lo possiede, e la libreria lo mostra a tutti.
          isCustom: false,
          isCurated: true,
        ),
      );
    }

    return ExerciseSeedResult(exercises: exercises, issues: issues);
  }

  static List<String> _groupsOf(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();
  }

  static ExerciseType? _typeOf(Object? raw) {
    if (raw is! String) return null;
    final wanted = raw.trim().toLowerCase();
    for (final type in ExerciseType.values) {
      if (type.name == wanted) return type;
    }
    return null;
  }
}

/// Cosa e stato letto, e cosa e stato scartato leggendolo.
class ExerciseSeedResult {
  const ExerciseSeedResult({required this.exercises, required this.issues});

  final List<Exercise> exercises;

  /// Gli scarti, con il motivo. Il criterio di accettazione chiede che siano
  /// **elencati**, non contati: un URL scartato in silenzio e un video che
  /// nessuno sa di aver perso.
  final List<SeedIssue> issues;

  /// Quanti esercizi porteranno una miniatura vera invece del segnaposto.
  int get withVideo => exercises.where((e) => e.hasSpecificVideo).length;

  /// Quanti apriranno una ricerca invece dell'esecuzione.
  int get withSearchOnly => exercises
      .where((e) => !e.hasSpecificVideo && e.videoSearchQuery != null)
      .length;
}

/// Una cosa scartata durante la lettura, con abbastanza contesto da poterla
/// correggere nel file senza cercarla.
class SeedIssue {
  const SeedIssue({
    required this.exerciseId,
    required this.field,
    required this.value,
    required this.reason,
  });

  final String exerciseId;
  final String field;
  final String value;
  final String reason;

  @override
  String toString() => '$exerciseId · $field: $reason';
}
