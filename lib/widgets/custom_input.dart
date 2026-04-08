import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement, TextInputFormatter;
import 'package:lucide_icons_flutter/lucide_icons.dart';

// ─── Design Tokens (from TactBoard Figma UI Kit) ──────────────────────────────

const _kAccent = Color(0xFFFDD329);
const _kErrorColor = Color(0xFFFF6666);
const _kBorderError = Color(0xFFFF3333);
const _kRadius = 24.0;
const _kHeight = 44.0;
const _kLabelFontSize = 12.0;
const _kInputFontSize = 14.0;
const _kHPad = 16.0;
const _kTrailingPad = 14.0;

// ─── CustomInput ──────────────────────────────────────────────────────────────

class CustomInput extends StatefulWidget {
  const CustomInput({
    super.key,
    this.label,
    this.hint,
    this.leadingIcon,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.isPassword = false,
    this.enabled = true,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.inputFormatters,
    this.maxLength,
  });

  final String? label;
  final String? hint;
  final IconData? leadingIcon;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isPassword;
  final bool enabled;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focus;
  late final AnimationController _anim;
  late final Animation<double> _bgAnim;
  late final Animation<double> _borderAnim;

  bool _isHovered = false;
  bool _isFocused = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(_onFocusChange);

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _bgAnim = Tween<double>(
      begin: 0.05,
      end: 0.10,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _borderAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focus.hasFocus);
    _isFocused ? _anim.forward() : _anim.reverse();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focus.dispose();
    } else {
      _focus.removeListener(_onFocusChange);
    }
    _anim.dispose();
    super.dispose();
  }

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  Color get _iconColor {
    if (!widget.enabled) return Colors.white.withValues(alpha: 0.25);
    if (_isFocused) {
      return _hasError ? _kErrorColor : _kAccent.withValues(alpha: 0.8);
    }
    if (_isHovered) return Colors.white.withValues(alpha: 0.7);
    return Colors.white.withValues(alpha: 0.4);
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            _Label(text: widget.label!),
            const SizedBox(height: 4),
          ],
          _InputField(
            anim: _anim,
            bgAnim: _bgAnim,
            borderAnim: _borderAnim,
            focus: _focus,
            isHovered: _isHovered,
            isFocused: _isFocused,
            hasError: _hasError,
            iconColor: _iconColor,
            isObscured: _isObscured && widget.isPassword,
            widget: widget,
            onHoverChange: (v) => setState(() => _isHovered = v),
            onToggleObscure: () => setState(() => _isObscured = !_isObscured),
          ),
          if (_hasError) ...[
            const SizedBox(height: 4),
            _ErrorText(text: widget.errorText!),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Raleway',
        fontSize: _kLabelFontSize,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
        color: Colors.white,
        height: 1.0,
      ).withOpacity(0.5),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(LucideIcons.circleAlert, size: 12, color: _kErrorColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: _kErrorColor,
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.anim,
    required this.bgAnim,
    required this.borderAnim,
    required this.focus,
    required this.isHovered,
    required this.isFocused,
    required this.hasError,
    required this.iconColor,
    required this.isObscured,
    required this.widget,
    required this.onHoverChange,
    required this.onToggleObscure,
  });

  final AnimationController anim;
  final Animation<double> bgAnim;
  final Animation<double> borderAnim;
  final FocusNode focus;
  final bool isHovered;
  final bool isFocused;
  final bool hasError;
  final Color iconColor;
  final bool isObscured;
  final CustomInput widget;
  final ValueChanged<bool> onHoverChange;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final bgOpacity = isHovered && !isFocused ? 0.08 : bgAnim.value;

        final Border? border = hasError
            ? Border.all(color: _kBorderError.withValues(alpha: 0.5), width: 1)
            : isFocused
            ? Border.all(color: _kAccent.withValues(alpha: 0.6), width: 1)
            : isHovered
            ? Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1)
            : null;

        return MouseRegion(
          onEnter: (_) => onHoverChange(true),
          onExit: (_) => onHoverChange(false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: _kHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: bgOpacity),
              borderRadius: BorderRadius.circular(_kRadius),
              border: border,
            ),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          // Leading icon
          if (widget.leadingIcon != null) ...[
            const SizedBox(width: _kHPad),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                widget.leadingIcon,
                key: ValueKey(iconColor),
                size: 16,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 8),
          ] else
            const SizedBox(width: _kHPad),

          // TextField
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: focus,
              enabled: widget.enabled,
              obscureText: isObscured,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofocus: widget.autofocus,
              inputFormatters: widget.inputFormatters,
              maxLength: widget.maxLength,
              maxLengthEnforcement: widget.maxLength != null
                  ? MaxLengthEnforcement.enforced
                  : null,
              buildCounter: widget.maxLength != null
                  ? (_, {required currentLength, required isFocused, maxLength}) => null
                  : null,
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: _kInputFontSize,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              cursorColor: _kAccent,
              cursorWidth: 2,
              selectionControls: _TactBoardTextSelectionControls(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: _kInputFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),

          // Trailing: password toggle or just padding
          if (widget.isPassword)
            _PasswordToggle(isObscured: isObscured, onTap: onToggleObscure)
          else
            const SizedBox(width: _kTrailingPad),
        ],
      ),
    );
  }
}

class _PasswordToggle extends StatefulWidget {
  const _PasswordToggle({required this.isObscured, required this.onTap});
  final bool isObscured;
  final VoidCallback onTap;

  @override
  State<_PasswordToggle> createState() => _PasswordToggleState();
}

class _PasswordToggleState extends State<_PasswordToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kTrailingPad),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Icon(
              widget.isObscured ? LucideIcons.eyeOff : LucideIcons.eye,
              key: ValueKey(widget.isObscured),
              size: 16,
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom selection controls to match accent color
class _TactBoardTextSelectionControls extends MaterialTextSelectionControls {
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    return super.buildHandle(context, type, textLineHeight, onTap);
  }
}

// ─── Extension helper ─────────────────────────────────────────────────────────

extension _TextStyleOpacity on TextStyle {
  TextStyle withOpacity(double opacity) =>
      copyWith(color: color?.withValues(alpha: opacity));
}

// ─── Preview / Demo widget ────────────────────────────────────────────────────

/// Drop this on a dark background to preview all states.
class CustomInputPreview extends StatefulWidget {
  const CustomInputPreview({super.key});

  @override
  State<CustomInputPreview> createState() => _CustomInputPreviewState();
}

class _CustomInputPreviewState extends State<CustomInputPreview> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _emailError;

  void _validate() {
    setState(() {
      _emailError = _emailCtrl.text.isEmpty
          ? 'Email is required'
          : !_emailCtrl.text.contains('@')
          ? 'Enter a valid email address'
          : null;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131314), // gray/700
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'CustomInput — Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 32),

                // Default — no label, no icon
                const CustomInput(hint: 'Enter your name...'),
                const SizedBox(height: 16),

                // With label + leading icon
                CustomInput(
                  label: 'Email',
                  hint: 'user@example.com',
                  leadingIcon: LucideIcons.mail,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                ),
                const SizedBox(height: 16),

                // Password
                CustomInput(
                  label: 'Password',
                  hint: '••••••••',
                  leadingIcon: LucideIcons.lock,
                  controller: _passwordCtrl,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _validate(),
                ),
                const SizedBox(height: 16),

                // Error state (static)
                const CustomInput(
                  label: 'Username',
                  hint: 'Enter username...',
                  leadingIcon: LucideIcons.user,
                  errorText: 'Username is already taken',
                ),
                const SizedBox(height: 16),

                // Disabled state
                const CustomInput(
                  label: 'Team',
                  hint: 'Auto-assigned',
                  leadingIcon: LucideIcons.shield,
                  enabled: false,
                ),
                const SizedBox(height: 32),

                // Submit button
                _PreviewButton(label: 'Validate', onTap: _validate),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewButton extends StatefulWidget {
  const _PreviewButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_PreviewButton> createState() => _PreviewButtonState();
}

class _PreviewButtonState extends State<_PreviewButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 44,
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFFDD329)
                : const Color(0xFFFDD329).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(_kRadius),
          ),
          alignment: Alignment.center,
          child: const Text(
            'VALIDATE',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Color(0xFF003907), // green/700
            ),
          ),
        ),
      ),
    );
  }
}
