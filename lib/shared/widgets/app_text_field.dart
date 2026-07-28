import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';
import 'app_icon.dart';

/// Labelled input. Colours, radius, fill and focus ring come from
/// inputDecorationTheme, so this adapts to dark mode automatically.
///
/// StatefulWidget because password fields own a reveal toggle: typing a
/// password blind on a phone keyboard is the single most common reason people
/// fail a login they actually know the answer to.
class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final String? errorText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  /// Tabler icon name shown inside the field, e.g. `mail`, `lock`, `person`.
  final String? icon;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.maxLines = 1,
    this.onChanged,
    this.icon,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: text.labelMedium?.copyWith(color: t.textSecondary)),
        const SizedBox(height: AppSizes.xs + 2),
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          onChanged: widget.onChanged,
          style: text.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: widget.icon == null
                ? null
                : FieldIcon(widget.icon!),
            suffixIcon: !widget.obscure
                ? null
                : GestureDetector(
                    onTap: () => setState(() => _hidden = !_hidden),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSizes.smd),
                      child: FieldIcon(
                          _hidden ? 'visibility' : 'visibility_off',
                          ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
