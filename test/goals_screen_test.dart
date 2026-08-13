import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/ui/screens/goals_screen.dart';

void main() {
  testWidgets('GoalsScreen renderizza senza eccezioni e mostra il titolo', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: GoalsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(GoalsScreen), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
