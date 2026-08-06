import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/ui/screens/exercise_library_screen.dart';

/// La libreria esercizi era raggiungibile da **un solo punto** in tutto il
/// codice, dentro la creazione di una scheda: tutto il materiale visivo di
/// EP-009 era di fatto invisibile. Questi test sorvegliano il punto d'ingresso.
///
/// Cosa NON coprono, e va detto: `ExerciseLibraryScreen` non e montabile in un
/// test, perche istanzia `FirestoreService` e `AuthService` nei campi e crea lo
/// stream dentro `build` — debito di US-008, US-009 e US-010÷US-012. Quindi il
/// tocco in consultazione e le stringhe a schermo restano **da confermare
/// sull'APK**.
void main() {
  group('modalita della schermata', () {
    test('per difetto e in consultazione, non in scelta', () {
      // E la modalita di chi arriva dal menu. Se il default cambiasse, dal menu
      // si aprirebbe una schermata che "sceglie" un esercizio per nessuno.
      const screen = ExerciseLibraryScreen();
      expect(screen.isSelecting, isFalse);
    });

    test('la creazione di una scheda la apre in scelta', () {
      const screen = ExerciseLibraryScreen(isSelecting: true);
      expect(screen.isSelecting, isTrue);
    });
  });

  group('testi della schermata e della voce di menu', () {
    const keys = [
      'exercises_menu',
      'exercises_title',
      'exercises_search',
      'exercises_empty',
    ];

    for (final locale in ['en', 'it']) {
      test('in $locale esistono tutte e quattro le chiavi', () {
        final loc = Localization(Locale(locale));
        for (final key in keys) {
          final value = loc.t(key);
          // `t` restituisce la chiave stessa quando manca: e il modo per
          // accorgersi di una traduzione dimenticata invece di vederla sparire.
          expect(
            value,
            isNot(key),
            reason: 'manca la traduzione $locale di $key',
          );
          expect(value.trim(), isNotEmpty);
        }
      });
    }

    test('le due lingue non dicono la stessa cosa', () {
      // Un copia-incolla dall'inglese all'italiano passerebbe il test sopra.
      final en = Localization(const Locale('en'));
      final it = Localization(const Locale('it'));
      expect(it.t('exercises_title'), isNot(en.t('exercises_title')));
      expect(it.t('exercises_search'), isNot(en.t('exercises_search')));
    });

    test('il vuoto dice cosa fare, non solo che non c e niente', () {
      // Con la libreria non ancora importata questo e il primo testo che
      // l'utente legge aprendo la voce nuova di menu.
      final it = Localization(const Locale('it'));
      expect(it.t('exercises_empty').toLowerCase(), contains('impostazioni'));
    });
  });
}
