import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';

/// Le quattro schermate principali non tornano ai valori scritti a mano.
///
/// È un test **sul sorgente** e non sui widget, per la stessa ragione del test
/// di localizzazione: queste schermate non si montano — istanziano Firebase e
/// creano stream dentro `build`, che è il debito di US-008÷US-012 — ma il
/// criterio parla di **come sono scritte**, e quello si legge.
///
/// **Limite dichiarato**: verifica l'assenza dei valori a mano, non che il
/// risultato sia bello. Il giudizio visivo è sull'APK.
void main() {
  const schermate = <String>[
    'lib/src/ui/screens/dashboard_screen.dart',
    'lib/src/ui/screens/calendar_screen.dart',
    'lib/src/ui/screens/program_list_screen.dart',
    'lib/src/ui/screens/active_session_screen.dart',
  ];

  /// Righe di codice, senza i commenti: un valore citato in un commento che
  /// spiega **perché** non c'è più non è una violazione.
  List<String> righeDiCodice(String percorso) {
    final file = File(percorso);
    expect(file.existsSync(), isTrue, reason: '$percorso non esiste');
    return file
        .readAsLinesSync()
        .where((r) => !r.trimLeft().startsWith('//'))
        .toList();
  }

  for (final percorso in schermate) {
    final nome = percorso.split('/').last;

    group(nome, () {
      test('nessuna ombra definita a mano', () {
        // È il criterio guida della storia, ed è l'unico verificabile con una
        // ricerca esatta: le ombre vengono da `elevation.levelN(scheme.shadow)`,
        // così seguono il tema invece di essere nere per sempre.
        final colpevoli = righeDiCodice(percorso)
            .where((r) => r.contains('BoxShadow('))
            .toList();

        expect(
          colpevoli,
          isEmpty,
          reason: 'usa expressive.elevation.levelN(scheme.shadow)',
        );
      });

      test('nessun colore letterale, a parte Colors.transparent', () {
        // `Colors.transparent` resta ammesso: non è una scelta di colore, è
        // «qui non disegnare niente», e serve a `Material` e ai fogli modali.
        final colpevoli = righeDiCodice(percorso)
            .where((r) => r.contains('Colors.'))
            .where((r) => !r.contains('Colors.transparent'))
            .toList();

        expect(
          colpevoli,
          isEmpty,
          reason: 'usa i ruoli del ColorScheme: '
              'onSurfaceVariant per il testo secondario, error per gli '
              'errori, primary solo per le azioni',
        );
      });

      test('nessuna spaziatura numerica scritta a mano', () {
        final numerico = RegExp(
          r'EdgeInsets\.all\(\s*[0-9]|'
          r'EdgeInsets\.symmetric\(\s*(horizontal|vertical):\s*[0-9]|'
          r'EdgeInsets\.only\(\s*(left|right|top|bottom):\s*[0-9]|'
          r'SizedBox\(\s*(height|width):\s*[0-9]',
        );
        final colpevoli = righeDiCodice(percorso)
            .where((r) => numerico.hasMatch(r))
            .toList();

        expect(colpevoli, isEmpty, reason: 'usa context.expressive.spacing');
      });

      test('nessun raggio numerico scritto a mano', () {
        final colpevoli = righeDiCodice(percorso)
            .where((r) => RegExp(r'BorderRadius\.circular\(\s*[0-9]').hasMatch(r))
            .toList();

        expect(
          colpevoli,
          isEmpty,
          reason: 'usa context.expressive.shape.cornerXx, '
              'e per i raggi singoli shape.radiusXx',
        );
      });

      test('nessuna dimensione di carattere scritta a mano', () {
        final colpevoli = righeDiCodice(percorso)
            .where((r) => RegExp(r'fontSize:\s*[0-9]').hasMatch(r))
            .toList();

        expect(
          colpevoli,
          isEmpty,
          reason: 'usa i ruoli di textTheme o expressive.typography',
        );
      });

      test('i campi che precedono Material 3 non si usano', () {
        // `cardColor` e `primaryColor` esistono ancora in `ThemeData` ma il
        // tema del progetto non li imposta: quando funzionano, funzionano per
        // un valore di default, non per una decisione.
        final colpevoli = righeDiCodice(percorso)
            .where((r) => r.contains('.cardColor') || r.contains('.primaryColor'))
            .toList();

        expect(
          colpevoli,
          isEmpty,
          reason: 'usa scheme.surfaceContainerHigh e scheme.primary',
        );
      });
    });
  }

  test('le tre schermate usano la card condivisa o dichiarano perché no', () {
    // Il calendario non la usa: le sue righe sono vetro sfocato con un bordo
    // luminoso, e `ExpressiveCard` porta un fondo opaco. La review lo dichiara.
    for (final percorso in const [
      'lib/src/ui/screens/dashboard_screen.dart',
      'lib/src/ui/screens/program_list_screen.dart',
    ]) {
      expect(
        File(percorso).readAsStringSync(),
        contains('ExpressiveCard'),
        reason: '$percorso deve usare la card condivisa',
      );
    }
  });

  test('la tipografia emphasized e usata per i titoli', () {
    // `titleEmphasized` esiste da US-033 e prima di questa storia non la usava
    // nessuno.
    for (final percorso in schermate) {
      expect(
        File(percorso).readAsStringSync(),
        contains('titleEmphasized'),
        reason: '$percorso deve usare expressive.typography.titleEmphasized',
      );
    }
  });

  test('i token nuovi delle icone in ExpressiveSizing hanno i valori dichiarati', () {
    const sizing = ExpressiveSizing();
    expect(sizing.iconSm, 16);
    expect(sizing.iconMd, 20);
    expect(sizing.iconLg, 24);
  });
}

