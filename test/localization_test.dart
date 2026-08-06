import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';

/// Ogni chiave `t('...')` scritta nel codice, con il file in cui compare.
///
/// Legge il sorgente perche il problema che questo test esiste per impedire non
/// e una traduzione sbagliata: e una traduzione **dimenticata**. `t` restituisce
/// la chiave quando manca — scelta giusta, che rende il buco visibile invece di
/// farlo sparire — ma serve qualcuno che guardi, e la revisione umana ha gia
/// fallito tre volte in tre schermate diverse.
Map<String, List<String>> usedKeys() {
  final keys = <String, List<String>>{};
  final pattern = RegExp(r"\.t\('([^']+)'\)");

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = entity.readAsStringSync();
    for (final match in pattern.allMatches(source)) {
      final key = match.group(1)!;
      // Le chiavi costruite a runtime — `t('badge_name_${badge.id}')` — non
      // sono verificabili staticamente. Limite dichiarato.
      if (key.contains(r'$')) continue;
      keys.putIfAbsent(key, () => []).add(entity.path);
    }
  }
  return keys;
}

void main() {
  const locales = ['en', 'it'];

  group('nessuna chiave usata e senza traduzione', () {
    for (final code in locales) {
      test('in $code', () {
        final loc = Localization(Locale(code));
        final missing = <String>[];

        usedKeys().forEach((key, files) {
          // `t` restituisce la chiave stessa quando non la trova: e questo il
          // segnale che a schermo comparirebbe `rpe_label`.
          if (loc.t(key) == key) {
            missing.add('$key  (${files.toSet().join(', ')})');
          }
        });

        expect(
          missing,
          isEmpty,
          reason:
              'Chiavi usate nel codice e mai tradotte in $code:\n'
              '${missing.join('\n')}',
        );
      });
    }

    test('il controllo trova davvero qualcosa: chiavi ne esistono', () {
      // Se l'espressione regolare smettesse di trovare le chiavi, i test sopra
      // passerebbero su un insieme vuoto senza verificare nulla.
      expect(usedKeys().length, greaterThan(50));
    });

    test('una chiave inesistente viene riconosciuta come mancante', () {
      // La prova al contrario: senza, non sapremmo se il confronto funziona.
      final loc = Localization(const Locale('it'));
      expect(loc.t('chiave_che_non_esiste'), 'chiave_che_non_esiste');
    });
  });

  group('le due lingue restano allineate', () {
    test('ogni chiave italiana esiste in inglese e viceversa', () {
      final en = Localization(const Locale('en'));
      final it = Localization(const Locale('it'));

      final onlyOneSide = <String>[];
      for (final key in usedKeys().keys) {
        final inEn = en.t(key) != key;
        final inIt = it.t(key) != key;
        if (inEn != inIt) {
          onlyOneSide.add('$key (en: $inEn, it: $inIt)');
        }
      }

      expect(
        onlyOneSide,
        isEmpty,
        reason: 'Chiavi tradotte in una sola lingua:\n${onlyOneSide.join('\n')}',
      );
    });

    test('le traduzioni non sono la stessa parola in entrambe le lingue', () {
      // Un campione delle chiavi aggiunte da questa storia: un copia-incolla
      // dall'inglese passerebbe tutti i test sopra.
      final en = Localization(const Locale('en'));
      final it = Localization(const Locale('it'));

      for (final key in ['cancel', 'event_deleted', 'rpe_label']) {
        expect(it.t(key), isNot(en.t(key)), reason: key);
      }
    });
  });

  group('le undici chiavi che comparivano a schermo', () {
    const found = [
      'rpe_label',
      'cancel',
      'completed_at',
      'error_connecting',
      'error_deleting',
      'event_deleted',
      'friend_label',
      'gymflow_user',
      'login_required',
      'no_workouts_create_first',
      'scheduled_for',
    ];

    for (final code in locales) {
      test('sono tutte tradotte in $code', () {
        final loc = Localization(Locale(code));
        for (final key in found) {
          expect(loc.t(key), isNot(key), reason: key);
          expect(loc.t(key).trim(), isNotEmpty, reason: key);
        }
      });
    }

    test('rpe_label non si confonde con l intensita media', () {
      // Il valore che accompagna viene da calculateAverageRPE: e lo sforzo
      // percepito. Chiamarlo "intensita" lo confonderebbe con una voce che
      // esiste gia ed e un'altra cosa.
      final it = Localization(const Locale('it'));
      expect(it.t('rpe_label'), isNot(it.t('avg_intensity_label')));
    });
  });
}
