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
    'lib/src/ui/screens/statistics_screen.dart',
    'lib/src/ui/screens/calendar_screen.dart',
    'lib/src/ui/screens/program_list_screen.dart',
    'lib/src/ui/screens/active_session_screen.dart',
  ];

  /// I widget nati per i mockup, sorvegliati con le stesse regole delle
  /// schermate ma **non** con le ultime due voci del file, che parlano di
  /// `ExpressiveCard` e del titolo di una schermata.
  ///
  /// Il piano di US-062 li voleva in questa lista, e non c'erano: e cosi che
  /// cinque `fontSize: 8.5` — i pixel del mockup — sono arrivati fino alla
  /// review senza che niente si accorgesse.
  const widgetDeiMockup = <String>[
    'lib/src/ui/widgets/home_hero_card.dart',
    'lib/src/ui/widgets/progress_ring.dart',
    'lib/src/ui/widgets/timer_overlay.dart',
    'lib/src/ui/widgets/expressive_cta_button.dart',
    'lib/src/ui/widgets/expressive_segmented_control.dart',
    'lib/src/ui/widgets/time_dial.dart',
    'lib/src/ui/widgets/charts/activity_chart.dart',
    'lib/src/ui/widgets/charts/body_measurements_chart.dart',
    'lib/src/ui/widgets/charts/workout_type_pie_chart.dart',
    'lib/src/ui/widgets/app_drawer.dart',
    'lib/src/ui/screens/settings_screen.dart',
    'lib/src/ui/widgets/workout_receipt.dart',
    'lib/src/ui/screens/workout_summary_screen.dart',
    'lib/src/ui/widgets/toast_utils.dart',
    'lib/src/ui/widgets/live_metrics_panel.dart',
    'lib/src/ui/screens/gamification_screen.dart',
    'lib/src/ui/screens/workout_creator_screen.dart',
    'lib/src/ui/screens/friend_detail_screen.dart',
    'lib/src/ui/screens/program_creator_screen.dart',
    'lib/src/ui/screens/connect_friend_screen.dart',
    'lib/src/ui/screens/profile_screen.dart',
    'lib/src/ui/screens/login_screen.dart',
    'lib/src/ui/screens/register_screen.dart',
    'lib/src/ui/screens/exercise_detail_screen.dart',
    'lib/src/ui/auth_wrapper.dart',
    'lib/src/ui/screens/body_measurements_screen.dart',
    'lib/src/ui/screens/exercise_library_screen.dart',
    'lib/src/ui/widgets/add_exercise_dialog.dart',
    'lib/src/ui/widgets/exercise_image.dart',
    'lib/src/ui/widgets/exercise_row.dart',
    'lib/src/ui/widgets/exercise_thumbnail.dart',
    'lib/src/ui/widgets/exercise_video_sheet.dart',
    'lib/src/ui/widgets/expressive_card.dart',
    'lib/src/ui/widgets/set_editor_sheet.dart',
    'lib/src/ui/widgets/set_value_slider.dart',
    'lib/src/ui/widgets/sparkline.dart',
    'lib/src/ui/widgets/spring_page_transition.dart',
    // Sono una schermata, non un widget: stanno qui e non fra `schermate`
    // perché non vogliono le due verifiche in fondo al file (la card
    // condivisa, `titleEmphasized`) — nessuna delle due ha un titolo o una
    // card, sono il telaio della navigazione e la schermata del tempo.
    'lib/src/ui/screens/main_screen.dart',
    'lib/src/ui/screens/time_tools_screen.dart',
    'lib/src/ui/screens/health_detail_screen.dart',
  ];

  const sorvegliati = <String>[...schermate, ...widgetDeiMockup];

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

  for (final percorso in sorvegliati) {
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
        //
        // Il criterio guarda `Theme.of(...)`, non un `.primaryColor` qualsiasi:
        // `ThemeSettings.primaryColor` — il colore d'azione scelto
        // dall'utente, letto da `themeSettingsNotifierProvider` — porta lo
        // stesso nome ma non e il campo di `ThemeData` che la storia vuole
        // fuori da qui.
        final campoVietato = RegExp(r'Theme\.of\([^)]*\)\.(cardColor|primaryColor)');
        final colpevoli = righeDiCodice(percorso)
            .where((r) => campoVietato.hasMatch(r))
            .toList();

        expect(
          colpevoli,
          isEmpty,
          reason: 'usa scheme.surfaceContainerHigh e scheme.primary',
        );
      });
    });
  }

  test('le schermate usano la card condivisa, o la ricevono da un widget che la usa', () {
    // Il calendario non la usa: le sue righe sono vetro sfocato con un bordo
    // luminoso, e `ExpressiveCard` porta un fondo opaco. La review lo dichiara.
    //
    // La dashboard non la nomina più direttamente da US-095, che le ha portato
    // via le statistiche: la sua unica card ora è `HomeHeroCard`, che
    // `ExpressiveCard` la usa due volte. **Vale, e resta nella lista**: toglierla
    // di qui avrebbe fatto sparire la guardia insieme al problema, e il criterio
    // e «usa la card condivisa», non «scrive quella parola».
    const viaDiretta = 'ExpressiveCard';
    const perDelega = <String, String>{
      'lib/src/ui/screens/dashboard_screen.dart': 'HomeHeroCard',
    };

    for (final percorso in const [
      'lib/src/ui/screens/dashboard_screen.dart',
      'lib/src/ui/screens/statistics_screen.dart',
      'lib/src/ui/screens/program_list_screen.dart',
    ]) {
      final sorgente = File(percorso).readAsStringSync();
      final delegato = perDelega[percorso];

      final vaBene = sorgente.contains(viaDiretta) ||
          (delegato != null &&
              sorgente.contains(delegato) &&
              File('lib/src/ui/widgets/${_fileDi(delegato)}')
                  .readAsStringSync()
                  .contains(viaDiretta));

      expect(
        vaBene,
        isTrue,
        reason: delegato == null
            ? '$percorso deve usare la card condivisa'
            : '$percorso deve usare la card condivisa, direttamente o '
                'attraverso $delegato — che a sua volta deve usarla',
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

/// Da `HomeHeroCard` a `home_hero_card.dart`.
String _fileDi(String classe) {
  final conTrattini = classe.replaceAllMapped(
    RegExp(r'(?<!^)([A-Z])'),
    (m) => '_${m[1]}',
  );
  return '${conTrattini.toLowerCase()}.dart';
}
