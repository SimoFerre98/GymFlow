import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('US-025: Unificazione schermate allenamenti (test sul sorgente)', () {
    test('home_screen.dart e stato eliminato', () {
      final homeScreenFile = File('lib/src/ui/screens/home_screen.dart');
      expect(
        homeScreenFile.existsSync(),
        isFalse,
        reason: 'home_screen.dart deve essere stato eliminato',
      );
    });

    test('nessun file in lib/ nomina HomeScreen', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final colpevoli = <String>[];
      final files = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Ignora i commenti di riga che spiegano la rimozione
          if (line.trimLeft().startsWith('//')) continue;
          if (line.contains('HomeScreen')) {
            colpevoli.add('${file.path}:${i + 1} -> ${line.trim()}');
          }
        }
      }

      expect(
        colpevoli,
        isEmpty,
        reason:
            'Nessun file in lib/ deve fare riferimento a HomeScreen. Trovati:\n'
            '${colpevoli.join('\n')}',
      );
    });

    test('main_screen.dart usa ProgramListScreen per la terza voce', () {
      final mainScreenFile = File('lib/src/ui/screens/main_screen.dart');
      expect(mainScreenFile.existsSync(), isTrue);

      final content = mainScreenFile.readAsStringSync();
      expect(
        content,
        isNot(contains('HomeScreen')),
        reason: 'main_screen.dart non deve piu usare HomeScreen',
      );

      // Cercare 'ProgramListScreen' nel file intero non basta: il test
      // resterebbe verde anche con la schermata montata sulla prima voce e il
      // Dashboard sulla terza, che e esattamente il difetto che US-025 chiude.
      // Quindi si estrae la lista _screens e si guarda la posizione.
      final listaScreens = RegExp(
        r'_screens\s*=\s*\[(.*?)\]',
        dotAll: true,
      ).firstMatch(content);
      expect(
        listaScreens,
        isNotNull,
        reason: 'la lista _screens di main_screen.dart non e stata trovata',
      );

      final voci = listaScreens!
          .group(1)!
          .split(',')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList();

      expect(
        voci.length,
        3,
        reason: 'la barra in basso ha tre voci: $voci',
      );
      expect(
        voci[2],
        contains('ProgramListScreen'),
        reason:
            'la terza voce della barra in basso deve essere ProgramListScreen, '
            'non ${voci[2]}',
      );
    });
  });
}
