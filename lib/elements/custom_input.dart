import 'package:flutter/material.dart';

class CustomInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final IconData? leadingIcon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final TextInputType? keyboardType;
  final Color accentColor;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  const CustomInput({
    super.key,
    this.label,
    this.hint,
    this.leadingIcon,
    this.controller,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.accentColor = const Color(0xFFFDD329),
    this.obscureText = false,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _isHovered = false;
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Optional label
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              widget.label!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        // Input field
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _isHovered ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                onTap: widget.onTap,
                readOnly: widget.readOnly,
                autofocus: widget.autofocus,
                keyboardType: widget.keyboardType,
                obscureText: _obscure,
                cursorColor: widget.accentColor,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: _isHovered ? 0.7 : 0.6),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(
                      alpha: _isHovered ? 0.5 : 0.4,
                    ),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  prefixIcon: widget.leadingIcon != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: 16, right: 12),
                          child: Icon(
                            widget.leadingIcon,
                            color: Colors.white.withValues(
                              alpha: _isHovered ? 0.5 : 0.4,
                            ),
                            size: 18,
                          ),
                        )
                      : null,
                  prefixIconConstraints: widget.leadingIcon != null
                      ? const BoxConstraints(minWidth: 46, minHeight: 44)
                      : null,
                  suffixIcon: widget.obscureText
                      ? GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withValues(
                                alpha: _isHovered ? 0.5 : 0.35,
                              ),
                              size: 18,
                            ),
                          ),
                        )
                      : null,
                  suffixIconConstraints: widget.obscureText
                      ? const BoxConstraints(minWidth: 46, minHeight: 44)
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: widget.leadingIcon != null ? 0 : 16,
                    vertical: 0,
                  ),
                  isCollapsed: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
