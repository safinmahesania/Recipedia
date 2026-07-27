import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Guards against the GetX trap that broke onboarding.
///
/// `Obx` subscribes only to observables read during ITS OWN build. A child
/// widget's build runs outside that scope, so a widget that reads `.value`
/// without its own `Obx` is read-but-never-subscribed: it renders once with
/// the initial value and never updates again.
///
/// This fails silently — no compile error, no analyzer warning, no lint. The
/// screen simply stops responding. That is exactly the kind of bug worth
/// spending a test on, because nothing else in the toolchain will catch it.
///
/// Real example: the diet step read `isLoading.value`, the only Obx was in the
/// parent (which read `done` and `step`), and the spinner never cleared.
void main() {
  test('widgets that read observables own an Obx', () {
    // Safe because the parent Obx demonstrably reads the same observable in a
    // condition, so it rebuilds and recreates these children. Re-verify before
    // adding to this list — "it works" is not the same as "it is subscribed".
    const allowed = <String>{
      '_ReadyToCook', // home: parent reads readyToCook.isNotEmpty
      '_AlmostThere', // home: parent reads almostThere.isNotEmpty
      '_Done', // onboarding: parent reads done.value; values are final by then
    };

    final classPattern = RegExp(
        r'class (_\w+) extends StatelessWidget \{(.*?)(?=\nclass |\Z)',
        dotAll: true);
    final readsPattern = RegExp(r'controller\.\w+\.value'
        r'|c\.\w+\.value'
        r'|controller\.\w+\.(?:isNotEmpty|isEmpty|length|contains)');

    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();

      for (final match in classPattern.allMatches(source)) {
        final name = match.group(1)!;
        final body = match.group(2)!;
        if (allowed.contains(name)) continue;
        if (!readsPattern.hasMatch(body)) continue;
        if (body.contains('Obx(')) continue;
        offenders.add('${entity.path} -> $name');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These widgets read a GetX observable but have no Obx of their '
          'own, so they will render once and never update:\n'
          '  ${offenders.join('\n  ')}\n\n'
          'Wrap the returned widget in Obx(() => ...), or add the class to the '
          'allowlist in this test if a parent Obx provably reads the same '
          'observable.',
    );
  });
}
