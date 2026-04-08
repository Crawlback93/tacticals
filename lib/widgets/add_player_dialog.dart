import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, TextEditingValue, TextInputFormatter;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'custom_input.dart' as wi;

/// Dialog for adding a custom player to the squad.
class AddPlayerDialog extends StatefulWidget {
  const AddPlayerDialog({super.key});

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  String _selectedPosition = 'Midfielder';
  String? _nameError;
  String? _numberError;

  static const _positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Attacker',
  ];

  static const _positionIcons = {
    'Goalkeeper': LucideIcons.handMetal,
    'Defender': LucideIcons.shield,
    'Midfielder': LucideIcons.activity,
    'Attacker': LucideIcons.zap,
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final numberText = _numberCtrl.text.trim();
    String? nameError;
    String? numberError;

    if (name.isEmpty) nameError = 'Name is required';
    if (numberText.isEmpty) {
      numberError = 'Number is required';
    } else if (int.tryParse(numberText) == null) {
      numberError = 'Must be a whole number';
    } else {
      final n = int.parse(numberText);
      if (n < 1 || n > 99) numberError = 'Must be between 1 and 99';
    }

    if (nameError != null || numberError != null) {
      setState(() {
        _nameError = nameError;
        _numberError = numberError;
      });
      return;
    }

    Navigator.of(context).pop({
      'name': name,
      'number': int.parse(numberText),
      'position': _selectedPosition,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title row
            Row(
              children: [
                const Icon(
                  LucideIcons.userPlus,
                  color: Color(0xFFFDD329),
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Add Custom Player',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Icon(
                      LucideIcons.x,
                      color: Colors.white.withValues(alpha: 0.35),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name
            wi.CustomInput(
              label: 'Name',
              hint: 'Player name...',
              leadingIcon: LucideIcons.user,
              controller: _nameCtrl,
              errorText: _nameError,
              textInputAction: TextInputAction.next,
              autofocus: true,
              maxLength: 32,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 12),

            // Number
            wi.CustomInput(
              label: 'Number',
              hint: '1 – 99',
              leadingIcon: LucideIcons.hash,
              controller: _numberCtrl,
              errorText: _numberError,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _NumberRangeFormatter(min: 1, max: 99),
              ],
              onChanged: (_) {
                if (_numberError != null) setState(() => _numberError = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),

            // Position
            Text(
              'POSITION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _positions.map((pos) {
                final isSelected = _selectedPosition == pos;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: pos == _positions.last ? 0 : 6,
                    ),
                    child: _PositionChip(
                      label: pos,
                      icon: _positionIcons[pos]!,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedPosition = pos),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(),
                    isSecondary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(label: 'Add Player', onTap: _submit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Position Chip ─────────────────────────────────────────────────────────────

class _PositionChip extends StatefulWidget {
  const _PositionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_PositionChip> createState() => _PositionChipState();
}

class _PositionChipState extends State<_PositionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 44,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFFFDD329).withValues(alpha: 0.15)
                : _hovered
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFFFDD329).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.isSelected
                    ? const Color(0xFFFDD329)
                    : Colors.white.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: widget.isSelected
                      ? const Color(0xFFFDD329)
                      : Colors.white.withValues(alpha: 0.45),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dialog Button ─────────────────────────────────────────────────────────────

class _DialogButton extends StatefulWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    this.isSecondary = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 44,
          decoration: BoxDecoration(
            color: widget.isSecondary
                ? Colors.white.withValues(alpha: _hovered ? 0.08 : 0.05)
                : _hovered
                ? const Color(0xFFFDD329)
                : const Color(0xFFFDD329).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: widget.isSecondary
                ? Border.all(color: Colors.white.withValues(alpha: 0.12))
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: widget.isSecondary
                  ? Colors.white.withValues(alpha: 0.6)
                  : const Color(0xFF003907),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Number Range Formatter ───────────────────────────────────────────────────

class _NumberRangeFormatter extends TextInputFormatter {
  const _NumberRangeFormatter({required this.min, required this.max});
  final int min;
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    // Block zero and leading zeros (e.g. "0", "00", "007")
    if (newValue.text.startsWith('0')) return oldValue;
    final n = int.tryParse(newValue.text);
    if (n == null) return oldValue;
    if (n > max) return oldValue;
    return newValue;
  }
}
