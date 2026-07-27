import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';

/// Cook-time input: type a number, or step it with +/-.
/// The unit ("min") is fixed and shown inline, so the user never types it.
/// Value is stored/returned as e.g. "30 min".
class DurationField extends StatefulWidget {
  final String? initial;      // e.g. "30 min" or "30"
  final int step;             // +/- increment
  final ValueChanged<String> onChanged;

  const DurationField({
    super.key,
    this.initial,
    this.step = 5,
    required this.onChanged,
  });

  @override
  State<DurationField> createState() => _DurationFieldState();
}

class _DurationFieldState extends State<DurationField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _numberFrom(widget.initial));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Pulls just the digits out of "30 min" -> "30".
  String _numberFrom(String? raw) {
    if (raw == null) return '';
    final m = RegExp(r'\d+').firstMatch(raw);
    return m?.group(0) ?? '';
  }

  int get _current => int.tryParse(_ctrl.text.trim()) ?? 0;

  void _emit() {
    final n = _current;
    widget.onChanged(n <= 0 ? '' : '$n min');
  }

  void _bump(int delta) {
    final next = (_current + delta).clamp(0, 999);
    _ctrl.text = next == 0 ? '' : '$next';
    setState(() {});
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          _stepButton(Icons.remove, () => _bump(-widget.step)),
          Expanded(
            child: TextField(
              controller: _ctrl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _emit(),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                isDense: true,
              ),
              style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // fixed unit — user never types this
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.smd),
            child: Text('min',
                style: text.bodyMedium?.copyWith(color: t.textSecondary)),
          ),
          _stepButton(Icons.add, () => _bump(widget.step)),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) => Builder(
        builder: (context) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon,
                  size: AppSizes.iconMd, color: context.tokens.brand),
            ),
          ),
        ),
      );
}
