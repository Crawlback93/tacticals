import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../models/drawing_element.dart';

/// Base class for all drawing events
abstract class DrawingEvent extends Equatable {
  const DrawingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to set the current drawing tool
class SetDrawingTool extends DrawingEvent {
  final DrawingTool tool;

  const SetDrawingTool(this.tool);

  @override
  List<Object?> get props => [tool];
}

/// Event to set the current color
class SetDrawingColor extends DrawingEvent {
  final Color color;

  const SetDrawingColor(this.color);

  @override
  List<Object?> get props => [color];
}

/// Event to set the current stroke width
class SetStrokeWidth extends DrawingEvent {
  final double width;

  const SetStrokeWidth(this.width);

  @override
  List<Object?> get props => [width];
}

/// Event to set the current line style
class SetLineStyle extends DrawingEvent {
  final LineStyle style;

  const SetLineStyle(this.style);

  @override
  List<Object?> get props => [style];
}

/// Event to set the arrow head position
class SetArrowHead extends DrawingEvent {
  final ArrowHeadPosition position;

  const SetArrowHead(this.position);

  @override
  List<Object?> get props => [position];
}

/// Event to set the fill color
class SetFillColor extends DrawingEvent {
  final Color? color;

  const SetFillColor(this.color);

  @override
  List<Object?> get props => [color];
}

/// Event to set fill opacity
class SetFillOpacity extends DrawingEvent {
  final double opacity;

  const SetFillOpacity(this.opacity);

  @override
  List<Object?> get props => [opacity];
}

/// Event to add a new drawing element
class AddDrawingElement extends DrawingEvent {
  final DrawingElement element;

  const AddDrawingElement(this.element);

  @override
  List<Object?> get props => [element.id];
}

/// Event to update an existing drawing element
class UpdateDrawingElement extends DrawingEvent {
  final DrawingElement element;

  const UpdateDrawingElement(this.element);

  @override
  List<Object?> get props => [element.id];
}

/// Event to delete a drawing element
class DeleteDrawingElement extends DrawingEvent {
  final String elementId;

  const DeleteDrawingElement(this.elementId);

  @override
  List<Object?> get props => [elementId];
}

/// Event to select an element
class SelectDrawingElement extends DrawingEvent {
  final String? elementId;

  const SelectDrawingElement(this.elementId);

  @override
  List<Object?> get props => [elementId];
}

/// Event to undo last action
class UndoDrawing extends DrawingEvent {
  const UndoDrawing();
}

/// Event to redo last undone action
class RedoDrawing extends DrawingEvent {
  const RedoDrawing();
}

/// Event to clear all drawings
class ClearDrawing extends DrawingEvent {
  const ClearDrawing();
}

/// Event to bring element to front
class BringToFront extends DrawingEvent {
  final String elementId;

  const BringToFront(this.elementId);

  @override
  List<Object?> get props => [elementId];
}

/// Event to send element to back
class SendToBack extends DrawingEvent {
  final String elementId;

  const SendToBack(this.elementId);

  @override
  List<Object?> get props => [elementId];
}

/// Event to duplicate an element
class DuplicateElement extends DrawingEvent {
  final String elementId;

  const DuplicateElement(this.elementId);

  @override
  List<Object?> get props => [elementId];
}

/// Event to load elements from saved state
class LoadDrawingElements extends DrawingEvent {
  final List<DrawingElement> elements;

  const LoadDrawingElements(this.elements);

  @override
  List<Object?> get props => [elements.length];
}

/// Event to update selected element's color
class UpdateSelectedElementColor extends DrawingEvent {
  final Color color;

  const UpdateSelectedElementColor(this.color);

  @override
  List<Object?> get props => [color];
}
