import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/src/ui/screens/dashboard_screen.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/providers/auth_provider.dart';
import 'package:gymflow/src/core/providers/firestore_provider.dart';
import 'package:gymflow/src/core/providers/exercise_provider.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/models/workout_program.dart';
import 'package:gymflow/src/models/workout.dart';
import 'package:gymflow/src/models/exercise.dart';

class FakeFirestoreService implements FirestoreService {
  @override
  Stream<List<WorkoutProgram>> getUserPrograms(String userId) => Stream.value([]);
  @override
  Stream<List<WorkoutTemplate>> getUserWorkouts(String userId) => Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalization extends Localization {
  const FakeLocalization(this.athleteName) : super(const Locale('it'));
  final String athleteName;
  @override
  String t(String key, [Map<String, String>? args]) {
    if (key == 'athlete') return athleteName;
    if (key == 'welcome_back') return 'Bentornato,';
    return key;
  }
}

class TestLocalizationNotifier extends LocalizationNotifier {
  TestLocalizationNotifier(this.athleteName);
  final String athleteName;
  
  @override
  Localization build() => FakeLocalization(athleteName);
}

class FakeExercises extends Exercises {
  @override
  Future<List<Exercise>> build() async => [];
}

void main() {
  Widget createDashboardApp(String userName) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => null), 
        currentUserIdProvider.overrideWith((ref) => '123'),
        firestoreServiceProvider.overrideWithValue(FakeFirestoreService()),
        exercisesProvider.overrideWith(() => FakeExercises()),
        localizationNotifierProvider.overrideWith(() => TestLocalizationNotifier(userName)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(Colors.blue),
        home: const DashboardScreen(),
      ),
    );
  }

  testWidgets('Barra compressa con nome lungo: viene troncato e non si interseca', (tester) async {
    const longName = 'Questo è un nome lunghissimo che sicuramente sborda se non viene troncato correttamente con maxLines';
    await tester.pumpWidget(createDashboardApp(longName));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(NestedScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Troviamo il testo nella NavigationToolbar (il titolo compresso)
    final nameText = find.descendant(
      of: find.byType(NavigationToolbar),
      matching: find.text(longName),
    ).last; // In caso ce ne siano due nella toolbar, prendiamo l'ultimo (il testo vero)
    
    final drawerIcon = find.byIcon(Icons.menu);

    expect(nameText, findsOneWidget);
    expect(drawerIcon, findsOneWidget);

    final nameRect = tester.getRect(nameText);
    final drawerRect = tester.getRect(drawerIcon);

    expect(nameRect.overlaps(drawerRect), isFalse, reason: 'Il nome si sovrappone al menu hamburger');
  });

  testWidgets('Barra compressa: nome corto non si interseca', (tester) async {
    const shortName = 'Mario';
    await tester.pumpWidget(createDashboardApp(shortName));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(NestedScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final nameText = find.descendant(
      of: find.byType(NavigationToolbar),
      matching: find.text(shortName),
    ).last;
    
    final drawerIcon = find.byIcon(Icons.menu);

    expect(nameText, findsOneWidget);
    expect(drawerIcon, findsOneWidget);

    final nameRect = tester.getRect(nameText);
    final drawerRect = tester.getRect(drawerIcon);

    expect(nameRect.overlaps(drawerRect), isFalse);
  });
  
  testWidgets('Da espanso il saluto resta dove previsto', (tester) async {
    await tester.pumpWidget(createDashboardApp('Mario'));
    await tester.pumpAndSettle();

    final welcomeText = find.text('Bentornato,');
    expect(welcomeText, findsOneWidget);
    
    final welcomeRect = tester.getRect(welcomeText);
    // Nella large appbar, la y del testo è lontana dal bordo superiore (più di kToolbarHeight che è 56)
    expect(welcomeRect.top > 56, isTrue);
  });
}
