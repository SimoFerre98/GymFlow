import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/exercise_provider.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/models/image_credit.dart';
import 'package:gymflow/src/ui/screens/image_credits_screen.dart';

class _FakeCurated extends CuratedExercises {
  _FakeCurated(this.items);
  final List<Exercise> items;

  @override
  Future<List<Exercise>> build() async => items;
}

class _FakeCredits extends ImageCredits {
  _FakeCredits(this.items);
  final List<ImageCredit> items;

  @override
  Future<List<ImageCredit>> build() async => items;
}

class _FakeLocalizationNotifier extends LocalizationNotifier {
  _FakeLocalizationNotifier(this._loc);
  final Localization _loc;

  @override
  Localization build() => _loc;
}

Exercise curated(String id, String name) {
  return Exercise(
    id: id,
    name: name,
    description: '',
    type: ExerciseType.strength,
    musclesTargeted: const ['petto'],
    isCurated: true,
  );
}

const _credito1 = ImageCredit(
  exerciseId: 'ex_002',
  author: 'Everkinetic',
  licenseShortName: 'CC-BY-SA 3',
  licenseUrl: 'https://creativecommons.org/licenses/by-sa/3.0/deed.en',
  sourceUrl: 'https://wger.de/media/exercise-images/192/Bench-press-1.png',
);

const _credito2 = ImageCredit(
  exerciseId: 'ex_009',
  author: 'cshep442',
  licenseShortName: 'CC-BY-SA 4',
  licenseUrl: 'https://creativecommons.org/licenses/by-sa/4.0/deed.en',
  sourceUrl: 'https://wger.de/media/exercise-images/1/dips.png',
);

void main() {
  Widget host({
    required List<Exercise> exercises,
    required List<ImageCredit> credits,
  }) {
    return ProviderScope(
      overrides: [
        curatedExercisesProvider.overrideWith(() => _FakeCurated(exercises)),
        imageCreditsProvider.overrideWith(() => _FakeCredits(credits)),
        localizationNotifierProvider.overrideWith(
          () => _FakeLocalizationNotifier(const Localization(Locale('it'))),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme(const Color(0xFFF0C38E)),
        home: const ImageCreditsScreen(),
      ),
    );
  }

  testWidgets('mostra autore e licenza per ogni esercizio con credito', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        exercises: [curated('ex_002', 'Panca piana'), curated('ex_009', 'Dip')],
        credits: [_credito1, _credito2],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Panca piana'), findsOneWidget);
    expect(find.textContaining('Everkinetic'), findsOneWidget);
    expect(find.textContaining('CC-BY-SA 3'), findsOneWidget);
    expect(find.text('Dip'), findsOneWidget);
    expect(find.textContaining('cshep442'), findsOneWidget);
  });

  testWidgets('un credito senza esercizio corrispondente non compare', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        exercises: [curated('ex_002', 'Panca piana')],
        // ex_009 non e fra gli esercizi: l'esercizio potrebbe essere stato
        // rimosso dalla libreria curata senza aggiornare i crediti.
        credits: [_credito1, _credito2],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Panca piana'), findsOneWidget);
    expect(find.textContaining('cshep442'), findsNothing);
  });

  testWidgets('senza crediti la schermata resta vuota ma non fallisce', (
    tester,
  ) async {
    await tester.pumpWidget(host(exercises: const [], credits: const []));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNothing);
  });
}
