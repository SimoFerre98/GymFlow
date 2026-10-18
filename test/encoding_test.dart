import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nessun testo storpiato dalla codifica nel sorgente.
///
/// Trovato il 2026-08-11 guardando uno screenshot del telefono: nelle
/// impostazioni la lingua mostrava `Ã°Å¸â€¡Â®` al posto della bandiera italiana, e
/// un dialogo diceva «non puÃ² essere annullata». Non era un problema di resa:
/// quei byte erano **nel sorgente**, perche qualcuno aveva aperto e risalvato i
/// file leggendo UTF-8 come Latin-1.
///
/// Nessun test poteva vederlo. Quello sulla localizzazione controlla che ogni
/// chiave esista in EN e IT, non che il testo sia leggibile: una stringa
/// storpiata e presente in entrambe le lingue e lo supera senza problemi.
///
/// **Limite dichiarato**: riconosce la firma della doppia codifica UTF-8 letta
/// come Latin-1, che e la sola che si e presentata qui. Un file salvato in
/// UTF-16, o troncato a meta di un carattere, gli sfugge.
void main() {
  /// Le sequenze che nascono leggendo UTF-8 come Latin-1.
  ///
  /// `Ã` seguito da una lettera accentata copre `à è é ì ò ù`; `Ã°Å¸` e la testa
  /// di ogni emoji a quattro byte.
  final firme = <String, String>{
    r'Ã¨': 'e accentata',
    r'Ã©': 'e acuta',
    r'Ã ': 'a accentata',
    // `à` sono i byte C3 A0: letti come Latin-1 danno `Ã` e uno spazio **non
    // separabile** (U+00A0), non uno spazio normale. La riga qui sopra cerca
    // lo spazio normale e per questo non vide mai «AttivitÃ  Allenamento» e
    // «IntensitÃ  Media», rimasti nella scheda Dati fino al 2026-10-18, quando
    // si sono visti su uno screenshot del telefono. Il carattere e scritto
    // come escape perche, a occhio, le due righe sono identiche.
    'Ã\u00A0': 'a accentata (spazio non separabile)',
    r'Ã¬': 'i accentata',
    r'Ã²': 'o accentata',
    r'Ã¹': 'u accentata',
    r'Ã¼': 'u con dieresi',
    r'Ã±': 'n con tilde',
    r'ðŸ': 'emoji',
    r'â€™': 'apostrofo tipografico',
    r'â€œ': 'virgolette aperte',
  };

  test('nessun file sorgente contiene testo mal codificato', () {
    final colpevoli = <String>[];

    for (final cartella in ['lib', 'test']) {
      final dir = Directory(cartella);
      if (!dir.existsSync()) continue;

      for (final file in dir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        // Questo file **contiene** le sequenze per riconoscerle: e l'unico che
        // puo, e va escluso o si accusa da solo.
        if (file.path.endsWith('encoding_test.dart')) continue;

        final righe = file.readAsLinesSync();
        for (var i = 0; i < righe.length; i++) {
          for (final firma in firme.entries) {
            if (righe[i].contains(firma.key)) {
              colpevoli.add(
                '${file.path}:${i + 1} — ${firma.value}: ${righe[i].trim()}',
              );
            }
          }
        }
      }
    }

    expect(
      colpevoli,
      isEmpty,
      reason: 'il file va risalvato in UTF-8, e il testo riscritto:\n'
          '${colpevoli.join('\n')}',
    );
  });
}
