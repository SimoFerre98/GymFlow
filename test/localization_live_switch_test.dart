import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/ui/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cambiare lingua deve ridisegnare cio che e gia a schermo.
///
/// Nasce da un difetto trovato in review su US-027: `login_screen.dart` leggeva
/// ogni stringa con `ref.read(localizationNotifierProvider)` **dentro `build`**.
/// `read` non crea un'iscrizione, quindi la schermata non veniva ricostruita e
/// restava nella lingua di prima. E lo stesso difetto di US-093, dove il
/// cronometro non si muoveva per la stessa ragione.
///
/// Tutti i test sul sorgente scritti finora — e sono parecchi — restavano verdi
/// con quel difetto: contano le stringhe tradotte, non guardano cosa viene
/// disegnato.
///
/// **Limite dichiarato**: prova **una** schermata, quella di accesso, perche e
/// l'unica delle otto secondarie che si monta senza Firebase. Le altre
/// istanziano servizi nel proprio `State` (debito di US-008) e cadono in un
/// test. Per quelle resta il controllo sul sorgente in
/// `localization_secondary_test.dart`, che pero prova una cosa piu debole:
/// **che la stringa venga dal dizionario, non che la schermata si iscriva.**
void main() {
  setUp(() {
    // Il notifier legge la lingua salvata all'avvio: senza valori finti la
    // chiamata al plugin fallisce e l'errore arriva fuori dal test.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('la schermata di accesso si aggiorna cambiando lingua', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    // La lingua predefinita e l'italiano.
    expect(find.text('Bentornato'), findsOneWidget);
    expect(find.text('ACCEDI'), findsOneWidget);

    await container
        .read(localizationNotifierProvider.notifier)
        .setLocale(const Locale('en'));
    await tester.pump();

    // Senza riavvio, e senza toccare la schermata.
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Bentornato'), findsNothing);
  });
}
