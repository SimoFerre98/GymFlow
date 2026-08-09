import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';

/// I tre file delle schermate principali trattati in questa storia.
const mainScreenFiles = [
  'lib/src/ui/screens/active_session_screen.dart',
  'lib/src/ui/screens/dashboard_screen.dart',
  'lib/src/ui/screens/calendar_screen.dart',
];

/// Stringhe letterali tecniche consentite, con motivazione.
///
/// Queste stringhe sono destinate ai log di debug o agli errori tecnici di
/// sviluppo e non sono testo dell'interfaccia utente.
const allowedTechnicalStrings = {
  'Error: \$err':
      'Errore tecnico di caricamento dati nella dashboard (log di debug per sviluppatori)',
  'Kg': 'Unità di misura del peso nelle tabelle degli esercizi (kilogrammi)',
  'Km': 'Unità di misura della distanza nelle tabelle cardio (kilometri)',
};

/// Estrae tutte le chiavi `t('...')` usate nei tre file delle schermate principali.
Set<String> usedKeysInMainScreens() {
  final keys = <String>{};
  final pattern = RegExp(r"\.t\('([^']+)'\)");

  for (final path in mainScreenFiles) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final source = file.readAsStringSync();
    for (final match in pattern.allMatches(source)) {
      final key = match.group(1)!;
      if (!key.contains(r'$')) {
        keys.add(key);
      }
    }
  }
  return keys;
}

void main() {
  group('US-026: Localizzazione schermate principali (test sul sorgente)', () {
    test('nessuna stringa letterale UI che comincia con maiuscola nei tre file',
        () {
      final unlocalized = <String>[];

      // Pattern per cercare Text('...'), Text("..."), label: Text('...'), helpText: '...', hintText: '...', tooltip: '...'
      final textPattern = RegExp(
        r"""(?:Text\(\s*['"]([A-Z][^'"]*)['"]|label:\s*Text\(\s*['"]([A-Z][^'"]*)['"]|helpText:\s*['"]([A-Z][^'"]*)['"]|hintText:\s*['"]([A-Z][^'"]*)['"]|tooltip:\s*['"]([A-Z][^'"]*)['"])""",
      );

      for (final path in mainScreenFiles) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path non esiste');
        final lines = file.readAsLinesSync();

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          for (final match in textPattern.allMatches(line)) {
            final matchedStr = match.group(1) ??
                match.group(2) ??
                match.group(3) ??
                match.group(4) ??
                match.group(5)!;

            if (allowedTechnicalStrings.containsKey(matchedStr)) {
              continue; // Stringa tecnica whitelistata
            }

            unlocalized.add('$path:${i + 1} -> "$matchedStr"');
          }
        }
      }

      expect(
        unlocalized,
        isEmpty,
        reason:
            'Stringhe letterali non localizzate trovate nei sorgenti delle schermate principali:\n'
            '${unlocalized.join('\n')}',
      );
    });

    test('nessun loc.t(...) e seguito da ?? (codice morto)', () {
      final deadNullCoalescing = <String>[];
      final deadPattern = RegExp(r"""\.t\('[^']+'\)\s*\?\?""");

      for (final path in mainScreenFiles) {
        final file = File(path);
        final lines = file.readAsLinesSync();

        for (var i = 0; i < lines.length; i++) {
          if (deadPattern.hasMatch(lines[i])) {
            deadNullCoalescing.add('$path:${i + 1}: ${lines[i].trim()}');
          }
        }
      }

      expect(
        deadNullCoalescing,
        isEmpty,
        reason:
            'Trovato loc.t(...) ?? in codice. loc.t non restituisce mai null, il ?? e codice morto:\n'
            '${deadNullCoalescing.join('\n')}',
      );
    });

    test('il ripiego su chiave mancante restituisce la chiave stessa', () {
      final locIt = Localization(const Locale('it'));
      final locEn = Localization(const Locale('en'));

      expect(locIt.t('chiave_inesistente_us026'), 'chiave_inesistente_us026');
      expect(locEn.t('chiave_inesistente_us026'), 'chiave_inesistente_us026');
    });

    test('tutte le chiavi usate nei tre file sono tradotte in EN e IT', () {
      final keys = usedKeysInMainScreens();
      expect(keys, isNotEmpty,
          reason: 'Devono essere presenti chiavi t(...) nei file principali');

      final locEn = Localization(const Locale('en'));
      final locIt = Localization(const Locale('it'));

      final missingEn = <String>[];
      final missingIt = <String>[];

      for (final key in keys) {
        if (locEn.t(key) == key) missingEn.add(key);
        if (locIt.t(key) == key) missingIt.add(key);
      }

      expect(
        missingEn,
        isEmpty,
        reason:
            'Chiavi usate nelle tre schermate ma mancanti in EN:\n${missingEn.join('\n')}',
      );
      expect(
        missingIt,
        isEmpty,
        reason:
            'Chiavi usate nelle tre schermate ma mancanti in IT:\n${missingIt.join('\n')}',
      );
    });
  });
}
