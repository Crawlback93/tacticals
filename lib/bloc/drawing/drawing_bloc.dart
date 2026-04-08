import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../models/drawing_element.dart';
import 'drawing_event.dart';
import 'drawing_state.dart';

class DrawingBloc extends HydratedBloc<DrawingEvent, DrawingState> {
  DrawingBloc() : super(const DrawingState()) {
    on<SetDrawingTool>(_onSetDrawingTool);
    on<SetDrawingColor>(_onSetDrawingColor);
    on<SetStrokeWidth>(_onSetStrokeWidth);
    on<SetLineStyle>(_onSetLineStyle);
    on<SetArrowHead>(_onSetArrowHead);
    on<SetFillColor>(_onSetFillColor);
    on<SetFillOpacity>(_onSetFillOpacity);
    on<AddDrawingElement>(_onAddDrawingElement);
    on<UpdateDrawingElement>(_onUpdateDrawingElement);
    on<DeleteDrawingElement>(_onDeleteDrawingElement);
    on<SelectDrawingElement>(_onSelectDrawingElement);
    on<UndoDrawing>(_onUndoDrawing);
    on<RedoDrawing>(_onRedoDrawing);
    on<ClearDrawing>(_onClearDrawing);
    on<BringToFront>(_onBringToFront);
    on<SendToBack>(_onSendToBack);
    on<DuplicateElement>(_onDuplicateElement);
    on<LoadDrawingElements>(_onLoadDrawingElements);
    on<UpdateSelectedElementColor>(_onUpdateSelectedElementColor);
  }

  void _onSetDrawingTool(SetDrawingTool event, Emitter<DrawingState> emit) {
    emit(
      state.copyWith(
        currentTool: event.tool,
        clearSelection: true,
        status: DrawingStatus.ready,
      ),
    );
  }

  void _onSetDrawingColor(SetDrawingColor event, Emitter<DrawingState> emit) {
    emit(state.copyWith(currentColor: event.color));
  }

  void _onSetStrokeWidth(SetStrokeWidth event, Emitter<DrawingState> emit) {
    emit(state.copyWith(currentStrokeWidth: event.width));
  }

  void _onSetLineStyle(SetLineStyle event, Emitter<DrawingState> emit) {
    emit(state.copyWith(currentLineStyle: event.style));
  }

  void _onSetArrowHead(SetArrowHead event, Emitter<DrawingState> emit) {
    emit(state.copyWith(currentArrowHead: event.position));
  }

  void _onSetFillColor(SetFillColor event, Emitter<DrawingState> emit) {
    if (event.color == null) {
      emit(state.copyWith(clearFillColor: true));
    } else {
      emit(state.copyWith(currentFillColor: event.color));
    }
  }

  void _onSetFillOpacity(SetFillOpacity event, Emitter<DrawingState> emit) {
    emit(state.copyWith(currentFillOpacity: event.opacity));
  }

  void _onAddDrawingElement(
    AddDrawingElement event,
    Emitter<DrawingState> emit,
  ) {
    _saveToUndoStack(emit);
    final newElements = List<DrawingElement>.from(state.elements)
      ..add(event.element);
    emit(state.copyWith(elements: newElements, status: DrawingStatus.ready));
  }

  void _onUpdateDrawingElement(
    UpdateDrawingElement event,
    Emitter<DrawingState> emit,
  ) {
    final newElements = state.elements.map((e) {
      if (e.id == event.element.id) {
        return event.element;
      }
      return e;
    }).toList();
    emit(state.copyWith(elements: newElements, status: DrawingStatus.editing));
  }

  void _onDeleteDrawingElement(
    DeleteDrawingElement event,
    Emitter<DrawingState> emit,
  ) {
    _saveToUndoStack(emit);
    final newElements = state.elements
        .where((e) => e.id != event.elementId)
        .toList();
    emit(
      state.copyWith(
        elements: newElements,
        clearSelection: state.selectedElementId == event.elementId,
        status: DrawingStatus.ready,
      ),
    );
  }

  void _onSelectDrawingElement(
    SelectDrawingElement event,
    Emitter<DrawingState> emit,
  ) {
    // Update isSelected flag on all elements
    final newElements = state.elements.map((e) {
      final copy = e.copyWith();
      copy.isSelected = e.id == event.elementId;
      return copy;
    }).toList();

    emit(
      state.copyWith(
        elements: newElements,
        selectedElementId: event.elementId,
        clearSelection: event.elementId == null,
        status: DrawingStatus.ready,
      ),
    );
  }

  void _onUndoDrawing(UndoDrawing event, Emitter<DrawingState> emit) {
    if (!state.canUndo) return;

    final newUndoStack = List<List<Map<String, dynamic>>>.from(state.undoStack);
    final lastState = newUndoStack.removeLast();

    final newRedoStack = List<List<Map<String, dynamic>>>.from(state.redoStack)
      ..add(state.elements.map((e) => e.toJson()).toList());

    final restoredElements = lastState
        .map((e) => DrawingElement.fromJson(e))
        .toList();

    emit(
      state.copyWith(
        elements: restoredElements,
        undoStack: newUndoStack,
        redoStack: newRedoStack,
        clearSelection: true,
        status: DrawingStatus.ready,
      ),
    );
  }

  void _onRedoDrawing(RedoDrawing event, Emitter<DrawingState> emit) {
    if (!state.canRedo) return;

    final newRedoStack = List<List<Map<String, dynamic>>>.from(state.redoStack);
    final lastState = newRedoStack.removeLast();

    final newUndoStack = List<List<Map<String, dynamic>>>.from(state.undoStack)
      ..add(state.elements.map((e) => e.toJson()).toList());

    final restoredElements = lastState
        .map((e) => DrawingElement.fromJson(e))
        .toList();

    emit(
      state.copyWith(
        elements: restoredElements,
        undoStack: newUndoStack,
        redoStack: newRedoStack,
        clearSelection: true,
        status: DrawingStatus.ready,
      ),
    );
  }

  void _onClearDrawing(ClearDrawing event, Emitter<DrawingState> emit) {
    _saveToUndoStack(emit);
    emit(
      state.copyWith(
        elements: [],
        clearSelection: true,
        status: DrawingStatus.ready,
      ),
    );
  }

  void _onBringToFront(BringToFront event, Emitter<DrawingState> emit) {
    _saveToUndoStack(emit);
    final maxOrder = state.elements.fold<int>(
      0,
      (max, e) => e.layerOrder > max ? e.layerOrder : max,
    );

    final newElements = state.elements.map((e) {
      if (e.id == event.elementId) {
        final copy = e.copyWith();
        copy.layerOrder = maxOrder + 1;
        return copy;
      }
      return e;
    }).toList();

    emit(state.copyWith(elements: newElements));
  }

  void _onSendToBack(SendToBack event, Emitter<DrawingState> emit) {
    _saveToUndoStack(emit);
    final minOrder = state.elements.fold<int>(
      0,
      (min, e) => e.layerOrder < min ? e.layerOrder : min,
    );

    final newElements = state.elements.map((e) {
      if (e.id == event.elementId) {
        final copy = e.copyWith();
        copy.layerOrder = minOrder - 1;
        return copy;
      }
      return e;
    }).toList();

    emit(state.copyWith(elements: newElements));
  }

  void _onDuplicateElement(DuplicateElement event, Emitter<DrawingState> emit) {
    _saveToUndoStack(emit);
    final element = state.elements.firstWhere(
      (e) => e.id == event.elementId,
      orElse: () => throw Exception('Element not found'),
    );

    // Create a copy with a new ID and offset position
    DrawingElement duplicate;
    if (element is FreehandElement) {
      duplicate = FreehandElement(
        points: element.points
            .map((p) => Offset(p.dx + 20, p.dy + 20))
            .toList(),
        strokeColor: element.strokeColor,
        strokeWidth: element.strokeWidth,
        opacity: element.opacity,
        layerOrder: element.layerOrder + 1,
      );
    } else if (element is LineElement) {
      duplicate = LineElement(
        start: Offset(element.start.dx + 20, element.start.dy + 20),
        end: Offset(element.end.dx + 20, element.end.dy + 20),
        control1: element.control1 != null
            ? Offset(element.control1!.dx + 20, element.control1!.dy + 20)
            : null,
        control2: element.control2 != null
            ? Offset(element.control2!.dx + 20, element.control2!.dy + 20)
            : null,
        strokeColor: element.strokeColor,
        strokeWidth: element.strokeWidth,
        lineStyle: element.lineStyle,
        layerOrder: element.layerOrder + 1,
      );
    } else if (element is ArrowElement) {
      duplicate = ArrowElement(
        start: Offset(element.start.dx + 20, element.start.dy + 20),
        end: Offset(element.end.dx + 20, element.end.dy + 20),
        control1: element.control1 != null
            ? Offset(element.control1!.dx + 20, element.control1!.dy + 20)
            : null,
        control2: element.control2 != null
            ? Offset(element.control2!.dx + 20, element.control2!.dy + 20)
            : null,
        strokeColor: element.strokeColor,
        strokeWidth: element.strokeWidth,
        lineStyle: element.lineStyle,
        arrowHead: element.arrowHead,
        arrowSize: element.arrowSize,
        layerOrder: element.layerOrder + 1,
      );
    } else if (element is RectangleElement) {
      duplicate = RectangleElement(
        rect: element.rect.translate(20, 20),
        strokeColor: element.strokeColor,
        strokeWidth: element.strokeWidth,
        fillColor: element.fillColor,
        fillOpacity: element.fillOpacity,
        rotation: element.rotation,
        layerOrder: element.layerOrder + 1,
      );
    } else if (element is EllipseElement) {
      duplicate = EllipseElement(
        rect: element.rect.translate(20, 20),
        strokeColor: element.strokeColor,
        strokeWidth: element.strokeWidth,
        fillColor: element.fillColor,
        fillOpacity: element.fillOpacity,
        layerOrder: element.layerOrder + 1,
      );
    } else if (element is PolygonElement) {
      duplicate = PolygonElement(
        points: element.points
            .map((p) => Offset(p.dx + 20, p.dy + 20))
            .toList(),
        strokeColor: element.strokeColor,
        strokeWidth: element.strokeWidth,
        fillColor: element.fillColor,
        fillOpacity: element.fillOpacity,
        isClosed: element.isClosed,
        layerOrder: element.layerOrder + 1,
      );
    } else if (element is TextElement) {
      duplicate = TextElement(
        position: Offset(element.position.dx + 20, element.position.dy + 20),
        text: element.text,
        textColor: element.textColor,
        fontSize: element.fontSize,
        fontWeight: element.fontWeight,
        hasBackground: element.hasBackground,
        backgroundColor: element.backgroundColor,
        layerOrder: element.layerOrder + 1,
      );
    } else if (element is EquipmentElement) {
      duplicate = EquipmentElement(
        position: Offset(element.position.dx + 20, element.position.dy + 20),
        equipmentType: element.equipmentType,
        color: element.color,
        size: element.size,
        rotation: element.rotation,
        layerOrder: element.layerOrder + 1,
      );
    } else {
      return;
    }

    final newElements = List<DrawingElement>.from(state.elements)
      ..add(duplicate);
    emit(
      state.copyWith(elements: newElements, selectedElementId: duplicate.id),
    );
  }

  void _onLoadDrawingElements(
    LoadDrawingElements event,
    Emitter<DrawingState> emit,
  ) {
    emit(state.copyWith(elements: event.elements, status: DrawingStatus.ready));
  }

  void _onUpdateSelectedElementColor(
    UpdateSelectedElementColor event,
    Emitter<DrawingState> emit,
  ) {
    if (state.selectedElementId == null) return;

    final newElements = state.elements.map((e) {
      if (e.id == state.selectedElementId) {
        if (e is FreehandElement) {
          return FreehandElement(
            id: e.id,
            layerOrder: e.layerOrder,
            isSelected: e.isSelected,
            points: e.points,
            strokeColor: event.color,
            strokeWidth: e.strokeWidth,
            opacity: e.opacity,
          );
        } else if (e is LineElement) {
          return LineElement(
            id: e.id,
            layerOrder: e.layerOrder,
            isSelected: e.isSelected,
            start: e.start,
            end: e.end,
            control1: e.control1,
            control2: e.control2,
            strokeColor: event.color,
            strokeWidth: e.strokeWidth,
            lineStyle: e.lineStyle,
          );
        } else if (e is ArrowElement) {
          return ArrowElement(
            id: e.id,
            layerOrder: e.layerOrder,
            isSelected: e.isSelected,
            start: e.start,
            end: e.end,
            control1: e.control1,
            control2: e.control2,
            strokeColor: event.color,
            strokeWidth: e.strokeWidth,
            lineStyle: e.lineStyle,
            arrowHead: e.arrowHead,
            arrowSize: e.arrowSize,
          );
        } else if (e is RectangleElement) {
          return RectangleElement(
            id: e.id,
            layerOrder: e.layerOrder,
            isSelected: e.isSelected,
            rect: e.rect,
            strokeColor: event.color,
            strokeWidth: e.strokeWidth,
            fillColor: e.fillColor,
            fillOpacity: e.fillOpacity,
            rotation: e.rotation,
          );
        } else if (e is EllipseElement) {
          return EllipseElement(
            id: e.id,
            layerOrder: e.layerOrder,
            isSelected: e.isSelected,
            rect: e.rect,
            strokeColor: event.color,
            strokeWidth: e.strokeWidth,
            fillColor: e.fillColor,
            fillOpacity: e.fillOpacity,
          );
        } else if (e is PolygonElement) {
          return PolygonElement(
            id: e.id,
            layerOrder: e.layerOrder,
            isSelected: e.isSelected,
            points: e.points,
            strokeColor: event.color,
            strokeWidth: e.strokeWidth,
            fillColor: e.fillColor,
            fillOpacity: e.fillOpacity,
            isClosed: e.isClosed,
          );
        } else if (e is TextElement) {
          return TextElement(
            id: e.id,
            layerOrder: e.layerOrder,
            isSelected: e.isSelected,
            position: e.position,
            text: e.text,
            textColor: event.color,
            fontSize: e.fontSize,
            fontWeight: e.fontWeight,
            hasBackground: e.hasBackground,
            backgroundColor: e.backgroundColor,
          );
        } else if (e is EquipmentElement) {
          return EquipmentElement(
            id: e.id,
            layerOrder: e.layerOrder,
            isSelected: e.isSelected,
            position: e.position,
            equipmentType: e.equipmentType,
            color: event.color,
            size: e.size,
            rotation: e.rotation,
          );
        }
      }
      return e;
    }).toList();

    emit(state.copyWith(elements: newElements, currentColor: event.color));
  }

  void _saveToUndoStack(Emitter<DrawingState> emit) {
    final newUndoStack = List<List<Map<String, dynamic>>>.from(state.undoStack)
      ..add(state.elements.map((e) => e.toJson()).toList());

    // Limit undo stack to 50 items
    if (newUndoStack.length > 50) {
      newUndoStack.removeAt(0);
    }

    emit(
      state.copyWith(
        undoStack: newUndoStack,
        redoStack: [], // Clear redo stack on new action
      ),
    );
  }

  @override
  DrawingState? fromJson(Map<String, dynamic> json) {
    try {
      return DrawingState.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(DrawingState state) {
    try {
      return state.toJson();
    } catch (e) {
      return null;
    }
  }
}
