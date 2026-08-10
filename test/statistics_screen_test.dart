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
      '_buildStatCard',
      '_buildHealthSection',
      '_buildHistoryItem'
    ];

    for (final item in itemsToMove) {
      expect(dashboardString, isNot(contains(item)), reason: 'DashboardScreen non deve più contenere $item');
      expect(statisticsString, contains(item), reason: 'StatisticsScreen deve contenere $item');
    }
  });

  test('I quattro _buildStatCard sono quattro anche dopo', () {
    final statisticsLines = righeDiCodice('lib/src/ui/screens/statistics_screen.dart');
    
    // Contiamo quante volte _buildStatCard viene chiamato nel build
    int count = 0;
    for (final line in statisticsLines) {
      if (line.contains('_buildStatCard(')) {
        count++;
      }
    }

    // Le statistiche sono 4 + la definizione del metodo = 5 occurrences totali (oppure 4 chiamate)
    // Dato che stiamo controllando con '_buildStatCard(' controlliamo le chiamate e la definizione.
    // La definizione e `Widget _buildStatCard(`. Le chiamate sono `_buildStatCard(`.
    // Visto che cerchiamo `_buildStatCard(`:
    expect(count, equals(5), reason: 'Ci devono essere 4 chiamate a _buildStatCard più la definizione del metodo');
  });

  test('La schermata è raggiungibile dal menu e dalla home', () {
    final drawerString = righeDiCodice('lib/src/ui/widgets/app_drawer.dart').join('\n');
    expect(drawerString, contains('StatisticsScreen'), reason: 'Il menu deve nominare StatisticsScreen');

    final dashboardString = righeDiCodice('lib/src/ui/screens/dashboard_screen.dart').join('\n');
    expect(dashboardString, contains('StatisticsScreen'), reason: 'La home deve nominare StatisticsScreen per arrivarci');
  });
}
