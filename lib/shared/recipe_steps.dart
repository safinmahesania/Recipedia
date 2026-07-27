/// Parsing for free-text instructions.
///
/// Source recipes store instructions as one blob. Splitting them is needed in
/// two places — the detail screen and cook mode — so it lives here rather than
/// drifting between the two.
class RecipeSteps {
  RecipeSteps._();

  /// Splits instructions into steps.
  ///
  /// Line breaks first. When there are none — which is the case for most of the
  /// imported catalogue, where instructions are one long blob — fall back to
  /// sentence boundaries. Returning an empty list here used to disable "Start
  /// cooking" on nearly every recipe.
  static List<String> split(String raw) {
    final byLine = raw
        .split(RegExp(r'\r?\n+'))
        .map(_clean)
        .where((s) => s.isNotEmpty)
        .toList();
    if (byLine.length > 1) return byLine;

    final blob = _clean(raw);
    if (blob.isEmpty) return const [];

    // Split after . ! ? followed by a space and a capital. Decimals ("1.5 cm")
    // and abbreviations survive because the next character is not upper case.
    final bySentence = blob
        .split(RegExp(r'(?<=[.!?])\s+(?=[A-Z])'))
        .map(_clean)
        .where((s) => s.length > 3)
        .toList();

    // One sentence is not a set of steps — better to show a paragraph than a
    // one-step cook mode.
    return bySentence.length > 1 ? bySentence : const [];
  }

  /// Always returns something cookable, even for a single-paragraph recipe.
  /// Used by cook mode, which must never be handed an empty list.
  static List<String> stepsOrWhole(String raw) {
    final parts = split(raw);
    if (parts.isNotEmpty) return parts;
    final whole = _clean(raw);
    return whole.isEmpty ? const [] : [whole];
  }

  static String _clean(String s) =>
      s.trim().replaceFirst(RegExp(r'^\d+[.)]\s*'), '');

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

  /// Minutes from free-text cook time ("35 min", "1 hr 10 min"). Unparseable
  /// values sort last rather than pretending to be zero.
  static int minutes(dynamic raw) {
    final t = (raw ?? '').toString().toLowerCase();
    if (t.isEmpty) return 1 << 30;
    final h = RegExp(r'(\d+)\s*(h|hr|hour)').firstMatch(t);
    final m = RegExp(r'(\d+)\s*(m|min)').firstMatch(t);
    if (h == null && m == null) {
      final bare = RegExp(r'(\d+)').firstMatch(t);
      return bare == null ? 1 << 30 : int.parse(bare.group(1)!);
    }
    return (int.tryParse(h?.group(1) ?? '0') ?? 0) * 60 +
        (int.tryParse(m?.group(1) ?? '0') ?? 0);
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
