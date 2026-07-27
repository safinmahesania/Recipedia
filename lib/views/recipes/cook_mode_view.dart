import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/cooked_service.dart';
import '../../shared/recipe_steps.dart';
import 'review_rating_view.dart';

/// Full-screen, one step at a time, for a phone propped against a jar.
///
/// Deliberately dark in both themes: this is the one screen used at arm's
/// length in a kitchen, where a bright panel is glare and the step text is the
/// only thing that matters.
///
/// NOTE: the screen will still sleep mid-cook. Adding `wakelock_plus` and
/// calling WakelockPlus.enable() in initState / disable() in dispose is a
/// two-line fix and worth doing before anyone actually cooks from this.
class CookModeView extends StatefulWidget {
  final String recipeId;
  final String title;
  final List<String> steps;
  final List<String> ingredients;

  const CookModeView({
    super.key,
    required this.recipeId,
    required this.title,
    required this.steps,
    this.ingredients = const [],
  });

  @override
  State<CookModeView> createState() => _CookModeViewState();
}

class _CookModeViewState extends State<CookModeView> {
  static const _ink = Color(0xFF08080A);
  static const _panel = Color(0x14FFFFFF);
  static const _muted = Color(0xFF9E9EA8);

  final CookedService _cooked = CookedService();
  final AuthService _auth = AuthService();

  int _index = 0;
  Timer? _ticker;
  Duration? _remaining;
  bool _running = false;
  bool _saving = false;

  String get _step => widget.steps[_index];
  bool get _isLast => _index == widget.steps.length - 1;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _go(int next) {
    if (next < 0 || next >= widget.steps.length) return;
    _ticker?.cancel();
    setState(() {
      _index = next;
      _remaining = null;
      _running = false;
    });
  }

  void _startTimer(Duration d) {
    _ticker?.cancel();
    setState(() {
      _remaining = d;
      _running = true;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      final left = (_remaining ?? Duration.zero) - const Duration(seconds: 1);
      if (left <= Duration.zero) {
        t.cancel();
        // No audio dependency, so haptics carry the alert. Heavy impact is
        // deliberate — a light tap goes unnoticed next to a hob.
        HapticFeedback.heavyImpact();
        setState(() {
          _remaining = Duration.zero;
          _running = false;
        });
      } else {
        setState(() => _remaining = left);
      }
    });
  }

  void _toggleTimer() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
    } else if (_remaining != null && _remaining! > Duration.zero) {
      _startTimer(_remaining!);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final uid = _auth.currentUser?.id;
    if (uid != null) {
      try {
        await _cooked.record(uid, widget.recipeId);
      } catch (_) {
        // Recording is a nicety; never block the user leaving the kitchen.
      }
    }
    if (!mounted) return;
    Get.back();
    Get.to(() => ReviewRatingView(
        recipeId: widget.recipeId, recipeTitle: widget.title));
  }

  @override
  Widget build(BuildContext context) {
    final suggested = RecipeSteps.durationIn(_step);
    final total = widget.steps.length;

    return Scaffold(
      backgroundColor: _ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.smd),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('STEP ${_index + 1} OF $total',
                      style: AppTextStyles.overline.copyWith(color: _muted)),
                  Row(children: [
                    if (widget.ingredients.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.list_alt, color: _muted),
                        tooltip: 'Ingredients',
                        onPressed: _showIngredients,
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: _muted),
                      tooltip: 'Exit cook mode',
                      onPressed: Get.back,
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: List.generate(
                  total,
                  (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: i == total - 1 ? 0 : AppSizes.xs),
                      child: AnimatedContainer(
                        duration: AppSizes.durBase,
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= _index
                              ? AppColors.primary
                              : const Color(0x29FFFFFF),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.xl),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _step,
                    style: AppTextStyles.displayLg.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              if (suggested != null || _remaining != null)
                _TimerPanel(
                  panel: _panel,
                  muted: _muted,
                  suggested: suggested,
                  remaining: _remaining,
                  running: _running,
                  onStart: () => _startTimer(_remaining ?? suggested!),
                  onToggle: _toggleTimer,
                  onReset: () => _startTimer(suggested ?? Duration.zero),
                ),

              const SizedBox(height: AppSizes.md),
              Row(children: [
                if (_index > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x33FFFFFF)),
                        minimumSize:
                            const Size.fromHeight(AppSizes.buttonHeight),
                      ),
                      onPressed: () => _go(_index - 1),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.smd),
                ],
                Expanded(
                  flex: _index > 0 ? 2 : 1,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPressed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                    ),
                    onPressed: _saving
                        ? null
                        : _isLast
                            ? _finish
                            : () => _go(_index + 1),
                    child: Text(_isLast ? 'Done cooking' : 'Next step'),
                  ),
                ),
              ]),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showIngredients() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161B),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ingredients',
                  style: AppTextStyles.title.copyWith(color: Colors.white)),
              const SizedBox(height: AppSizes.smd),
              ...widget.ingredients.map((i) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.xs + 2),
                    child: Row(children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AppSizes.smd),
                      Expanded(
                        child: Text(i,
                            style: AppTextStyles.bodyLg
                                .copyWith(color: Colors.white)),
                      ),
                    ]),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  final Color panel;
  final Color muted;
  final Duration? suggested;
  final Duration? remaining;
  final bool running;
  final VoidCallback onStart;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  const _TimerPanel({
    required this.panel,
    required this.muted,
    required this.suggested,
    required this.remaining,
    required this.running,
    required this.onStart,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final active = remaining != null;
    final done = remaining == Duration.zero;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          Text(done ? 'TIME IS UP' : 'TIMER',
              style: AppTextStyles.overline
                  .copyWith(color: done ? AppColors.primary : muted)),
          const SizedBox(height: AppSizes.xs),
          Text(
            RecipeSteps.format(remaining ?? suggested ?? Duration.zero),
            style: AppTextStyles.displayLg.copyWith(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.smd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (active) ...[
                _CircleButton(
                    icon: Icons.refresh, onTap: onReset, muted: muted),
                const SizedBox(width: AppSizes.smd),
              ],
              _CircleButton(
                icon: !active
                    ? Icons.play_arrow
                    : (running ? Icons.pause : Icons.play_arrow),
                onTap: active ? onToggle : onStart,
                primary: true,
                muted: muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final Color muted;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.muted,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = primary ? 48.0 : 40.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary ? AppColors.primary : const Color(0x1FFFFFFF),
        ),
        child: Icon(icon,
            color: primary ? Colors.white : muted, size: primary ? 26 : 20),
      ),
    );
  }
}
