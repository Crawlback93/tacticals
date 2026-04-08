import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? label;
  final int? width;
  final Color accentColor;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.label,
    this.width,
    this.accentColor = const Color(0xFFFDD329),
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  bool _isHovered = false;

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
        // Dropdown field
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            width: widget.width?.toDouble(),
            constraints: widget.width != null
                ? null
                : const BoxConstraints(minWidth: 160, maxWidth: 320),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _isHovered ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
                value: widget.value,
                items: widget.items,
                onChanged: widget.onChanged,
                hint: widget.hint != null
                    ? Text(
                        widget.hint!,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: _isHovered ? 0.5 : 0.4,
                          ),
                          fontSize: 14,
                        ),
                      )
                    : null,
                icon: Icon(
                  LucideIcons.chevronDown,
                  color: _isHovered
                      ? widget.accentColor
                      : Colors.white.withValues(alpha: 0.4),
                  size: 18,
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: _isHovered ? 0.7 : 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                dropdownColor: const Color(0xFF2A2A2A),
                isExpanded: true,
                focusColor: Colors.transparent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
