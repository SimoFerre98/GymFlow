import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> righeDiCodice(String percorso) {
    final file = File(percorso);
    expect(file.existsSync(), isTrue, reason: '$percorso non esiste');
    return file
        .readAsLinesSync()
        .where((r) => !r.trimLeft().startsWith('//'))
        .toList();
  }

  test('Le sei voci sono state spostate dalla home alle statistiche', () {
    final dashboardLines = righeDiCodice('lib/src/ui/screens/dashboard_screen.dart');
    final dashboardString = dashboardLines.join('\n');

    final statisticsLines = righeDiCodice('lib/src/ui/screens/statistics_screen.dart');
    final statisticsString = statisticsLines.join('\n');

    final itemsToMove = [
      'ActivityChart',
      'BodyMeasurementsChart',
      // Era `_buildStatCard`, un metodo privato: il redesign Immersivo ha
      // sostituito la griglia di tessere con quattro sezioni a piena
      // larghezza (massimale, volume settimanale, ripartizione, streak — la
      // stessa grammatica per tutte, vedi il commento su `_SezioneDati`). Il
      // nome cambia, cio che questo test sorveglia no.
      '_SezioneDati',
      // Era `_buildHealthSection`, un metodo privato della schermata. US-100 lo
      // ha estratto in un widget suo per poter dimostrare che col permesso
      // mancante non compare uno zero: la schermata intera non si monta in un
      // test. Il nome cambia, cio che questo test sorveglia no — la sezione
      // salute sta nelle statistiche e non piu nella home.
      'HealthSummarySection',
      // Era `_buildHistoryItem`: stessa sorte di `_buildStatCard`, rinominato
      // nella riscrittura di questa schermata in `_StoricoItem`.
      '_StoricoItem',
    ];

    for (final item in itemsToMove) {
      expect(dashboardString, isNot(contains(item)), reason: 'DashboardScreen non deve più contenere $item');
      expect(statisticsString, contains(item), reason: 'StatisticsScreen deve contenere $item');
    }
  });

  test('Le quattro _SezioneDati (ex _buildStatCard) sono quattro anche dopo', () {
    // `_buildStatCard` non esiste piu: il redesign Immersivo lo ha sostituito
    // con `_SezioneDati`, un widget invece di un metodo privato, usato con la
    // stessa cardinalita — una per massimale, volume settimanale,
    // ripartizione e streak (vedi il commento sulla classe). Il criterio
    // resta lo stesso, solo il nome sorvegliato cambia.
    final statisticsLines = righeDiCodice('lib/src/ui/screens/statistics_screen.dart');

    int count = 0;
    for (final line in statisticsLines) {
      if (line.contains('_SezioneDati(')) {
        count++;
      }
    }

    // 4 chiamate + il costruttore della classe = 5 occorrenze totali di
    // `_SezioneDati(`.
    expect(count, equals(5), reason: 'Ci devono essere 4 chiamate a _SezioneDati più il suo costruttore');
  });

  test('La schermata è raggiungibile dalla home, non più dal cassetto', () {
    // L'utente ha chiesto di togliere Statistiche ed Esercizi dal cassetto:
    // troppe voci che duplicano una via già più diretta. Statistiche resta
    // raggiungibile dall'icona nella barra della home, che è l'unica via
    // rimasta — e questo test lo sorveglia cambiando verso, non cancellando
    // il criterio.
    final drawerString = righeDiCodice('lib/src/ui/widgets/app_drawer.dart').join('\n');
    expect(drawerString, isNot(contains('StatisticsScreen')), reason: 'Il cassetto non deve più nominare StatisticsScreen');

    final dashboardString = righeDiCodice('lib/src/ui/screens/dashboard_screen.dart').join('\n');
    expect(dashboardString, contains('StatisticsScreen'), reason: 'La home deve nominare StatisticsScreen per arrivarci');
  });
}
