import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../models/drawing_element.dart';

/// Status of the drawing state
enum DrawingStatus { initial, ready, drawing, editing }

/// State for the drawing BLoC
class DrawingState extends Equatable {
  final DrawingStatus status;
  final List<DrawingElement> elements;
  final String? selectedElementId;
  final DrawingTool currentTool;
  final Color currentColor;
  final double currentStrokeWidth;
  final LineStyle currentLineStyle;
  final ArrowHeadPosition currentArrowHead;
  final Color? currentFillColor;
  final double currentFillOpacity;

  // Undo/Redo stacks (stored as JSON for serialization)
  final List<List<Map<String, dynamic>>> undoStack;
  final List<List<Map<String, dynamic>>> redoStack;

  const DrawingState({
    this.status = DrawingStatus.initial,
    this.elements = const [],
    this.selectedElementId,
    this.currentTool = DrawingTool.select,
    this.currentColor = Colors.red,
    this.currentStrokeWidth = 3.0,
    this.currentLineStyle = LineStyle.solid,
    this.currentArrowHead = ArrowHeadPosition.end,
    this.currentFillColor,
    this.currentFillOpacity = 0.3,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  /// Get the currently selected element
  DrawingElement? get selectedElement {
    if (selectedElementId == null) return null;
    try {
      return elements.firstWhere((e) => e.id == selectedElementId);
    } catch (_) {
      return null;
    }
  }

  /// Check if undo is available
  bool get canUndo => undoStack.isNotEmpty;

  /// Check if redo is available
  bool get canRedo => redoStack.isNotEmpty;

  DrawingState copyWith({
    DrawingStatus? status,
    List<DrawingElement>? elements,
    String? selectedElementId,
    bool clearSelection = false,
    DrawingTool? currentTool,
    Color? currentColor,
    double? currentStrokeWidth,
    LineStyle? currentLineStyle,
    ArrowHeadPosition? currentArrowHead,
    Color? currentFillColor,
    bool clearFillColor = false,
    double? currentFillOpacity,
    List<List<Map<String, dynamic>>>? undoStack,
    List<List<Map<String, dynamic>>>? redoStack,
  }) {
    return DrawingState(
      status: status ?? this.status,
      elements: elements ?? this.elements,
      selectedElementId: clearSelection
          ? null
          : (selectedElementId ?? this.selectedElementId),
      currentTool: currentTool ?? this.currentTool,
      currentColor: currentColor ?? this.currentColor,
      currentStrokeWidth: currentStrokeWidth ?? this.currentStrokeWidth,
      currentLineStyle: currentLineStyle ?? this.currentLineStyle,
      currentArrowHead: currentArrowHead ?? this.currentArrowHead,
      currentFillColor: clearFillColor
          ? null
          : (currentFillColor ?? this.currentFillColor),
      currentFillOpacity: currentFillOpacity ?? this.currentFillOpacity,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }

  /// Convert state to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'elements': elements.map((e) => e.toJson()).toList(),
      'selectedElementId': selectedElementId,
      'currentTool': currentTool.name,
      'currentColor': currentColor.toARGB32(),
      'currentStrokeWidth': currentStrokeWidth,
      'currentLineStyle': currentLineStyle.name,
      'currentArrowHead': currentArrowHead.name,
      'currentFillColor': currentFillColor?.toARGB32(),
      'currentFillOpacity': currentFillOpacity,
      'undoStack': undoStack,
      'redoStack': redoStack,
    };
  }

  /// Create state from JSON
  factory DrawingState.fromJson(Map<String, dynamic> json) {
    return DrawingState(
      status: DrawingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DrawingStatus.ready,
      ),
      elements:
          (json['elements'] as List?)
              ?.map((e) => DrawingElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      selectedElementId: json['selectedElementId'] as String?,
      currentTool: DrawingTool.values.firstWhere(
        (e) => e.name == json['currentTool'],
        orElse: () => DrawingTool.select,
      ),
      currentColor: Color(
        json['currentColor'] as int? ?? Colors.red.toARGB32(),
      ),
      currentStrokeWidth:
          (json['currentStrokeWidth'] as num?)?.toDouble() ?? 3.0,
      currentLineStyle: LineStyle.values.firstWhere(
        (e) => e.name == json['currentLineStyle'],
        orElse: () => LineStyle.solid,
      ),
      currentArrowHead: ArrowHeadPosition.values.firstWhere(
        (e) => e.name == json['currentArrowHead'],
        orElse: () => ArrowHeadPosition.end,
      ),
      currentFillColor: json['currentFillColor'] != null
          ? Color(json['currentFillColor'] as int)
          : null,
      currentFillOpacity:
          (json['currentFillOpacity'] as num?)?.toDouble() ?? 0.3,
      undoStack:
          (json['undoStack'] as List?)
              ?.map(
                (stack) => (stack as List)
                    .map((e) => e as Map<String, dynamic>)
                    .toList(),
              )
              .toList() ??
          [],
      redoStack:
          (json['redoStack'] as List?)
              ?.map(
                (stack) => (stack as List)
                    .map((e) => e as Map<String, dynamic>)
                    .toList(),
              )
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    status,
    elements,
    selectedElementId,
    currentTool,
    currentColor,
    currentStrokeWidth,
    currentLineStyle,
    currentArrowHead,
    currentFillColor,
    currentFillOpacity,
    undoStack,
    redoStack,
  ];
}
