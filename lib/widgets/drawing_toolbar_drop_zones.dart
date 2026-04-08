import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'drawing_layer.dart';

/// Overlay that shows drop zone highlights (bottom / left) while the
/// drawing toolbar is being dragged around the field.
class DrawingToolbarDropZones extends StatelessWidget {
  const DrawingToolbarDropZones({
    super.key,
    required this.isDraggingNotifier,
    required this.dragPosNotifier,
    required this.sideResolver,
  });

  final ValueNotifier<bool> isDraggingNotifier;
  final ValueNotifier<Offset> dragPosNotifier;

  /// Returns which [ToolbarSide] the current drag position corresponds to.
  final ToolbarSide Function(Offset globalPos) sideResolver;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDraggingNotifier,
      builder: (_, isDragging, _) {
        if (!isDragging) return const SizedBox.shrink();
        return ValueListenableBuilder<Offset>(
          valueListenable: dragPosNotifier,
          builder: (_, dragPos, _) {
            final side = sideResolver(dragPos);
            return Stack(
              children: [
                // Bottom drop zone
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 72,
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: side == ToolbarSide.bottom
                            ? Colors.blue.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.04),
                        border: Border(
                          top: BorderSide(
                            color: side == ToolbarSide.bottom
                                ? Colors.blue.withValues(alpha: 0.6)
                                : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.alignEndHorizontal,
                          color: Colors.white30,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                // Left drop zone
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: 72,
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: side == ToolbarSide.left
                            ? Colors.blue.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.04),
                        border: Border(
                          right: BorderSide(
                            color: side == ToolbarSide.left
                                ? Colors.blue.withValues(alpha: 0.6)
                                : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.alignStartVertical,
                          color: Colors.white30,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
