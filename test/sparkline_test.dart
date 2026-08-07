import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/ui/widgets/sparkline.dart';

void main() {
  group('Sparkline widget', () {
    testWidgets('si monta e rispetta RepaintBoundary e dimensioni fornite',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Sparkline(
              values: [100.0, 110.0, 105.0, 120.0],
              color: Colors.amber,
              width: 100,
              height: 22,
            ),
          ),
        ),
      );

      expect(find.byType(Sparkline), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);

      final size = tester.getSize(find.byType(Sparkline));
      expect(size.width, 100);
      expect(size.height, 22);
    });

    testWidgets('non fallisce con lista vuota o con un solo elemento',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Sparkline(
                  values: [],
                  color: Colors.amber,
                  height: 22,
                ),
                Sparkline(
                  values: [100.0],
                  color: Colors.red,
                  height: 22,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Sparkline), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('gestisce serie con valori identici senza divisioni per zero',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Sparkline(
              values: [120.0, 120.0, 120.0],
              color: Colors.amber,
              width: 80,
              height: 22,
            ),
          ),
        ),
      );

      expect(find.byType(Sparkline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('aggiorna il rendering quando cambiano i valori',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Sparkline(
              values: [100.0, 110.0],
              color: Colors.amber,
            ),
          ),
        ),
      );

      expect(find.byType(Sparkline), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Sparkline(
              values: [100.0, 110.0, 120.0, 130.0],
              color: Colors.amber,
            ),
          ),
        ),
      );

      expect(find.byType(Sparkline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
