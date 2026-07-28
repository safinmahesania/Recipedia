import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipedia/constants/app_colors.dart';
import 'package:recipedia/shared/widgets/app_icon.dart';
import 'package:recipedia/shared/widgets/app_text_field.dart';
import 'package:recipedia/shared/widgets/ingredient_icon.dart';
import 'package:recipedia/shared/widgets/recipe_card.dart';
import 'package:recipedia/shared/widgets/skeletons.dart';
import 'package:recipedia/theme/app_theme.dart';

/// Widget tests for the shared components. None of these touch Supabase or
/// GetX, which is exactly why they are worth having: they cover the pieces
/// every screen is built from, without needing a backend or a signed-in user.
void main() {
  Widget host(Widget child, {Brightness brightness = Brightness.light}) =>
      MaterialApp(
        theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
        home: Scaffold(body: Center(child: child)),
      );

  group('RecipeCard', () {
    testWidgets('shows the title', (tester) async {
      await tester.pumpWidget(host(const RecipeCard(
          recipe: {'id': 'r1', 'title': 'Palak Paneer'})));
      expect(find.text('Palak Paneer'), findsOneWidget);
    });

    testWidgets('names what is missing when the scan supplies it', (tester) async {
      await tester.pumpWidget(host(const RecipeCard(recipe: {
        'id': 'r1',
        'title': 'Palak Paneer',
        'matched_count': 4,
        'missing_count': 1,
        'missing_names': ['paneer'],
      })));
      await tester.pumpAndSettle();
      // The point of the card is telling you what you are short of.
      expect(find.textContaining('paneer'), findsWidgets);
    });

    testWidgets('the add-to-list action only appears when something is missing',
        (tester) async {
      await tester.pumpWidget(host(RecipeCard(
        recipe: const {
          'id': 'r1',
          'title': 'Dal',
          'matched_count': 5,
          'missing_count': 0
        },
        onAddMissing: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('List'), findsNothing);
    });

    testWidgets('long press fires', (tester) async {
      var fired = false;
      await tester.pumpWidget(host(RecipeCard(
        recipe: const {'id': 'r1', 'title': 'Dal'},
        onLongPress: () => fired = true,
      )));
      await tester.longPress(find.text('Dal'));
      expect(fired, isTrue);
    });
  });

  group('AppTextField', () {
    testWidgets('password starts hidden and the eye reveals it', (tester) async {
      final c = TextEditingController(text: 'hunter22');
      await tester.pumpWidget(host(AppTextField(
          label: 'Password', hint: '', controller: c, obscure: true)));

      EditableText field() => tester.widget<EditableText>(find.byType(EditableText));
      expect(field().obscureText, isTrue);

      await tester.tap(find.byType(FieldIcon).last);
      await tester.pumpAndSettle();
      expect(field().obscureText, isFalse);
    });

    testWidgets('no eye on a normal field', (tester) async {
      await tester.pumpWidget(host(AppTextField(
          label: 'Name', hint: '', controller: TextEditingController())));
      expect(find.byType(FieldIcon), findsNothing);
    });
  });

  group('IngredientIcon', () {
    testWidgets('falls back to a letter when nothing else resolves',
        (tester) async {
      await tester.pumpWidget(host(const IngredientIcon(name: 'kokum')));
      await tester.pumpAndSettle();
      // Tier three: no icon_key, no category, so the first letter stands in.
      expect(find.text('K'), findsOneWidget);
    });

    testWidgets('renders artwork when the key is known', (tester) async {
      await tester.pumpWidget(
          host(const IngredientIcon(name: 'tomato', iconKey: 'tomato')));
      await tester.pumpAndSettle();
      expect(find.text('T'), findsNothing);
    });
  });

  group('AppIcon', () {
    testWidgets('an unmapped name is visibly wrong, not invisible',
        (tester) async {
      await tester.pumpWidget(host(const AppIcon('definitely_not_an_icon')));
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('filled and outline are different glyphs', (tester) async {
      await tester.pumpWidget(host(const Row(
          mainAxisSize: MainAxisSize.min,
          children: [AppIcon('home'), AppIcon('home', filled: true)])));
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.first.fill, 0);
      expect(icons.last.fill, 1);
    });
  });

  group('skeletons', () {
    testWidgets('ListSkeleton renders the requested number of rows',
        (tester) async {
      await tester.pumpWidget(host(
          const SizedBox(height: 600, child: ListSkeleton(count: 3))));
      await tester.pump();
      expect(find.byType(ListRowSkeleton), findsNWidgets(3));
    });

    testWidgets('EmptyState shows its message', (tester) async {
      await tester.pumpWidget(host(const EmptyState(
          icon: 'inbox_outlined',
          title: 'Nothing here',
          message: 'Add something to get started.')));
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Add something to get started.'), findsOneWidget);
    });
  });

  group('slotFor', () {
    test('is deterministic and stays in range', () {
      for (final seed in ['a', 'palak paneer', '', 'x' * 200]) {
        final slot = AppColors.slotFor(seed);
        expect(slot, inInclusiveRange(0, AppColors.categoryTints.length - 1));
        expect(AppColors.slotFor(seed), slot, reason: 'must be stable');
      }
    });
  });

  testWidgets('both themes register the token extension', (tester) async {
    for (final b in Brightness.values) {
      await tester.pumpWidget(host(const SizedBox(), brightness: b));
      final ctx = tester.element(find.byType(SizedBox));
      expect(Theme.of(ctx).extensions, isNotEmpty);
    }
  });
}
