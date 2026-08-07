import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/ui/widgets/exercise_row.dart';
import 'package:gymflow/src/ui/widgets/exercise_thumbnail.dart';
import 'package:shared_preferences/shared_preferences.dart';

Exercise exercise({
  String id = 'e1',
  String name = 'Panca piana',
  String? videoUrl,
  String? videoSearchQuery,
  String? imageUrl,
  ExerciseType type = ExerciseType.strength,
  List<String> muscles = const ['petto'],
}) {
  return Exercise(
    id: id,
    name: name,
    description: '',
    type: type,
    videoUrl: videoUrl,
    videoSearchQuery: videoSearchQuery,
    imageUrl: imageUrl,
    musclesTargeted: muscles,
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Widget host(Widget child, {ThemeData? theme}) {
    return ProviderScope(
      child: MaterialApp(
        theme: theme ?? AppTheme.darkTheme(AppPalette.amber),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('ExerciseRow', () {
    testWidgets('mostra miniatura, nome e sottotitolo di default', (tester) async {
      await tester.pumpWidget(
        host(ExerciseRow(exercise: exercise())),
      );

      expect(find.byType(ExerciseThumbnail), findsOneWidget);
      expect(find.text('Panca piana'), findsOneWidget);
      expect(find.text('STRENGTH'), findsOneWidget);
    });

    testWidgets('mostra sottotitolo personalizzato se fornito', (tester) async {
      await tester.pumpWidget(
        host(
          ExerciseRow(
            exercise: exercise(),
            subtitle: const Text('4 x 10 @ 60kg'),
          ),
        ),
      );

      expect(find.text('4 x 10 @ 60kg'), findsOneWidget);
      expect(find.text('STRENGTH'), findsNothing);
    });

    testWidgets('mostra trailing se fornito', (tester) async {
      await tester.pumpWidget(
        host(
          ExerciseRow(
            exercise: exercise(),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('tocco sulla miniatura attiva onThumbnailTap e non onTap', (
      tester,
    ) async {
      var rowTapped = 0;
      var thumbTapped = 0;

      await tester.pumpWidget(
        host(
          ExerciseRow(
            exercise: exercise(),
            onTap: () => rowTapped++,
            onThumbnailTap: () => thumbTapped++,
          ),
        ),
      );

      await tester.tap(find.byType(ExerciseThumbnail));
      await tester.pump();

      expect(thumbTapped, 1);
      expect(rowTapped, 0);
    });

    testWidgets('tocco sul corpo della riga attiva onTap', (tester) async {
      var rowTapped = 0;
      var thumbTapped = 0;

      await tester.pumpWidget(
        host(
          ExerciseRow(
            exercise: exercise(),
            onTap: () => rowTapped++,
            onThumbnailTap: () => thumbTapped++,
          ),
        ),
      );

      await tester.tap(find.text('Panca piana'));
      await tester.pump();

      expect(rowTapped, 1);
      expect(thumbTapped, 0);
    });

    testWidgets('il fondo segue surfaceContainerHigh del tema', (tester) async {
      final darkTheme = AppTheme.darkTheme(AppPalette.amber);
      await tester.pumpWidget(
        host(ExerciseRow(exercise: exercise()), theme: darkTheme),
      );

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(ExerciseRow),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, darkTheme.colorScheme.surfaceContainerHigh);
    });

    testWidgets('il fondo trasparente viene rispettato', (tester) async {
      await tester.pumpWidget(
        host(
          ExerciseRow(
            exercise: exercise(),
            transparentBackground: true,
          ),
        ),
      );

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(ExerciseRow),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, Colors.transparent);
    });

    testWidgets('il raggio e quello del mockup convertito, non copiato', (
      tester,
    ) async {
      // Il mockup dice 16 px, ma i pixel non si copiano: 16 x 1,36 = 22 dp, e
      // `cornerLg` (24) e il token piu vicino. Con `cornerMd` (16) la riga
      // avrebbe angoli molto piu squadrati di quelli disegnati.
      await tester.pumpWidget(
        host(ExerciseRow(exercise: exercise())),
      );

      const tokens = ExpressiveTokens();
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(ExerciseRow),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.borderRadius, tokens.shape.cornerLg);
    });
  });
}
