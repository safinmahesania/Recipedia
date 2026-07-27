import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../shared/widgets/app_icon.dart';
import '../../theme/app_tokens.dart';

/// "Check your inbox" and "Link sent" are the same screen with different words,
/// so they are one widget. Both are the moment a flow hands off to email, and
/// both need the same three things: what was sent, where, and a way out if the
/// address was wrong.
class MailSentView extends StatefulWidget {
  final String title;
  final String email;
  final String message;

  /// Label for the escape hatch — "Change email" during signup, "Try another
  /// email" during password reset.
  final String changeLabel;
  final Future<void> Function()? onResend;

  const MailSentView({
    super.key,
    required this.title,
    required this.email,
    required this.message,
    required this.changeLabel,
    this.onResend,
  });

  @override
  State<MailSentView> createState() => _MailSentViewState();
}

class _MailSentViewState extends State<MailSentView> {
  static const _cooldown = 60;
  int _left = _cooldown;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    _ticker?.cancel();
    setState(() => _left = _cooldown);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_left <= 1) {
        t.cancel();
        setState(() => _left = 0);
      } else {
        setState(() => _left--);
      }
    });
  }

  String get _clock =>
      '0:${_left.toString().padLeft(2, '0')}';

  Future<void> _resend() async {
    if (_left > 0 || widget.onResend == null) return;
    await widget.onResend!();
    if (!mounted) return;
    _start();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Sent again')));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              SizedBox(
                height: 158,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: t.categoryTints[1],
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusXl),
                      ),
                    ),
                    Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: t.canvas
                                .withValues(alpha: isDark ? 0.18 : 0.55)),
                      ),
                    ),
                    Container(
                      width: 96,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.surfaceRaised,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: t.cardShadow,
                      ),
                      child: AppIcon('mail_outline',
                          fallback: Icons.mail_outline,
                          size: 34,
                          color: t.categoryGlyphs[1]),
                    ),
                    Positioned(
                      right: 44,
                      bottom: 26,
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.successTint,
                          boxShadow: t.cardShadow,
                        ),
                        child: AppIcon('check',
                            fallback: Icons.check,
                            size: 18,
                            color: t.onSuccessTint),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(widget.title,
                  textAlign: TextAlign.center, style: text.headlineMedium),
              const SizedBox(height: AppSizes.sm),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: widget.message),
                  TextSpan(
                      text: widget.email,
                      style: text.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const TextSpan(text: '.'),
                ]),
                textAlign: TextAlign.center,
                style:
                    text.bodyMedium?.copyWith(color: t.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSizes.lg),
              Container(
                padding: const EdgeInsets.all(AppSizes.smd),
                decoration: BoxDecoration(
                  color: t.surfaceRaised,
                  border: Border.all(color: t.cardBorder),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: t.cardShadow,
                ),
                child: Row(children: [
                  AppIcon('info_outline',
                      fallback: Icons.info_outline,
                      size: AppSizes.iconMd,
                      color: t.onWarningTint),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _left > 0
                        ? Text('Nothing yet? Check spam, or resend in $_clock',
                            style: text.labelSmall
                                ?.copyWith(color: t.textSecondary))
                        : GestureDetector(
                            onTap: _resend,
                            child: Text('Send it again',
                                style: text.labelMedium
                                    ?.copyWith(color: t.onBrandTint)),
                          ),
                  ),
                ]),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: Get.back,
                  child: Text('Wrong address? ${widget.changeLabel}'),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
          ),
        ),
      ),
    );
  }
}
