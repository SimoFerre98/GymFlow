import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nessuna stringa di interfaccia scritta a mano nelle schermate secondarie.
///
/// Questo test **mancava**, e il piano di US-027 lo chiedeva. Senza di lui «tutte
/// le stringhe sono state sostituite» e una dichiarazione: alla prima misura ne
/// restavano undici, fra cui `Text('LOGIN')`, `Text('Male')` nel profilo e
/// quattro titoli di sezione in `program_creator_screen`.
///
/// **Limite dichiarato**: legge il sorgente e riconosce le forme piu comuni —
/// `Text('...')`, `labelText:`, `hintText:`, `title:`. Una stringa passata a un
/// widget per un'altra strada gli sfugge. Non sostituisce l'occhio sull'APK,
/// impedisce le ricadute.
void main() {
  const schermate = <String>[
    'lib/src/ui/screens/profile_screen.dart',
    'lib/src/ui/screens/login_screen.dart',
    'lib/src/ui/screens/register_screen.dart',
    'lib/src/ui/screens/program_creator_screen.dart',
    'lib/src/ui/screens/workout_creator_screen.dart',
    'lib/src/ui/screens/settings_screen.dart',
    'lib/src/ui/screens/friend_detail_screen.dart',
    'lib/src/ui/screens/health_detail_screen.dart',
  ];

  /// Le stringhe che **restano in inglese di proposito**, con il motivo.
  ///
  /// Questa lista e la parte importante del test: se cresce senza una ragione
  /// accanto, il test ha smesso di servire. Ogni voce va difesa in una review.
  const ammesse = <String, String>{
    'Google Fit / Health Connect':
        'nomi di prodotto: non si traducono, come non si traduce «Firebase»',
  };

  /// Le forme in cui una stringa arriva sotto gli occhi di un utente.
  final formeVisibili = RegExp(
    r"""(?:Text\(\s*|labelText:\s*|hintText:\s*|title:\s*)'([A-Z][^']{2,})'""",
  );

  for (final percorso in schermate) {
    test('${percorso.split('/').last} non ha stringhe di interfaccia a mano', () {
      final file = File(percorso);
      expect(file.existsSync(), isTrue, reason: '$percorso non esiste');

      final colpevoli = <String>[];
      final righe = file.readAsLinesSync();
      for (var i = 0; i < righe.length; i++) {
        final riga = righe[i];
        // Una stringa citata in un commento che spiega perche non c'e piu non e
        // una violazione.
        if (riga.trimLeft().startsWith('//')) continue;

        for (final trovata in formeVisibili.allMatches(riga)) {
          final testo = trovata.group(1)!;
          if (ammesse.containsKey(testo)) continue;
          colpevoli.add('${i + 1}: $testo');
        }
      }

      expect(
        colpevoli,
        isEmpty,
        reason: 'stringhe da portare nel dizionario, con la chiave in EN e IT:\n'
            '${colpevoli.join('\n')}',
      );
    });
  }

  test('ogni eccezione ammessa ha un motivo scritto', () {
    // Una lista di eccezioni senza motivi diventa il posto dove si nasconde
    // tutto cio che non si e voluto tradurre.
    for (final voce in ammesse.entries) {
      expect(
        voce.value.trim().length,
        greaterThan(15),
        reason: '«${voce.key}» e ammessa senza una ragione scritta',
      );
    }
  });
}
