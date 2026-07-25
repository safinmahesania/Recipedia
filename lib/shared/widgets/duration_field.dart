import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';

/// Cook-time input: type a number, or step it with +/-.
/// The unit ("min") is fixed and shown inline, so the user never types it.
/// Value is stored/returned as e.g. "30 min".
class DurationField extends StatefulWidget {
  final String? initial;      // e.g. "30 min" or "30"
  final int step;             // +/- increment
  final ValueChanged<String> onChanged;

  const DurationField({
    Key? key,
    this.initial,
    this.step = 5,
    required this.onChanged,
  }) : super(key: key);

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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
          ),
          // fixed unit — user never types this
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text('min',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ),
          _stepButton(Icons.add, () => _bump(widget.step)),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
        ),
      );
}
