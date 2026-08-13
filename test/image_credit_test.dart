import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/image_credit.dart';

void main() {
  group('ImageCreditSeed.parse', () {
    test('legge le voci con tutti i campi', () {
      const source = '''
      {
        "ex_002": {
          "author": "Everkinetic",
          "licenseShortName": "CC-BY-SA 3",
          "licenseUrl": "https://creativecommons.org/licenses/by-sa/3.0/deed.en",
          "sourceUrl": "https://wger.de/media/exercise-images/192/Bench-press-1.png"
        }
      }
      ''';

      final credits = ImageCreditSeed.parse(source);

      expect(credits, hasLength(1));
      expect(credits.single.exerciseId, 'ex_002');
      expect(credits.single.author, 'Everkinetic');
      expect(credits.single.licenseShortName, 'CC-BY-SA 3');
      expect(
        credits.single.licenseUrl,
        'https://creativecommons.org/licenses/by-sa/3.0/deed.en',
      );
      expect(
        credits.single.sourceUrl,
        'https://wger.de/media/exercise-images/192/Bench-press-1.png',
      );
    });

    test('un file non JSON non fa cadere nulla', () {
      expect(ImageCreditSeed.parse('non un json'), isEmpty);
    });

    test('una radice che non e un oggetto produce una lista vuota', () {
      expect(ImageCreditSeed.parse('[1, 2, 3]'), isEmpty);
    });

    test('una voce che non e un oggetto viene scartata', () {
      final credits = ImageCreditSeed.parse('{"ex_001": "non un oggetto"}');
      expect(credits, isEmpty);
    });

    test('campi mancanti diventano stringhe vuote, non falliscono', () {
      final credits = ImageCreditSeed.parse('{"ex_003": {}}');
      expect(credits.single.author, isEmpty);
      expect(credits.single.licenseShortName, isEmpty);
      expect(credits.single.licenseUrl, isEmpty);
      expect(credits.single.sourceUrl, isEmpty);
    });
  });
}
