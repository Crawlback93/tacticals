import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'football_pitch_painter.dart' show FieldStyle;

/// Collapsible field controls toolbar with animation
class FieldControlsToolbar extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onToggle;
  final bool isVertical;
  final bool isTransitioning;
  final Future<void> Function(bool) onOrientationChange;
  final double fieldScale;
  final ValueChanged<double> onScaleChange;
  final bool showSnapPoints;
  final VoidCallback onSnapPointsToggle;
  final bool magnetize;
  final VoidCallback onMagnetizeToggle;
  final String selectedFormation;
  final List<String> formations;
  final ValueChanged<String> onFormationChanged;
  final bool showPlayerNames;
  final VoidCallback onPlayerNamesToggle;
  final VoidCallback onClearField;

  const FieldControlsToolbar({
    super.key,
    required this.isVisible,
    required this.onToggle,
    required this.isVertical,
    required this.isTransitioning,
    required this.onOrientationChange,
    required this.fieldScale,
    required this.onScaleChange,
    required this.showSnapPoints,
    required this.onSnapPointsToggle,
    required this.magnetize,
    required this.onMagnetizeToggle,
    required this.selectedFormation,
    required this.formations,
    required this.onFormationChanged,
    required this.showPlayerNames,
    required this.onPlayerNamesToggle,
    required this.onClearField,
  });

  @override
  State<FieldControlsToolbar> createState() => FieldControlsToolbarState();
}

class FieldControlsToolbarState extends State<FieldControlsToolbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _toolbarSlide;
  late final Animation<double> _toolbarFade;
  late final Animation<double> _buttonScale;
  late final Animation<double> _buttonRotation;

  bool _showToolbar = true;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    // Single controller for both button and toolbar animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Button animates in first half (0.0 - 0.4)
    _buttonScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInQuad),
      ),
    );

    _buttonRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInQuad),
      ),
    );

    // Toolbar animates in second half (0.3 - 1.0)
    _toolbarSlide = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutQuad),
      ),
    );

    _toolbarFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    // Start with toolbar visible by default
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant FieldControlsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _openToolbar();
      } else {
        _closeToolbar();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openToolbar() {
    if (!_showToolbar) {
      setState(() {
        _showToolbar = true;
        _isAnimating = true;
      });
      _controller.forward().then((_) {
        if (mounted) setState(() => _isAnimating = false);
      });
    }
  }

  void _closeToolbar() {
    setState(() => _isAnimating = true);
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showToolbar = false;
          _isAnimating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showToolbar) {
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _buttonScale.value,
              child: Transform.rotate(
                angle: _buttonRotation.value * math.pi,
                child: child,
              ),
            );
          },
          child: _FieldControlsToggleButton(onPressed: widget.onToggle),
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_toolbarSlide.value, 0),
            child: Opacity(opacity: _toolbarFade.value, child: child),
          );
        },
        child: IgnorePointer(
          ignoring: _isAnimating,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close Button
                    _ToolbarButton(
                      icon: LucideIcons.x,
                      onPressed: widget.onToggle,
                      tooltip: 'Close Controls',
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 24, color: Colors.white24),
                    const SizedBox(width: 8),
                    // Orientation Toggle
                    Row(
                      children: [
                        _OrientationButton(
                          icon: LucideIcons.rectangleHorizontal,
                          isSelected: !widget.isVertical,
                          onPressed: () {
                            if (widget.isVertical && !widget.isTransitioning) {
                              widget.onOrientationChange(false);
                            }
                          },
                          tooltip: 'Horizontal',
                        ),
                        const SizedBox(width: 8),
                        _OrientationButton(
                          icon: LucideIcons.rectangleVertical,
                          isSelected: widget.isVertical,
                          onPressed: () {
                            if (!widget.isVertical && !widget.isTransitioning) {
                              widget.onOrientationChange(true);
                            }
                          },
                          tooltip: 'Vertical',
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 24, color: Colors.white24),
                    const SizedBox(width: 8),
                    // Scale
                    Row(
                      children: [
                        _ToolbarButton(
                          icon: LucideIcons.minus,
                          onPressed: () {
                            widget.onScaleChange(
                              ((widget.fieldScale * 10 - 1) / 10).clamp(
                                0.5,
                                1.0,
                              ),
                            );
                          },
                          tooltip: 'Decrease scale',
                        ),
                        const SizedBox(width: 8),
                        _ToolbarButton(
                          icon: LucideIcons.plus,
                          onPressed: () {
                            widget.onScaleChange(
                              ((widget.fieldScale * 10 + 1) / 10).clamp(
                                0.5,
                                1.0,
                              ),
                            );
                          },
                          tooltip: 'Increase scale',
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 24, color: Colors.white24),
                    const SizedBox(width: 8),
                    // Snap Points Toggle
                    _ToolbarButton(
                      icon: LucideIcons.grid3x3,
                      isSelected: widget.showSnapPoints,
                      onPressed: widget.onSnapPointsToggle,
                      tooltip: widget.showSnapPoints
                          ? 'Hide Snap Points'
                          : 'Show Snap Points',
                    ),
                    const SizedBox(width: 8),
                    // Magnetize Toggle
                    _ToolbarButton(
                      icon: LucideIcons.magnet,
                      isSelected: widget.magnetize,
                      onPressed: widget.onMagnetizeToggle,
                      tooltip: widget.magnetize
                          ? 'Disable Magnetize'
                          : 'Enable Magnetize',
                    ),
                    const SizedBox(width: 8),
                    // Formation Dropdown Button
                    _FormationButton(
                      formation: widget.selectedFormation,
                      formations: widget.formations,
                      onChanged: widget.onFormationChanged,
                    ),
                    const SizedBox(width: 8),
                    // Show Names Toggle
                    _ToolbarButton(
                      icon: LucideIcons.tag,
                      isSelected: widget.showPlayerNames,
                      onPressed: widget.onPlayerNamesToggle,
                      tooltip: widget.showPlayerNames
                          ? 'Hide Names'
                          : 'Show Names',
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 24, color: Colors.white24),
                    const SizedBox(width: 8),
                    // Clear Field
                    _ToolbarButton(
                      icon: LucideIcons.trash2,
                      iconColor: Colors.redAccent,
                      onPressed: widget.onClearField,
                      tooltip: 'Clear Field',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle button for field controls
class _FieldControlsToggleButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _FieldControlsToggleButton({required this.onPressed});

  @override
  State<_FieldControlsToggleButton> createState() =>
      _FieldControlsToggleButtonState();
}

class _FieldControlsToggleButtonState extends State<_FieldControlsToggleButton>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _rotationController;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _rotationController.forward();
    } else {
      _rotationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open Field Controls',
      child: MouseRegion(
        onEnter: (_) => _onHoverChanged(true),
        onExit: (_) => _onHoverChanged(false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isHovered ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _isHovered ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 150),
                    builder: (context, value, child) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 0.7),
                            value,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: value > 0.5
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.4 * value,
                                    ),
                                    blurRadius: 12 * value,
                                    spreadRadius: 2 * value,
                                  ),
                                ]
                              : null,
                        ),
                        child: child,
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * math.pi * 0.5,
                          child: child,
                        );
                      },
                      child: const Icon(
                        LucideIcons.settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Orientation button widget
class _OrientationButton extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;
  final String tooltip;

  const _OrientationButton({
    required this.icon,
    required this.isSelected,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  State<_OrientationButton> createState() => _OrientationButtonState();
}

class _OrientationButtonState extends State<_OrientationButton> {
  bool _isHovered = false;

  // Accent color
  static const Color _accentColor = Color(0xFFFDD329);

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isSelected
        ? _accentColor.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.05);
    final hoverColor = widget.isSelected
        ? _accentColor.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.1);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _isHovered ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 150),
            builder: (context, value, child) {
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color.lerp(baseColor, hoverColor, value),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: child,
              );
            },
            child: Center(
              child: Icon(
                widget.icon,
                size: 20,
                color: widget.isSelected ? _accentColor : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Toolbar button widget
class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? iconColor;
  final bool isSelected;

  const _ToolbarButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.iconColor,
    this.isSelected = false,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isHovered = false;

  // Accent color
  static const Color _accentColor = Color(0xFFFDD329);

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isSelected
        ? _accentColor.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.05);
    final hoverColor = widget.isSelected
        ? _accentColor.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.1);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _isHovered ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 150),
            builder: (context, value, child) {
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color.lerp(baseColor, hoverColor, value),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: child,
              );
            },
            child: Center(
              child: Icon(
                widget.icon,
                size: 20,
                color: widget.isSelected
                    ? _accentColor
                    : widget.iconColor ?? Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dropdown item with hover effect matching _ToolbarButton style
class _DropdownItem extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;
  final double width;

  const _DropdownItem({
    required this.isSelected,
    required this.onTap,
    required this.child,
    this.width = 90,
  });

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _isHovered = false;
  static const _accent = Color(0xFFFDD329);

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isSelected
        ? _accent.withValues(alpha: 0.2)
        : Colors.transparent;
    final hoverColor = widget.isSelected
        ? _accent.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.08);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _isHovered ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 150),
          builder: (_, v, child) => Container(
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(baseColor, hoverColor, v),
              borderRadius: BorderRadius.circular(8),
            ),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Formation button with popup menu
class _FormationButton extends StatefulWidget {
  final String formation;
  final List<String> formations;
  final ValueChanged<String> onChanged;

  final bool openBelow;

  const _FormationButton({
    required this.formation,
    required this.formations,
    required this.onChanged,
    this.openBelow = false,
  });

  @override
  State<_FormationButton> createState() => _FormationButtonState();
}

class _FormationButtonState extends State<_FormationButton> {
  bool _isHovered = false;
  final GlobalKey _buttonKey = GlobalKey();

  // Accent color
  static const Color _accentColor = Color(0xFFFDD329);

  void _showFormationPicker() {
    final RenderBox button =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonPos = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;

    final formations = widget.formations;
    final halfLength = (formations.length / 2).ceil();
    final leftColumn = formations.sublist(0, halfLength);
    final rightColumn = formations.sublist(halfLength);

    // Calculate dropdown width (2 columns * 90 + spacing + padding)
    const dropdownWidth = 90.0 * 2 + 8 + 16; // columns + gap + padding

    // Center the dropdown relative to button
    final dropdownLeft =
        buttonPos.dx + (buttonSize.width / 2) - (dropdownWidth / 2);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: dropdownLeft,
            top: widget.openBelow ? buttonPos.dy + buttonSize.height + 8 : null,
            bottom: widget.openBelow
                ? null
                : overlay.size.height - buttonPos.dy + 8,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildColumn(ctx, leftColumn),
                    const SizedBox(width: 8),
                    _buildColumn(ctx, rightColumn),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(BuildContext ctx, List<String> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.map((f) {
        final isSelected = f == widget.formation;
        return _DropdownItem(
          isSelected: isSelected,
          onTap: () {
            widget.onChanged(f);
            Navigator.pop(ctx);
          },
          width: 90,
          child: Text(
            f,
            style: TextStyle(
              color: isSelected ? _accentColor : Colors.white,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: 2,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Formation: ${widget.formation.split('').join(' ')}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _showFormationPicker,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _isHovered ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 150),
            builder: (context, value, child) {
              return Container(
                key: _buttonKey,
                width: 75,
                height: 32,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.1),
                    value,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: child,
              );
            },
            child: Center(
              child: Text(
                widget.formation,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder button for drawing tools when DrawingLayer is not yet built
class DrawingToggleButtonPlaceholder extends StatefulWidget {
  final VoidCallback onPressed;

  const DrawingToggleButtonPlaceholder({super.key, required this.onPressed});

  @override
  State<DrawingToggleButtonPlaceholder> createState() =>
      _DrawingToggleButtonPlaceholderState();
}

class _DrawingToggleButtonPlaceholderState
    extends State<DrawingToggleButtonPlaceholder>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open Drawing Tools',
      child: MouseRegion(
        onEnter: (_) => _onHoverChanged(true),
        onExit: (_) => _onHoverChanged(false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isHovered ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: AnimatedBuilder(
                    animation: _hoverAnimation,
                    builder: (context, child) {
                      final value = _hoverAnimation.value;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 0.7),
                            value,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: value > 0.5
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.4 * value,
                                    ),
                                    blurRadius: 12 * value,
                                    spreadRadius: 2 * value,
                                  ),
                                ]
                              : null,
                        ),
                        child: child,
                      );
                    },
                    child: const Icon(
                      LucideIcons.pencilRuler,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle button for sidebar visibility
class SidebarToggleButton extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onPressed;

  const SidebarToggleButton({
    super.key,
    required this.isOpen,
    required this.onPressed,
  });

  @override
  State<SidebarToggleButton> createState() => _SidebarToggleButtonState();
}

class _SidebarToggleButtonState extends State<SidebarToggleButton>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );

    // Horizontal shake: 0 -> -4px -> 4px -> -3px -> 3px -> 0
    _shakeAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 4.0, end: -3.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -3.0, end: 3.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 1),
      ],
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.isOpen ? 'Hide Squad Panel' : 'Show Squad Panel',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _onHoverChanged(true),
        onExit: (_) => _onHoverChanged(false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isHovered && !widget.isOpen
                    ? _pulseAnimation.value
                    : 1.0,
                child: child,
              );
            },
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _isHovered ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 150),
                    builder: (context, value, child) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 0.7),
                            value,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: value > 0.5
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.4 * value,
                                    ),
                                    blurRadius: 12 * value,
                                    spreadRadius: 2 * value,
                                  ),
                                ]
                              : null,
                        ),
                        child: child,
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: Icon(
                        widget.isOpen
                            ? LucideIcons.panelRightClose
                            : LucideIcons.panelRightOpen,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Inline row of all field-control buttons — place this inside a header/app-bar.
/// All state lives in the parent; this widget is purely presentational.
class FieldControlsRow extends StatelessWidget {
  final bool isVertical;
  final bool isTransitioning;
  final Future<void> Function(bool) onOrientationChange;
  final double fieldScale;
  final ValueChanged<double> onScaleChange;
  final bool showSnapPoints;
  final VoidCallback onSnapPointsToggle;
  final bool magnetize;
  final VoidCallback onMagnetizeToggle;
  final String selectedFormation;
  final List<String> formations;
  final ValueChanged<String> onFormationChanged;
  final bool showPlayerNames;
  final VoidCallback onPlayerNamesToggle;
  final VoidCallback onClearField;
  final FieldStyle fieldStyle;
  final ValueChanged<FieldStyle> onFieldStyleChanged;

  const FieldControlsRow({
    super.key,
    required this.isVertical,
    required this.isTransitioning,
    required this.onOrientationChange,
    required this.fieldScale,
    required this.onScaleChange,
    required this.showSnapPoints,
    required this.onSnapPointsToggle,
    required this.magnetize,
    required this.onMagnetizeToggle,
    required this.selectedFormation,
    required this.formations,
    required this.onFormationChanged,
    required this.showPlayerNames,
    required this.onPlayerNamesToggle,
    required this.onClearField,
    required this.fieldStyle,
    required this.onFieldStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Orientation — single toggle button
        _ToolbarButton(
          icon: LucideIcons.refreshCcw,
          onPressed: () {
            if (!isTransitioning) onOrientationChange(!isVertical);
          },
          tooltip: isVertical ? 'Switch to Horizontal' : 'Switch to Vertical',
        ),
        const SizedBox(width: 8),
        // Field style picker
        _FieldStyleButton(
          fieldStyle: fieldStyle,
          onChanged: onFieldStyleChanged,
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 24, color: Colors.white24),
        const SizedBox(width: 8),
        // Scale
        _ToolbarButton(
          icon: LucideIcons.minus,
          onPressed: () =>
              onScaleChange(((fieldScale * 10 - 1) / 10).clamp(0.5, 1.0)),
          tooltip: 'Zoom Out',
        ),
        const SizedBox(width: 8),
        _ToolbarButton(
          icon: LucideIcons.plus,
          onPressed: () =>
              onScaleChange(((fieldScale * 10 + 1) / 10).clamp(0.5, 1.0)),
          tooltip: 'Zoom In',
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 24, color: Colors.white24),
        const SizedBox(width: 8),
        // Snap points
        _ToolbarButton(
          icon: LucideIcons.grid3x3,
          isSelected: showSnapPoints,
          onPressed: onSnapPointsToggle,
          tooltip: showSnapPoints ? 'Hide Snap Points' : 'Show Snap Points',
        ),
        const SizedBox(width: 8),
        // Magnetize
        _ToolbarButton(
          icon: LucideIcons.magnet,
          isSelected: magnetize,
          onPressed: onMagnetizeToggle,
          tooltip: magnetize ? 'Disable Magnetize' : 'Enable Magnetize',
        ),
        const SizedBox(width: 8),
        // Formation picker (opens dropdown below because it's in the header)
        _FormationButton(
          formation: selectedFormation,
          formations: formations,
          onChanged: onFormationChanged,
          openBelow: true,
        ),
        const SizedBox(width: 8),
        // Player names
        _ToolbarButton(
          icon: LucideIcons.tag,
          isSelected: showPlayerNames,
          onPressed: onPlayerNamesToggle,
          tooltip: showPlayerNames ? 'Hide Names' : 'Show Names',
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 24, color: Colors.white24),
        const SizedBox(width: 8),
        // Clear field
        _ToolbarButton(
          icon: LucideIcons.trash2,
          iconColor: Colors.redAccent,
          onPressed: onClearField,
          tooltip: 'Clear Field',
        ),
      ],
    );
  }
}

class _FieldStyleButton extends StatefulWidget {
  final FieldStyle fieldStyle;
  final ValueChanged<FieldStyle> onChanged;

  const _FieldStyleButton({required this.fieldStyle, required this.onChanged});

  @override
  State<_FieldStyleButton> createState() => _FieldStyleButtonState();
}

class _FieldStyleButtonState extends State<_FieldStyleButton> {
  bool _isHovered = false;
  final GlobalKey _buttonKey = GlobalKey();

  static final _styles = [
    (style: FieldStyle.classic, label: 'Classic', icon: LucideIcons.leaf),
    (style: FieldStyle.dark, label: 'Dark', icon: LucideIcons.moon),
    (style: FieldStyle.blueprint, label: 'Blueprint', icon: LucideIcons.ruler),
  ];

  static const _accent = Color(0xFFFDD329);

  void _showStylePicker() {
    final RenderBox button =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonPos = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;

    const dropdownWidth = 160.0;
    final dropdownLeft =
        buttonPos.dx + (buttonSize.width / 2) - (dropdownWidth / 2);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: dropdownLeft,
            top: buttonPos.dy + buttonSize.height + 8,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: dropdownWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _styles.map((s) {
                    final isSelected = s.style == widget.fieldStyle;
                    return _DropdownItem(
                      isSelected: isSelected,
                      width: dropdownWidth - 16,
                      onTap: () {
                        widget.onChanged(s.style);
                        Navigator.pop(ctx);
                      },
                      child: Row(
                        children: [
                          Icon(
                            s.icon,
                            size: 14,
                            color: isSelected ? _accent : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.label,
                            style: TextStyle(
                              color: isSelected ? _accent : Colors.white,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          if (isSelected) ...[
                            const Spacer(),
                            const Icon(
                              LucideIcons.check,
                              size: 12,
                              color: _accent,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _styles.firstWhere((s) => s.style == widget.fieldStyle);
    return Tooltip(
      message: 'Field style',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _showStylePicker,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _isHovered ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 150),
            builder: (_, v, child) => Container(
              key: _buttonKey,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Color.lerp(
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.1),
                  v,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: child,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(current.icon, size: 16, color: _accent),
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronDown, size: 12, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
