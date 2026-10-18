import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/providers/profile_provider.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/models/user_profile.dart';
import 'package:gymflow/src/ui/screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Il riquadro «CLIENTI» della Home compare solo a un trainer (US-089).
///
/// È il criterio di US-086 che questa storia non deve rompere: chi è atleta
/// vede la Home identica a prima. E nel dubbio — profilo in caricamento,
/// profilo assente — il riquadro non c'è: un lampo del riquadro a un atleta,
/// mentre il profilo arriva, sarebbe una piccola bugia.
class FintaProfilo extends CurrentUserProfile {
  FintaProfilo(this.flusso);

  final Stream<UserProfile?> flusso;

  @override
  Stream<UserProfile?> build() => flusso;
}

class OsservatoreRotte extends NavigatorObserver {
  int spinte = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => spinte++;
}

UserProfile profilo(UserRole ruolo) => UserProfile(
  id: 'u1',
  email: 'u@example.com',
  displayName: 'Utente',
  role: ruolo,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  late OsservatoreRotte osservatore;

  Future<void> monta(WidgetTester tester, Stream<UserProfile?> flusso) async {
    osservatore = OsservatoreRotte();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProfileProvider.overrideWith(() => FintaProfilo(flusso))],
        child: MaterialApp(
          theme: AppTheme.darkTheme(AppPalette.accent),
          navigatorObservers: [osservatore],
          home: const Scaffold(
            body: SingleChildScrollView(
              child: HomeShortcutRow(loc: Localization(Locale('it'))),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  int riquadri(WidgetTester tester) => tester
      .widgetList(find.descendant(of: find.byType(GridView), matching: find.byType(InkWell)))
      .length;

  testWidgets('un trainer vede il riquadro CLIENTI, in più degli altri', (tester) async {
    await monta(tester, Stream.value(profilo(UserRole.trainer)));
    expect(find.text('CLIENTI'), findsOneWidget);
    expect(riquadri(tester), 6);
  });

  testWidgets('chi è atleta e trainer insieme lo vede', (tester) async {
    await monta(tester, Stream.value(profilo(UserRole.both)));
    expect(find.text('CLIENTI'), findsOneWidget);
  });

  testWidgets('un atleta vede la Home identica a prima: nessun riquadro in più', (tester) async {
    await monta(tester, Stream.value(profilo(UserRole.athlete)));
    expect(find.text('CLIENTI'), findsNothing);
    expect(riquadri(tester), 5);
    expect(find.text('DATI'), findsOneWidget, reason: 'gli altri riquadri ci sono');
  });

  testWidgets('con il profilo ancora in caricamento il riquadro non c è', (tester) async {
    // Un flusso che non emette mai: lo stato di chi aspetta il profilo.
    await monta(tester, Completer<UserProfile?>().future.asStream());
    expect(find.text('CLIENTI'), findsNothing);
    expect(riquadri(tester), 5);
  });

  testWidgets('senza profilo (utente senza documento) il riquadro non c è', (tester) async {
    await monta(tester, Stream.value(null));
    expect(find.text('CLIENTI'), findsNothing);
  });

  testWidgets('se il profilo non si legge il riquadro non c è', (tester) async {
    await monta(tester, Stream<UserProfile?>.error(StateError('permesso negato')));
    expect(find.text('CLIENTI'), findsNothing);
    expect(riquadri(tester), 5);
  });

  testWidgets('il tocco sul riquadro apre i clienti', (tester) async {
    await monta(tester, Stream.value(profilo(UserRole.trainer)));
    final prima = osservatore.spinte;
    // Senza `pump` dopo il tocco: la rotta e spinta, ma la schermata non viene
    // costruita (qui non c'e un provider dei clienti).
    await tester.tap(find.text('CLIENTI'));
    expect(osservatore.spinte, prima + 1);
  });
}
