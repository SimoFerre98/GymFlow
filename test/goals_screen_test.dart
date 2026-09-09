import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/ui/screens/goals_screen.dart';
import 'package:gymflow/src/ui/widgets/back_pill.dart';

void main() {
  testWidgets(
    'GoalsScreen renderizza senza eccezioni e mostra titolo e azione per aggiungere',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GoalsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(GoalsScreen), findsOneWidget);

      // Il titolo non e piu un AppBar: e `BackPill` + testo nell'intestazione
      // del corpo (vedi goals_screen.dart). Si verifica la struttura, non il
      // testo tradotto, per non dipendere dalla lingua di default.
      expect(find.byType(BackPill), findsOneWidget);

      // "Aggiungi obiettivo" non e piu una FloatingActionButton: e il
      // pulsante a piena larghezza in fondo alla lista (`_buildAddCta`), con
      // la stessa icona Icons.add che portava il FAB. Nessuna forma di FAB
      // resta nella schermata.
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
    },
  );
}
