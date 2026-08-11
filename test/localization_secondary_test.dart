import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nessuna stringa di interfaccia scritta a mano nelle schermate secondarie.
///
/// Questo test **mancava**, e il piano di US-027 lo chiedeva. Senza di lui «tutte
/// le stringhe sono state sostituite» e una dichiarazione: alla prima misura ne
/// restavano diciassette, fra cui `Text('LOGIN')`, `Text('Male')` nel profilo e
/// quattro titoli di sezione in `program_creator_screen`.
///
/// **La prima versione di questo test leggeva riga per riga** e riconosceva solo
/// `Text('...')`, `labelText:`, `hintText:` e `title:`. Sono le forme piu comuni,
/// ma non le uniche: `Text(` seguito dalla stringa **sulla riga dopo** — che e
/// come `dart format` spezza le righe lunghe — non veniva visto, e nemmeno una
/// stringa passata come argomento a un widget interno (`_buildStatCard(context,
/// 'Streak', ...)`). Cosi il test e diventato verde con almeno quaranta stringhe
/// ancora in inglese: **un test che riconosce una forma sola sorveglia una forma
/// sola.**
///
/// Ora la rete e rovesciata: si guarda **ogni** letterale che comincia per
/// maiuscola, e cio che non deve finire a schermo va dichiarato — o per il
/// contesto in cui compare, o per nome in [ammesse]. La lista delle eccezioni e
/// la parte importante del test: se cresce senza una ragione accanto, il test ha
/// smesso di servire.
///
/// **Limite dichiarato**: resta un test sul sorgente. Non prova che le
/// traduzioni siano buone, ne che l'interfaccia si aggiorni cambiando lingua —
/// quello lo prova `si aggiorna cambiando lingua senza riavviare` in
/// `localization_live_switch_test.dart`. E una stringa che comincia per
/// minuscola gli sfugge ancora.
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

  /// I contesti in cui un letterale **non arriva sotto gli occhi di nessuno**.
  ///
  /// Si escludono per il posto in cui stanno, non per come sono scritti: e la
  /// distinzione fra un testo e un dato, che e la parte difficile di questa
  /// storia.
  const contestiTecnici = <String, String>{
    'debugPrint(':
        'traccia di sviluppo: finisce nel log, non sullo schermo',
    'DateFormat(':
        'schema di formattazione, non testo da leggere: «MMM d» descrive la forma di una data',
    'Exception(':
        'messaggio per chi legge lo stack. Se un giorno arriva a schermo, il difetto e che ci arriva',
    'debugLabel:':
        'etichetta di diagnostica del framework',
  };

  /// Le stringhe che **restano in inglese di proposito**, con il motivo.
  ///
  /// Ogni voce va difesa in una review.
  const ammesse = <String, String>{
    'Google Fit / Health Connect':
        'nomi di prodotto: non si traducono, come non si traduce «Firebase»',
    'GymFlow':
        'il nome dell applicazione, che non cambia con la lingua',
  };

  /// Qualunque letterale fra apici singoli che comincia per maiuscola.
  ///
  /// Volutamente cieca alla forma sintattica: e il rovescio dell errore che
  /// questo test ha gia commesso una volta.
  final letterali = RegExp(r"'([A-Z][^'\\]{2,})'");

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
        // Il contesto tecnico puo stare sulla riga precedente: `DateFormat(` a
        // fine riga e lo schema sotto e come le righe lunghe vengono spezzate.
        // Si guarda solo se la riga prima **finisce** con l'apertura, per non
        // assolvere una stringa che segue una chiamata gia chiusa.
        final precedente = i > 0 ? righe[i - 1].trimRight() : '';
        if (contestiTecnici.keys.any(
          (c) => riga.contains(c) || precedente.endsWith(c),
        )) {
          continue;
        }

        for (final trovata in letterali.allMatches(riga)) {
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
    for (final voce in {...ammesse, ...contestiTecnici}.entries) {
      expect(
        voce.value.trim().length,
        greaterThan(15),
        reason: '«${voce.key}» e ammessa senza una ragione scritta',
      );
    }
  });
}
