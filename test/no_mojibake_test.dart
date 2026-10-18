import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nessun testo in `lib/` ha gli accenti corrotti.
///
/// «Attività» scritto come «AttivitÃ » e «Intensità» come «IntensitÃ » sono
/// rimasti nell'interfaccia (la scheda Dati) senza che nessun test se ne
/// accorgesse: erano UTF-8 letto come Latin-1 e riscritto, un difetto che si
/// vede solo guardando lo schermo. Il segno e sempre lo stesso — una `Ã`, una
/// `Â` o una `â€` dove c'era una lettera accentata o una virgoletta.
///
/// **Limite dichiarato**: cerca solo la corruzione di questo tipo. Non scopre
/// un refuso, né una traduzione sbagliata.
void main() {
  final segni = <String>['Ã', 'Â', 'â€', '�'];

  test('nessun file di lib/ contiene segni di UTF-8 corrotto', () {
    final colpevoli = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final righe = file.readAsLinesSync();
      for (var i = 0; i < righe.length; i++) {
        for (final segno in segni) {
          if (righe[i].contains(segno)) {
            colpevoli.add('${file.path}:${i + 1}  (${segno.codeUnits.map((c) => 'U+${c.toRadixString(16).toUpperCase()}').join(' ')})');
          }
        }
      }
    }
    expect(colpevoli, isEmpty, reason: 'testo corrotto:\n${colpevoli.join('\n')}');
  });

  test('le due stringhe che erano corrotte ora hanno l accento giusto', () {
    final sorgente = File('lib/src/core/providers/localization_provider.dart').readAsStringSync();
    expect(sorgente, contains("'avg_intensity_label': 'Intensità Media'"));
    expect(sorgente, contains("'workout_activity_chart': 'Attività Allenamento'"));
  });
}
