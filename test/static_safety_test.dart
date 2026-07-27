import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Guards for bug classes that shipped to a device before being caught.
///
/// Every one of these compiled cleanly and passed `flutter analyze`. They
/// surfaced as a crash, a blank screen, or literal template text on a card.
/// Static analysis cannot see any of them, so they live here instead.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String read(File f) => f.readAsStringSync();

  // ---------------------------------------------------------------- painting

  test('BoxDecoration never sets both color and gradient', () {
    // Mutually exclusive by assertion. Crashes on first paint, not at build.
    final offenders = <String>[];
    for (final f in dartFiles) {
      final src = read(f);
      for (final m in RegExp(r'BoxDecoration\(').allMatches(src)) {
        final seg = src.substring(
            m.start, (m.start + 700).clamp(0, src.length));
        if (RegExp(r'\bcolor:').hasMatch(seg) &&
            RegExp(r'\bgradient:').hasMatch(seg)) {
          offenders.add('${f.path}:${'\n'.allMatches(src.substring(0, m.start)).length + 1}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'color and gradient cannot coexist on a BoxDecoration:\n'
            '  ${offenders.join('\n  ')}');
  });

  test('a borderRadius is never paired with a multi-colour Border', () {
    // Flutter requires uniform border colours to round the corners.
    final offenders = <String>[];
    for (final f in dartFiles) {
      final src = read(f);
      for (final m in RegExp(r'BoxDecoration\(').allMatches(src)) {
        final seg = src.substring(
            m.start, (m.start + 900).clamp(0, src.length));
        if (!seg.contains('borderRadius')) continue;
        if (!RegExp(r'border:\s*Border\(').hasMatch(seg)) continue;
        final sides = RegExp(r'(?:top|right|bottom|left):\s*BorderSide\(([^)]*)\)')
            .allMatches(seg)
            .map((s) => s.group(1))
            .toSet();
        if (sides.length > 1) {
          offenders.add('${f.path}:${'\n'.allMatches(src.substring(0, m.start)).length + 1}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Non-uniform Border with borderRadius:\n'
            '  ${offenders.join('\n  ')}');
  });

  // ------------------------------------------------------------------ string

  test('no escaped dollar sign disables interpolation', () {
    // `\$foo` renders the literal text. Shipped once as "${d.inDays} d ago"
    // on every report card.
    final offenders = <String>[];
    for (final f in dartFiles) {
      final lines = read(f).split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'\\\$\{?\w').hasMatch(lines[i])) {
          offenders.add('${f.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Escaped \$ prevents interpolation:\n  ${offenders.join('\n  ')}');
  });

  // ------------------------------------------------------------------ assets

  test('every AppIcon name has a matching SVG', () {
    // A missing name silently falls back to a Material glyph, which is how
    // the Google and Apple buttons nearly shipped as blank circles.
    final available = Directory('assets/icons')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last.replaceAll('.svg', ''))
        .toSet();

    final missing = <String>{};
    for (final f in dartFiles) {
      final src = read(f);
      for (final m in RegExp(r"AppIcon\(\s*'([a-z_0-9]+)'").allMatches(src)) {
        if (!available.contains(m.group(1))) missing.add(m.group(1)!);
      }
      for (final m in RegExp(r"icon: '([a-z_0-9]+)'").allMatches(src)) {
        if (!available.contains(m.group(1))) missing.add(m.group(1)!);
      }
    }
    expect(missing, isEmpty,
        reason: 'Icon names with no asset: ${missing.join(', ')}');
  });

  // -------------------------------------------------------------- PostgREST

  test('every embedded select follows a declared foreign key', () {
    // PostgREST can only embed across a real FK. `reports` is polymorphic, so
    // reports.select('recipes(...)') failed at runtime with PGRST200.
    final sql = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .map((f) => f.readAsStringSync())
        .join('\n');

    final links = <String, Set<String>>{};
    void link(String a, String b) {
      (links[a] ??= <String>{}).add(b);
      (links[b] ??= <String>{}).add(a);
    }

    for (final t in RegExp(
            r'create table (?:if not exists )?public\.(\w+)\s*\((.*?)\n\);',
            dotAll: true)
        .allMatches(sql)) {
      final child = t.group(1)!;
      for (final r
          in RegExp(r'references public\.(\w+)').allMatches(t.group(2)!)) {
        link(child, r.group(1)!);
      }
    }

    final offenders = <String>[];
    for (final f in dartFiles.where((f) => f.path.contains('/services/'))) {
      final src = read(f);
      for (final q in RegExp(r"\.from\('(\w+)'\)[\s\S]{0,120}?\.select\(\s*((?:'[^']*'\s*)+)")
          .allMatches(src)) {
        final table = q.group(1)!;
        final sel = RegExp("'([^']*)'")
            .allMatches(q.group(2)!)
            .map((m) => m.group(1))
            .join();
        // Only check the outermost embeds; nested ones hop through a parent
        // that this simple parse cannot follow.
        for (final e in RegExp(r'(\w+)\s*\(').allMatches(sel)) {
          final embed = e.group(1)!;
          if (embed == table) continue;
          final reachable = links[table] ?? const <String>{};
          if (reachable.contains(embed)) continue;
          // Nested: reachable from anything the table can reach.
          final twoHop = reachable
              .expand((n) => links[n] ?? const <String>{})
              .toSet();
          if (twoHop.contains(embed)) continue;
          offenders.add('${f.path}: $table.select -> $embed(...)');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Embeds with no foreign key to follow:\n'
            '  ${offenders.toSet().join('\n  ')}');
  });

  // ------------------------------------------------------------ architecture

  test('services never import Flutter', () {
    // A service that shows a snackbar cannot be reused or tested headlessly.
    final offenders = dartFiles
        .where((f) => f.path.contains('/services/'))
        .where((f) => read(f).contains('package:flutter/'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty,
        reason: 'Services must stay UI-free:\n  ${offenders.join('\n  ')}');
  });

  test('views never call Supabase directly', () {
    final offenders = dartFiles
        .where((f) => f.path.contains('/views/'))
        .where((f) => RegExp(r'\bsupabase\.').hasMatch(read(f)))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty,
        reason: 'Data access belongs in a service:\n  ${offenders.join('\n  ')}');
  });
}
