/// Parsing for free-text instructions.
///
/// Source recipes store instructions as one blob. Splitting them is needed in
/// two places — the detail screen and cook mode — so it lives here rather than
/// drifting between the two.
class RecipeSteps {
  RecipeSteps._();

  /// Splits on line breaks and strips any leading "1." / "2)" numbering, since
  /// the UI supplies its own. Returns an empty list when there is only one
  /// block, which is the signal to render it as a paragraph instead.
  static List<String> split(String raw) {
    final parts = raw
        .split(RegExp(r'\r?\n+'))
        .map((s) => s.trim().replaceFirst(RegExp(r'^\d+[.)]\s*'), ''))
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.length > 1 ? parts : const [];
  }

  static final _duration = RegExp(
    r'(\d+)\s*(?:-|to|–)?\s*(\d+)?\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?)',
    caseSensitive: false,
  );

  /// Finds a cooking duration mentioned in a step, so cook mode can offer a
  /// timer instead of making the user set one.
  ///
  /// For a range ("simmer 10-12 minutes") it takes the LONGER end. A timer that
  /// fires early is worse than one that fires late — you can always check the
  /// pan, but you cannot un-burn it.
  static Duration? durationIn(String step) {
    final m = _duration.firstMatch(step);
    if (m == null) return null;

    final low = int.tryParse(m.group(1) ?? '') ?? 0;
    final high = int.tryParse(m.group(2) ?? '') ?? low;
    final value = high > low ? high : low;
    if (value <= 0) return null;

    final unit = (m.group(3) ?? '').toLowerCase();
    if (unit.startsWith('h')) return Duration(hours: value);
    if (unit.startsWith('s')) return Duration(seconds: value);
    return Duration(minutes: value);
  }

  static String format(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:${m.padLeft(2, '0')}:$s';
    }
    return '$m:$s';
  }
}
