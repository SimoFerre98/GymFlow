import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  group('Date formatting', () {
    test('formattare una data in it e en non solleva eccezioni', () {
      // `initializeDateFormatting` e sincrona: non va attesa.
      initializeDateFormatting();

      final date = DateTime(2026, 8, 9);

      // La forma esatta usata dalla lista degli allenamenti, che senza
      // inizializzazione lanciava `LocaleDataException`.
      expect(DateFormat.yMMMd('it').format(date), isNotEmpty);
      expect(DateFormat.yMMMd('en').format(date), isNotEmpty);
    });

    test('la chiamata a initializeDateFormatting resta in main.dart', () {
      // E questo il vero guardiano della regressione: il test sopra passerebbe
      // anche se `main.dart` non inizializzasse niente, perche inizializza da
      // se. La schermata delle schede non e montabile in un test — Firebase e
      // stream dentro `build` — quindi la prova che l'app funzioni sta in due
      // pezzi: `intl` funziona una volta inizializzato, e `main` lo inizializza.
      final mainFile = File('lib/main.dart');
      expect(
        mainFile.existsSync(),
        isTrue,
        reason: 'Il file lib/main.dart non esiste',
      );

      expect(
        mainFile.readAsStringSync(),
        contains('initializeDateFormatting('),
        reason:
            'Senza questa chiamata la lista degli allenamenti torna a mostrare '
            'una schermata rossa appena una scheda ha una data di inizio',
      );
    });
  });
}
