import 'package:flutter_test/flutter_test.dart';
import 'package:recipedia/shared/recipe_steps.dart';

/// The parsing that turns imported free text into something cookable.
///
/// Worth real tests because every rule here was a decision, not an accident:
/// which end of a range a timer takes, whether a one-paragraph recipe counts as
/// steps, what an unparseable cook time sorts as. A regression in any of them
/// is silent — the app still runs, it just gets the wrong answer.
void main() {
  group('split', () {
    test('splits on line breaks and strips existing numbering', () {
      final steps = RecipeSteps.split('1. Heat the oil\n2) Add cumin\n3. Serve');
      expect(steps, ['Heat the oil', 'Add cumin', 'Serve']);
    });

    test('falls back to sentences when there are no line breaks', () {
      // The whole imported catalogue stores instructions as one blob. Returning
      // [] here is what disabled "Start cooking" on nearly every recipe.
      final steps = RecipeSteps.split(
          'Heat oil in a pan. Add cumin seeds and let them splutter. Serve hot.');
      expect(steps.length, 3);
      expect(steps.last, 'Serve hot.');
    });

    test('does not split a decimal into two steps', () {
      final steps =
          RecipeSteps.split('Boil for 1.5 hours. Mash them well thereafter.');
      expect(steps.length, 2);
      expect(steps.first, contains('1.5 hours'));
    });

    test('a single sentence is not a set of steps', () {
      expect(RecipeSteps.split('Mix everything and serve.'), isEmpty);
    });

    test('stepsOrWhole always yields something cookable', () {
      // Cook mode must never receive an empty list.
      expect(RecipeSteps.stepsOrWhole('Mix everything and serve.'),
          ['Mix everything and serve.']);
      expect(RecipeSteps.stepsOrWhole('   '), isEmpty);
    });
  });

  group('durationIn', () {
    test('reads a plain duration', () {
      expect(RecipeSteps.durationIn('Fry for 30 seconds'),
          const Duration(seconds: 30));
      expect(RecipeSteps.durationIn('Rest the dough 1 hour'),
          const Duration(hours: 1));
      expect(RecipeSteps.durationIn('Cook 5 mins on medium'),
          const Duration(minutes: 5));
    });

    test('takes the LONGER end of a range', () {
      // Deliberate: a timer that fires early is worse than one that fires late.
      // You can always check the pan; you cannot un-burn it.
      expect(RecipeSteps.durationIn('Simmer for 10-12 minutes'),
          const Duration(minutes: 12));
    });

    test('ignores quantities that are not times', () {
      expect(RecipeSteps.durationIn('Add 2 cups water and stir'), isNull);
      expect(RecipeSteps.durationIn('Chop 3 onions'), isNull);
    });
  });

  group('minutes', () {
    test('parses the shapes cook_time actually contains', () {
      expect(RecipeSteps.minutes('35 min'), 35);
      expect(RecipeSteps.minutes('1 hr 10 min'), 70);
      expect(RecipeSteps.minutes('2 hours'), 120);
      expect(RecipeSteps.minutes('45'), 45);
    });

    test('unparseable values sort last, not first', () {
      // Returning 0 would put every broken row at the top of "Quick tonight".
      expect(RecipeSteps.minutes(null), greaterThan(100000));
      expect(RecipeSteps.minutes(''), greaterThan(100000));
      expect(RecipeSteps.minutes('a while'), greaterThan(100000));
    });
  });

  group('format', () {
    test('renders a countdown', () {
      expect(RecipeSteps.format(const Duration(minutes: 12)), '12:00');
      expect(RecipeSteps.format(const Duration(seconds: 90)), '1:30');
      expect(RecipeSteps.format(const Duration(hours: 1, minutes: 5)), '1:05:00');
    });
  });
}
