import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ogni schermata che si apre da un riquadro della Home ha il tasto indietro.
///
/// Segnalato dall'utente sul telefono: da «Dati» (Statistiche) e da
/// «Traguardi» non si poteva tornare. Un commento in `gamification_screen.dart`
/// diceva che quelle destinazioni non ne avevano bisogno, e l'unica prova
/// contraria e arrivata con l'APK.
///
/// È un test **sul sorgente**: queste schermate istanziano Firebase e non si
/// montano in un test (debito US-008). Legge la lista dei riquadri da
/// `_ShortcutRow`, cosi una destinazione aggiunta domani e controllata senza
/// toccare questo file.
///
/// **Limite dichiarato**: verifica che la pillola sia scritta nella classe
/// della schermata, non che sia visibile o che il tocco chiuda davvero. Quello
/// resta sull'APK.
void main() {
  String leggi(String percorso) {
    // Eccezione e non `expect`: questi aiutanti girano mentre si costruisce
    // l'elenco dei test, fuori da qualunque test.
    final file = File(percorso);
    if (!file.existsSync()) throw StateError('$percorso non esiste');
    return file.readAsStringSync();
  }

  /// `StatisticsScreen` -> `statistics_screen.dart`.
  String fileDi(String classe) {
    final snake = classe.replaceAllMapped(
      RegExp(r'(?<=[a-z])([A-Z])'),
      (m) => '_${m[1]!.toLowerCase()}',
    );
    return 'lib/src/ui/screens/${snake.toLowerCase()}.dart';
  }

  /// Il testo della classe [nome] e del suo `State`, e niente di ciò che viene
  /// dopo: in `statistics_screen.dart` c'e anche `_HistoryScreen`, che ha la
  /// sua pillola e non deve far passare per buona quella della schermata.
  String testoDellaClasse(String sorgente, String nome) {
    final dichiarazioni = RegExp(r'^class (\w+)', multiLine: true).allMatches(sorgente).toList();
    final inizio = dichiarazioni.indexWhere((m) => m[1] == nome);
    if (inizio < 0) throw StateError('class $nome non trovata');
    var fine = sorgente.length;
    for (var i = inizio + 1; i < dichiarazioni.length; i++) {
      if (dichiarazioni[i][1] != '_${nome}State') {
        fine = dichiarazioni[i].start;
        break;
      }
    }
    return sorgente.substring(dichiarazioni[inizio].start, fine);
  }

  final dashboard = leggi('lib/src/ui/screens/dashboard_screen.dart');
  final riquadri = testoDellaClasse(dashboard, '_ShortcutRow');
  final destinazioni = RegExp(r'builder: \(_\) => const (\w+)\(\)')
      .allMatches(riquadri)
      .map((m) => m[1]!)
      .toSet()
      .toList();

  test('la Home ha dei riquadri, e il test li ha trovati', () {
    // Se la forma di `_ShortcutRow` cambia e la ricerca non trova piu niente,
    // il ciclo qui sotto non controllerebbe nulla e il test passerebbe lo
    // stesso: questo lo impedisce.
    expect(destinazioni.length, greaterThanOrEqualTo(4));
    expect(destinazioni, contains('StatisticsScreen'));
    expect(destinazioni, contains('GamificationScreen'));
  });

  for (final classe in destinazioni) {
    test('$classe ha il tasto indietro', () {
      final testo = testoDellaClasse(leggi(fileDi(classe)), classe);
      final righe = testo.split('\n').where((r) => !r.trimLeft().startsWith('//'));
      expect(
        righe.any((r) => r.contains('BackPill(')),
        isTrue,
        reason: '$classe si apre da un riquadro della Home e non ha BackPill',
      );
    });
  }
}
