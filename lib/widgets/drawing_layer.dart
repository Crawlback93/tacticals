import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Enum for drawing tool types
enum DrawingTool {
  select,
  freehand,
  line,
  arrow,
  rectangle,
  ellipse,
  spot,
  text,
  cone,
  pole,
  mannequin,
  miniGoal,
}

/// Enum for line styles
enum LineStyle { solid, dashed, dotted }

/// Which side the drawing toolbar is docked to
enum ToolbarSide { bottom, left }

/// Enum for arrow head positions
enum ArrowHeadPosition { none, start, end, both }

/// Enum for handle types (for dragging control points and resize)
enum HandleType {
  none,
  // For lines/arrows
  start,
  end,
  control1,
  control2,
  // For resize (corners)
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  // For resize (midpoints)
  topCenter,
  bottomCenter,
  leftCenter,
  rightCenter,
}

/// Base class for all drawing elements
abstract class DrawingElement {
  final String id;
  int layerOrder;
  bool isSelected;

  DrawingElement({String? id, this.layerOrder = 0, this.isSelected = false})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson();

  Rect get boundingBox;

  /// Tight rect used for the selection frame (no hit-test padding).
  Rect get visualBounds => boundingBox;

  bool containsPoint(Offset point);

  DrawingElement copyWith();
}

/// Freehand drawing element
class FreehandElement extends DrawingElement {
  List<Offset> points;
  Color strokeColor;
  double strokeWidth;
  double opacity;

  FreehandElement({
    super.id,
    super.layerOrder,
    super.isSelected,
    required this.points,
    this.strokeColor = Colors.red,
    this.strokeWidth = 3.0,
    this.opacity = 1.0,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'freehand',
    'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    'strokeColor': strokeColor.toHex(),
    'strokeWidth': strokeWidth,
    'opacity': opacity,
    'layerOrder': layerOrder,
  };

  Rect _pointsBounds() {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.dx, maxX = points.first.dx;
    double minY = points.first.dy, maxY = points.first.dy;
    for (var p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  Rect get visualBounds => _pointsBounds().inflate(strokeWidth / 2);

  @override
  Rect get boundingBox => _pointsBounds().inflate(strokeWidth / 2 + 8);

  @override
  bool containsPoint(Offset point) => boundingBox.contains(point);

  @override
  FreehandElement copyWith() => FreehandElement(
    id: id,
    layerOrder: layerOrder,
    isSelected: isSelected,
    points: List.from(points),
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
    opacity: opacity,
  );
}

/// Line element (straight line with control points)
class LineElement extends DrawingElement {
  Offset start;
  Offset end;
  Offset? control1; // First control point (between start and end)
  Offset? control2; // Second control point (between start and end)
  Color strokeColor;
  double strokeWidth;
  LineStyle lineStyle;

  LineElement({
    super.id,
    super.layerOrder,
    super.isSelected,
    required this.start,
    required this.end,
    this.control1,
    this.control2,
    this.strokeColor = Colors.red,
    this.strokeWidth = 3.0,
    this.lineStyle = LineStyle.solid,
  });

  /// Initialize control points at 1/3 and 2/3 of the line
  void initControlPoints() {
    control1 = Offset(
      start.dx + (end.dx - start.dx) / 3,
      start.dy + (end.dy - start.dy) / 3,
    );
    control2 = Offset(
      start.dx + (end.dx - start.dx) * 2 / 3,
      start.dy + (end.dy - start.dy) * 2 / 3,
    );
  }

  /// Get all 4 handle positions
  List<Offset> get handlePositions => [
    start,
    control1 ??
        Offset(
          start.dx + (end.dx - start.dx) / 3,
          start.dy + (end.dy - start.dy) / 3,
        ),
    control2 ??
        Offset(
          start.dx + (end.dx - start.dx) * 2 / 3,
          start.dy + (end.dy - start.dy) * 2 / 3,
        ),
    end,
  ];

  /// Check which handle is at the given position
  HandleType hitTestHandle(Offset point, {double tolerance = 12.0}) {
    final handles = handlePositions;
    if ((handles[0] - point).distance < tolerance) return HandleType.start;
    if ((handles[1] - point).distance < tolerance) return HandleType.control1;
    if ((handles[2] - point).distance < tolerance) return HandleType.control2;
    if ((handles[3] - point).distance < tolerance) return HandleType.end;
    return HandleType.none;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'line',
    'start': {'dx': start.dx, 'dy': start.dy},
    'end': {'dx': end.dx, 'dy': end.dy},
    'control1': control1 != null
        ? {'dx': control1!.dx, 'dy': control1!.dy}
        : null,
    'control2': control2 != null
        ? {'dx': control2!.dx, 'dy': control2!.dy}
        : null,
    'strokeColor': strokeColor.toHex(),
    'strokeWidth': strokeWidth,
    'lineStyle': lineStyle.name,
    'layerOrder': layerOrder,
  };

  Rect _handleBounds() {
    final pts = handlePositions;
    double minX = pts[0].dx, maxX = pts[0].dx;
    double minY = pts[0].dy, maxY = pts[0].dy;
    for (var p in pts) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  Rect get visualBounds => _handleBounds().inflate(strokeWidth / 2);

  @override
  Rect get boundingBox => _handleBounds().inflate(strokeWidth / 2 + 8);

  @override
  bool containsPoint(Offset point) => boundingBox.contains(point);

  @override
  LineElement copyWith() => LineElement(
    id: id,
    layerOrder: layerOrder,
    isSelected: isSelected,
    start: start,
    end: end,
    control1: control1,
    control2: control2,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
    lineStyle: lineStyle,
  );
}

/// Arrow element with control points
class ArrowElement extends DrawingElement {
  Offset start;
  Offset end;
  Offset? control1;
  Offset? control2;
  Color strokeColor;
  double strokeWidth;
  LineStyle lineStyle;
  ArrowHeadPosition arrowHead;
  double arrowSize;

  ArrowElement({
    super.id,
    super.layerOrder,
    super.isSelected,
    required this.start,
    required this.end,
    this.control1,
    this.control2,
    this.strokeColor = Colors.red,
    this.strokeWidth = 3.0,
    this.lineStyle = LineStyle.solid,
    this.arrowHead = ArrowHeadPosition.end,
    this.arrowSize = 12.0,
  });

  /// Initialize control points at 1/3 and 2/3 of the line
  void initControlPoints() {
    control1 = Offset(
      start.dx + (end.dx - start.dx) / 3,
      start.dy + (end.dy - start.dy) / 3,
    );
    control2 = Offset(
      start.dx + (end.dx - start.dx) * 2 / 3,
      start.dy + (end.dy - start.dy) * 2 / 3,
    );
  }

  /// Get all 4 handle positions
  List<Offset> get handlePositions => [
    start,
    control1 ??
        Offset(
          start.dx + (end.dx - start.dx) / 3,
          start.dy + (end.dy - start.dy) / 3,
        ),
    control2 ??
        Offset(
          start.dx + (end.dx - start.dx) * 2 / 3,
          start.dy + (end.dy - start.dy) * 2 / 3,
        ),
    end,
  ];

  /// Check which handle is at the given position
  HandleType hitTestHandle(Offset point, {double tolerance = 12.0}) {
    final handles = handlePositions;
    if ((handles[0] - point).distance < tolerance) return HandleType.start;
    if ((handles[1] - point).distance < tolerance) return HandleType.control1;
    if ((handles[2] - point).distance < tolerance) return HandleType.control2;
    if ((handles[3] - point).distance < tolerance) return HandleType.end;
    return HandleType.none;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'arrow',
    'start': {'dx': start.dx, 'dy': start.dy},
    'end': {'dx': end.dx, 'dy': end.dy},
    'control1': control1 != null
        ? {'dx': control1!.dx, 'dy': control1!.dy}
        : null,
    'control2': control2 != null
        ? {'dx': control2!.dx, 'dy': control2!.dy}
        : null,
    'strokeColor': strokeColor.toHex(),
    'strokeWidth': strokeWidth,
    'lineStyle': lineStyle.name,
    'arrowHead': arrowHead.name,
    'arrowSize': arrowSize,
    'layerOrder': layerOrder,
  };

  Rect _handleBounds() {
    final pts = handlePositions;
    double minX = pts[0].dx, maxX = pts[0].dx;
    double minY = pts[0].dy, maxY = pts[0].dy;
    for (var p in pts) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  Rect get visualBounds => _handleBounds().inflate(arrowSize / 2 + strokeWidth / 2);

  @override
  Rect get boundingBox {
    return _handleBounds().inflate(arrowSize + 10);
  }

  @override
  bool containsPoint(Offset point) {
    // Simple bounding box check for easy selection
    return boundingBox.contains(point);
  }

  @override
  ArrowElement copyWith() => ArrowElement(
    id: id,
    layerOrder: layerOrder,
    isSelected: isSelected,
    start: start,
    end: end,
    control1: control1,
    control2: control2,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
    lineStyle: lineStyle,
    arrowHead: arrowHead,
    arrowSize: arrowSize,
  );
}

/// Rectangle element
class RectangleElement extends DrawingElement {
  Rect rect;
  Color strokeColor;
  double strokeWidth;
  Color? fillColor;
  double fillOpacity;
  double rotation;

  RectangleElement({
    super.id,
    super.layerOrder,
    super.isSelected,
    required this.rect,
    this.strokeColor = Colors.red,
    this.strokeWidth = 2.0,
    this.fillColor,
    this.fillOpacity = 0.3,
    this.rotation = 0.0,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'rectangle',
    'rect': {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    },
    'strokeColor': strokeColor.toHex(),
    'strokeWidth': strokeWidth,
    'fillColor': fillColor?.toHex(),
    'fillOpacity': fillOpacity,
    'rotation': rotation,
    'layerOrder': layerOrder,
  };

  @override
  Rect get visualBounds => rect.inflate(strokeWidth / 2);

  @override
  Rect get boundingBox => rect.inflate(strokeWidth / 2 + 8);

  @override
  bool containsPoint(Offset point) => boundingBox.contains(point);

  @override
  RectangleElement copyWith() => RectangleElement(
    id: id,
    layerOrder: layerOrder,
    isSelected: isSelected,
    rect: rect,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
    fillColor: fillColor,
    fillOpacity: fillOpacity,
    rotation: rotation,
  );
}

/// Ellipse element
class EllipseElement extends DrawingElement {
  Rect rect;
  Color strokeColor;
  double strokeWidth;
  Color? fillColor;
  double fillOpacity;

  EllipseElement({
    super.id,
    super.layerOrder,
    super.isSelected,
    required this.rect,
    this.strokeColor = Colors.red,
    this.strokeWidth = 2.0,
    this.fillColor,
    this.fillOpacity = 0.3,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'ellipse',
    'rect': {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    },
    'strokeColor': strokeColor.toHex(),
    'strokeWidth': strokeWidth,
    'fillColor': fillColor?.toHex(),
    'fillOpacity': fillOpacity,
    'layerOrder': layerOrder,
  };

  @override
  Rect get visualBounds => rect.inflate(strokeWidth / 2);

  @override
  Rect get boundingBox => rect.inflate(strokeWidth / 2 + 8);

  @override
  bool containsPoint(Offset point) => boundingBox.contains(point);

  @override
  EllipseElement copyWith() => EllipseElement(
    id: id,
    layerOrder: layerOrder,
    isSelected: isSelected,
    rect: rect,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
    fillColor: fillColor,
    fillOpacity: fillOpacity,
  );
}

/// Spot element - a freehand drawn filled shape (blob/splat)
class SpotElement extends DrawingElement {
  List<Offset> points;
  Color fillColor;
  double fillOpacity;
  Color strokeColor;
  double strokeWidth;

  SpotElement({
    super.id,
    super.layerOrder,
    super.isSelected,
    required this.points,
    this.fillColor = Colors.red,
    this.fillOpacity = 0.5,
    this.strokeColor = Colors.red,
    this.strokeWidth = 2.0,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'spot',
    'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    'fillColor': fillColor.toHex(),
    'fillOpacity': fillOpacity,
    'strokeColor': strokeColor.toHex(),
    'strokeWidth': strokeWidth,
    'layerOrder': layerOrder,
  };

  @override
  Rect get boundingBox {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.dx, maxX = points.first.dx;
    double minY = points.first.dy, maxY = points.first.dy;
    for (var p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(strokeWidth / 2 + 8);
  }

  @override
  Rect get visualBounds {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.dx, maxX = points.first.dx;
    double minY = points.first.dy, maxY = points.first.dy;
    for (var p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(strokeWidth / 2);
  }

  @override
  bool containsPoint(Offset point) => boundingBox.contains(point);

  @override
  SpotElement copyWith() => SpotElement(
    id: id,
    layerOrder: layerOrder,
    isSelected: isSelected,
    points: List.from(points),
    fillColor: fillColor,
    fillOpacity: fillOpacity,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
  );
}

/// Text element
class TextElement extends DrawingElement {
  Offset position;
  String text;
  Color textColor;
  double fontSize;
  FontWeight fontWeight;
  bool hasBackground;
  Color? backgroundColor;

  TextElement({
    super.id,
    super.layerOrder,
    super.isSelected,
    required this.position,
    required this.text,
    this.textColor = Colors.white,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.bold,
    this.hasBackground = true,
    this.backgroundColor,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'text',
    'position': {'dx': position.dx, 'dy': position.dy},
    'text': text,
    'textColor': textColor.toHex(),
    'fontSize': fontSize,
    'fontWeight': fontWeight.index,
    'hasBackground': hasBackground,
    'backgroundColor': backgroundColor?.toHex(),
    'layerOrder': layerOrder,
  };

  /// Measures the actual rendered size using TextPainter.
  Size measureSize() {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Raleway',
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.size;
  }

  @override
  Rect get visualBounds {
    final s = measureSize();
    return Rect.fromLTWH(
      position.dx - 4,
      position.dy - 2,
      s.width + 8,
      s.height + 4,
    );
  }

  @override
  Rect get boundingBox => visualBounds.inflate(8);

  @override
  bool containsPoint(Offset point) => boundingBox.contains(point);

  @override
  TextElement copyWith() => TextElement(
    id: id,
    layerOrder: layerOrder,
    isSelected: isSelected,
    position: position,
    text: text,
    textColor: textColor,
    fontSize: fontSize,
    fontWeight: fontWeight,
    hasBackground: hasBackground,
    backgroundColor: backgroundColor,
  );
}

/// Equipment element (cones, poles, mannequins, mini-goals)
class EquipmentElement extends DrawingElement {
  Offset position;
  DrawingTool equipmentType;
  Color color;
  double size;
  double rotation;

  EquipmentElement({
    super.id,
    super.layerOrder,
    super.isSelected,
    required this.position,
    required this.equipmentType,
    this.color = Colors.orange,
    this.size = 24.0,
    this.rotation = 0.0,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'equipment',
    'position': {'dx': position.dx, 'dy': position.dy},
    'equipmentType': equipmentType.name,
    'color': color.toHex(),
    'size': size,
    'rotation': rotation,
    'layerOrder': layerOrder,
  };

  @override
  Rect get visualBounds =>
      Rect.fromCenter(center: position, width: size, height: size);

  @override
  Rect get boundingBox =>
      Rect.fromCenter(center: position, width: size + 16, height: size + 16);

  @override
  bool containsPoint(Offset point) => boundingBox.contains(point);

  @override
  EquipmentElement copyWith() => EquipmentElement(
    id: id,
    layerOrder: layerOrder,
    isSelected: isSelected,
    position: position,
    equipmentType: equipmentType,
    color: color,
    size: size,
    rotation: rotation,
  );
}

/// Extension to convert Color to hex string
extension ColorToHex on Color {
  String toHex() =>
      '#${(toARGB32() & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0')}';
}

/// Helper function to calculate distance from point to line segment (unused but kept for future use)
// ignore: unused_element
double _distanceToLineSegment(Offset point, Offset start, Offset end) {
  final l2 = (end - start).distanceSquared;
  if (l2 == 0) return (point - start).distance;

  var t =
      ((point.dx - start.dx) * (end.dx - start.dx) +
          (point.dy - start.dy) * (end.dy - start.dy)) /
      l2;
  t = t.clamp(0.0, 1.0);

  final projection = Offset(
    start.dx + t * (end.dx - start.dx),
    start.dy + t * (end.dy - start.dy),
  );
  return (point - projection).distance;
}

/// Drawing state manager
class DrawingState extends ChangeNotifier {
  final List<DrawingElement> _elements = [];
  final List<List<DrawingElement>> _undoStack = [];
  final List<List<DrawingElement>> _redoStack = [];

  DrawingTool _currentTool = DrawingTool.select;
  Color _currentColor = Colors.red;
  double _currentStrokeWidth = 3.0;
  LineStyle _currentLineStyle = LineStyle.solid;
  ArrowHeadPosition _currentArrowHead = ArrowHeadPosition.end;
  Color? _currentFillColor;
  double _currentFillOpacity = 0.3;

  DrawingElement? _selectedElement;
  DrawingElement? _currentDrawing;
  Offset? _startPoint;

  // For handle dragging
  HandleType _draggingHandle = HandleType.none;

  // Set by DrawingLayerState to constrain element movement
  Size fieldSize = Size.zero;

  List<DrawingElement> get elements => List.unmodifiable(_elements);
  DrawingTool get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  LineStyle get currentLineStyle => _currentLineStyle;
  ArrowHeadPosition get currentArrowHead => _currentArrowHead;
  Color? get currentFillColor => _currentFillColor;
  double get currentFillOpacity => _currentFillOpacity;
  DrawingElement? get selectedElement => _selectedElement;
  DrawingElement? get currentDrawing => _currentDrawing;
  HandleType get draggingHandle => _draggingHandle;

  /// Handle ESC / Delete keys
  bool handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (_currentTool != DrawingTool.select) {
        setTool(DrawingTool.select);
        return true;
      }
      // Deselect if something is selected
      if (_selectedElement != null) {
        _selectedElement!.isSelected = false;
        _selectedElement = null;
        notifyListeners();
        return true;
      }
    }
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.backspace)) {
      if (_selectedElement != null) {
        deleteSelected();
        return true;
      }
    }
    return false;
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void clearSelection() {
    if (_selectedElement != null) {
      _selectedElement!.isSelected = false;
      _selectedElement = null;
      notifyListeners();
    }
  }

  /// Returns the topmost element that contains [point], or null.
  DrawingElement? elementAt(Offset point) {
    for (final el in _elements.reversed) {
      if (el.containsPoint(point)) return el;
    }
    return null;
  }

  /// Trigger a repaint after external mutation (e.g. text edit).
  void notifyExternalChange() => notifyListeners();

  void setTool(DrawingTool tool) {
    if (_selectedElement != null) {
      _selectedElement!.isSelected = false;
      _selectedElement = null;
    }
    _currentTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    if (_selectedElement != null) {
      _updateSelectedElementColor(color);
    }
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    notifyListeners();
  }

  void setLineStyle(LineStyle style) {
    _currentLineStyle = style;
    notifyListeners();
  }

  void setArrowHead(ArrowHeadPosition position) {
    _currentArrowHead = position;
    notifyListeners();
  }

  void setFillColor(Color? color) {
    _currentFillColor = color;
    notifyListeners();
  }

  void setFillOpacity(double opacity) {
    _currentFillOpacity = opacity;
    notifyListeners();
  }

  void _saveState() {
    _undoStack.add(_elements.map((e) => e.copyWith()).toList());
    _redoStack.clear();
  }

  void _updateSelectedElementColor(Color color) {
    if (_selectedElement is FreehandElement) {
      (_selectedElement as FreehandElement).strokeColor = color;
    } else if (_selectedElement is LineElement) {
      (_selectedElement as LineElement).strokeColor = color;
    } else if (_selectedElement is ArrowElement) {
      (_selectedElement as ArrowElement).strokeColor = color;
    } else if (_selectedElement is RectangleElement) {
      (_selectedElement as RectangleElement).strokeColor = color;
    } else if (_selectedElement is EllipseElement) {
      (_selectedElement as EllipseElement).strokeColor = color;
    } else if (_selectedElement is SpotElement) {
      (_selectedElement as SpotElement).fillColor = color;
    } else if (_selectedElement is TextElement) {
      (_selectedElement as TextElement).textColor = color;
    } else if (_selectedElement is EquipmentElement) {
      (_selectedElement as EquipmentElement).color = color;
    }
  }

  void onPanStart(Offset position) {
    if (_currentTool == DrawingTool.select) {
      // First check if we're hitting a handle on a selected element
      if (_selectedElement != null) {
        // Check for line/arrow specific handles
        if (_selectedElement is LineElement) {
          final line = _selectedElement as LineElement;
          final handle = line.hitTestHandle(position);
          if (handle != HandleType.none) {
            _draggingHandle = handle;
            _startPoint = position;
            notifyListeners();
            return;
          }
        } else if (_selectedElement is ArrowElement) {
          final arrow = _selectedElement as ArrowElement;
          final handle = arrow.hitTestHandle(position);
          if (handle != HandleType.none) {
            _draggingHandle = handle;
            _startPoint = position;
            notifyListeners();
            return;
          }
        }

        // Check for resize handles on any element
        final resizeHandle = _hitTestResizeHandle(
          position,
          _selectedElement!.visualBounds,
        );
        if (resizeHandle != HandleType.none) {
          _draggingHandle = resizeHandle;
          _startPoint = position;
          notifyListeners();
          return;
        }
      }

      // Try to select element
      _draggingHandle = HandleType.none;
      DrawingElement? newSelection;
      for (var element in _elements.reversed) {
        if (element.containsPoint(position)) {
          newSelection = element;
          break;
        }
      }

      // Update selection
      for (var e in _elements) {
        e.isSelected = false;
      }
      _selectedElement = newSelection;
      if (_selectedElement != null) {
        _selectedElement!.isSelected = true;
      }
      _startPoint = position;
      notifyListeners();
      return;
    }

    _startPoint = position;

    switch (_currentTool) {
      case DrawingTool.freehand:
        _currentDrawing = FreehandElement(
          points: [position],
          strokeColor: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        break;
      case DrawingTool.line:
        _currentDrawing = LineElement(
          start: position,
          end: position,
          strokeColor: _currentColor,
          strokeWidth: _currentStrokeWidth,
          lineStyle: _currentLineStyle,
        );
        break;
      case DrawingTool.arrow:
        _currentDrawing = ArrowElement(
          start: position,
          end: position,
          strokeColor: _currentColor,
          strokeWidth: _currentStrokeWidth,
          lineStyle: _currentLineStyle,
          arrowHead: _currentArrowHead,
        );
        break;
      case DrawingTool.rectangle:
        _currentDrawing = RectangleElement(
          rect: Rect.fromPoints(position, position),
          strokeColor: _currentColor,
          strokeWidth: _currentStrokeWidth,
          fillColor: _currentFillColor,
          fillOpacity: _currentFillOpacity,
        );
        break;
      case DrawingTool.ellipse:
        _currentDrawing = EllipseElement(
          rect: Rect.fromPoints(position, position),
          strokeColor: _currentColor,
          strokeWidth: _currentStrokeWidth,
          fillColor: _currentFillColor,
          fillOpacity: _currentFillOpacity,
        );
        break;
      case DrawingTool.spot:
        _currentDrawing = SpotElement(
          points: [position],
          fillColor: _currentFillColor ?? _currentColor,
          fillOpacity: _currentFillOpacity,
          strokeColor: _currentColor,
          strokeWidth: _currentStrokeWidth,
        );
        break;
      case DrawingTool.cone:
      case DrawingTool.pole:
      case DrawingTool.mannequin:
      case DrawingTool.miniGoal:
        _currentDrawing = EquipmentElement(
          position: position,
          equipmentType: _currentTool,
          color: _currentColor,
        );
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void onPanUpdate(Offset position) {
    if (_currentTool == DrawingTool.select && _selectedElement != null) {
      // Check if we're dragging a handle
      if (_draggingHandle != HandleType.none) {
        _moveHandle(_selectedElement!, _draggingHandle, position);
        notifyListeners();
        return;
      }

      // Move selected element, clamped to field bounds
      final rawDelta = position - (_startPoint ?? position);
      final delta = _clampDelta(_selectedElement!, rawDelta);
      _moveElement(_selectedElement!, delta);
      // Adjust _startPoint by actual applied delta to avoid drift
      _startPoint = (_startPoint ?? position) + delta;
      notifyListeners();
      return;
    }

    if (_currentDrawing == null) return;

    switch (_currentTool) {
      case DrawingTool.freehand:
        (_currentDrawing as FreehandElement).points.add(position);
        break;
      case DrawingTool.line:
        (_currentDrawing as LineElement).end = position;
        break;
      case DrawingTool.arrow:
        (_currentDrawing as ArrowElement).end = position;
        break;
      case DrawingTool.rectangle:
        (_currentDrawing as RectangleElement).rect = Rect.fromPoints(
          _startPoint!,
          position,
        );
        break;
      case DrawingTool.ellipse:
        (_currentDrawing as EllipseElement).rect = Rect.fromPoints(
          _startPoint!,
          position,
        );
        break;
      case DrawingTool.spot:
        (_currentDrawing as SpotElement).points.add(position);
        break;
      case DrawingTool.cone:
      case DrawingTool.pole:
      case DrawingTool.mannequin:
      case DrawingTool.miniGoal:
        (_currentDrawing as EquipmentElement).position = position;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void onPanEnd() {
    if (_draggingHandle != HandleType.none) {
      _draggingHandle = HandleType.none;
      notifyListeners();
      return;
    }

    if (_currentDrawing != null) {
      _saveState();
      // Initialize control points for lines and arrows
      if (_currentDrawing is LineElement) {
        (_currentDrawing as LineElement).initControlPoints();
      } else if (_currentDrawing is ArrowElement) {
        (_currentDrawing as ArrowElement).initControlPoints();
      }
      _elements.add(_currentDrawing!);
      _currentDrawing = null;
    }
    _startPoint = null;
    notifyListeners();
  }

  void onTap(Offset position) {
    // Handle selection by click
    if (_currentTool == DrawingTool.select) {
      DrawingElement? newSelection;
      for (var element in _elements.reversed) {
        if (element.containsPoint(position)) {
          newSelection = element;
          break;
        }
      }

      // Update selection
      for (var e in _elements) {
        e.isSelected = false;
      }
      _selectedElement = newSelection;
      if (_selectedElement != null) {
        _selectedElement!.isSelected = true;
      }
      notifyListeners();
      return;
    }

    if (_currentTool == DrawingTool.text) {
      _saveState();
      _elements.add(
        TextElement(position: position, text: 'Text', textColor: _currentColor),
      );
      notifyListeners();
    }
  }

  void _moveElement(DrawingElement element, Offset delta) {
    if (element is FreehandElement) {
      element.points = element.points.map((p) => p + delta).toList();
    } else if (element is LineElement) {
      element.start += delta;
      element.end += delta;
      if (element.control1 != null) {
        element.control1 = element.control1! + delta;
      }
      if (element.control2 != null) {
        element.control2 = element.control2! + delta;
      }
    } else if (element is ArrowElement) {
      element.start += delta;
      element.end += delta;
      if (element.control1 != null) {
        element.control1 = element.control1! + delta;
      }
      if (element.control2 != null) {
        element.control2 = element.control2! + delta;
      }
    } else if (element is RectangleElement) {
      element.rect = element.rect.shift(delta);
    } else if (element is EllipseElement) {
      element.rect = element.rect.shift(delta);
    } else if (element is SpotElement) {
      element.points = element.points.map((p) => p + delta).toList();
    } else if (element is TextElement) {
      element.position += delta;
    } else if (element is EquipmentElement) {
      element.position += delta;
    }
  }

  /// Clamp [delta] so that [element]'s bounding box stays within [fieldSize].
  Offset _clampDelta(DrawingElement element, Offset delta) {
    if (fieldSize == Size.zero) return delta;
    final box = element.visualBounds;
    final dx = delta.dx.clamp(
      -box.left,
      fieldSize.width - box.right,
    );
    final dy = delta.dy.clamp(
      -box.top,
      fieldSize.height - box.bottom,
    );
    return Offset(dx, dy);
  }

  void _moveHandle(DrawingElement element, HandleType handle, Offset position) {
    // Handle line/arrow specific handles
    if (element is LineElement) {
      switch (handle) {
        case HandleType.start:
          element.start = position;
          return;
        case HandleType.end:
          element.end = position;
          return;
        case HandleType.control1:
          element.control1 = position;
          return;
        case HandleType.control2:
          element.control2 = position;
          return;
        default:
          break;
      }
    } else if (element is ArrowElement) {
      switch (handle) {
        case HandleType.start:
          element.start = position;
          return;
        case HandleType.end:
          element.end = position;
          return;
        case HandleType.control1:
          element.control1 = position;
          return;
        case HandleType.control2:
          element.control2 = position;
          return;
        default:
          break;
      }
    }

    // Handle resize for rect-based elements
    if (element is RectangleElement) {
      element.rect = _resizeRect(element.rect, handle, position);
    } else if (element is EllipseElement) {
      element.rect = _resizeRect(element.rect, handle, position);
    } else if (element is EquipmentElement) {
      // For equipment, resize by changing size based on distance from center
      final distance = (position - element.position).distance;
      element.size = (distance * 2).clamp(16.0, 100.0);
    } else if (element is SpotElement) {
      // Scale all points relative to the visual bounds
      final bounds = element.visualBounds;
      final newRect = _resizeRect(bounds, handle, position);
      if (bounds.width > 0 && bounds.height > 0) {
        final scaleX = newRect.width / bounds.width;
        final scaleY = newRect.height / bounds.height;
        element.points = element.points.map((p) {
          final nx = newRect.left + (p.dx - bounds.left) * scaleX;
          final ny = newRect.top + (p.dy - bounds.top) * scaleY;
          return Offset(nx, ny);
        }).toList();
      }
    } else if (element is TextElement) {
      // For text, resize by changing font size
      final bounds = element.visualBounds;
      final newWidth = (position.dx - bounds.left).abs();
      element.fontSize = (newWidth / (element.text.length * 0.6)).clamp(
        8.0,
        48.0,
      );
    }
  }

  Rect _resizeRect(Rect rect, HandleType handle, Offset position) {
    switch (handle) {
      case HandleType.topLeft:
        return Rect.fromLTRB(position.dx, position.dy, rect.right, rect.bottom);
      case HandleType.topRight:
        return Rect.fromLTRB(rect.left, position.dy, position.dx, rect.bottom);
      case HandleType.bottomLeft:
        return Rect.fromLTRB(position.dx, rect.top, rect.right, position.dy);
      case HandleType.bottomRight:
        return Rect.fromLTRB(rect.left, rect.top, position.dx, position.dy);
      case HandleType.topCenter:
        return Rect.fromLTRB(rect.left, position.dy, rect.right, rect.bottom);
      case HandleType.bottomCenter:
        return Rect.fromLTRB(rect.left, rect.top, rect.right, position.dy);
      case HandleType.leftCenter:
        return Rect.fromLTRB(position.dx, rect.top, rect.right, rect.bottom);
      case HandleType.rightCenter:
        return Rect.fromLTRB(rect.left, rect.top, position.dx, rect.bottom);
      default:
        return rect;
    }
  }

  HandleType _hitTestResizeHandle(
    Offset point,
    Rect bounds, {
    double tolerance = 12.0,
  }) {
    // Corner handles
    if ((bounds.topLeft - point).distance < tolerance) {
      return HandleType.topLeft;
    }
    if ((bounds.topRight - point).distance < tolerance) {
      return HandleType.topRight;
    }
    if ((bounds.bottomLeft - point).distance < tolerance) {
      return HandleType.bottomLeft;
    }
    if ((bounds.bottomRight - point).distance < tolerance) {
      return HandleType.bottomRight;
    }

    // Midpoint handles
    final topCenter = Offset(bounds.center.dx, bounds.top);
    final bottomCenter = Offset(bounds.center.dx, bounds.bottom);
    final leftCenter = Offset(bounds.left, bounds.center.dy);
    final rightCenter = Offset(bounds.right, bounds.center.dy);

    if ((topCenter - point).distance < tolerance) return HandleType.topCenter;
    if ((bottomCenter - point).distance < tolerance) {
      return HandleType.bottomCenter;
    }
    if ((leftCenter - point).distance < tolerance) return HandleType.leftCenter;
    if ((rightCenter - point).distance < tolerance) {
      return HandleType.rightCenter;
    }

    return HandleType.none;
  }

  void deleteSelected() {
    if (_selectedElement != null) {
      _saveState();
      _elements.remove(_selectedElement);
      _selectedElement = null;
      notifyListeners();
    }
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_elements.map((e) => e.copyWith()).toList());
      _elements.clear();
      _elements.addAll(_undoStack.removeLast());
      _selectedElement = null;
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_elements.map((e) => e.copyWith()).toList());
      _elements.clear();
      _elements.addAll(_redoStack.removeLast());
      _selectedElement = null;
      notifyListeners();
    }
  }

  void clearAll() {
    if (_elements.isNotEmpty) {
      _saveState();
      _elements.clear();
      _selectedElement = null;
      notifyListeners();
    }
  }

  void bringToFront() {
    if (_selectedElement != null) {
      _saveState();
      _elements.remove(_selectedElement);
      _elements.add(_selectedElement!);
      notifyListeners();
    }
  }

  void sendToBack() {
    if (_selectedElement != null) {
      _saveState();
      _elements.remove(_selectedElement);
      _elements.insert(0, _selectedElement!);
      notifyListeners();
    }
  }

  Map<String, dynamic> toJson() => {
    'elements': _elements.map((e) => e.toJson()).toList(),
  };

  void fromJson(Map<String, dynamic> json) {
    _elements.clear();
    final elementsJson = json['elements'] as List?;
    if (elementsJson != null) {
      for (final elementJson in elementsJson) {
        final type = elementJson['type'] as String;
        final element = _deserializeElement(type, elementJson);
        if (element != null) {
          _elements.add(element);
        }
      }
    }
    notifyListeners();
  }

  DrawingElement? _deserializeElement(String type, Map<String, dynamic> json) {
    switch (type) {
      case 'freehand':
        return FreehandElement(
          id: json['id'],
          layerOrder: json['layerOrder'] ?? 0,
          points: (json['points'] as List)
              .map(
                (p) => Offset(
                  (p['dx'] as num).toDouble(),
                  (p['dy'] as num).toDouble(),
                ),
              )
              .toList(),
          strokeColor: _parseColor(json['strokeColor']),
          strokeWidth: (json['strokeWidth'] as num).toDouble(),
          opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        );
      case 'line':
        return LineElement(
          id: json['id'],
          layerOrder: json['layerOrder'] ?? 0,
          start: _parseOffset(json['start']),
          end: _parseOffset(json['end']),
          control1: json['control1'] != null
              ? _parseOffset(json['control1'])
              : null,
          control2: json['control2'] != null
              ? _parseOffset(json['control2'])
              : null,
          strokeColor: _parseColor(json['strokeColor']),
          strokeWidth: (json['strokeWidth'] as num).toDouble(),
          lineStyle: LineStyle.values.firstWhere(
            (e) => e.name == json['lineStyle'],
            orElse: () => LineStyle.solid,
          ),
        );
      case 'arrow':
        return ArrowElement(
          id: json['id'],
          layerOrder: json['layerOrder'] ?? 0,
          start: _parseOffset(json['start']),
          end: _parseOffset(json['end']),
          control1: json['control1'] != null
              ? _parseOffset(json['control1'])
              : null,
          control2: json['control2'] != null
              ? _parseOffset(json['control2'])
              : null,
          strokeColor: _parseColor(json['strokeColor']),
          strokeWidth: (json['strokeWidth'] as num).toDouble(),
          lineStyle: LineStyle.values.firstWhere(
            (e) => e.name == json['lineStyle'],
            orElse: () => LineStyle.solid,
          ),
          arrowHead: ArrowHeadPosition.values.firstWhere(
            (e) => e.name == json['arrowHead'],
            orElse: () => ArrowHeadPosition.end,
          ),
          arrowSize: (json['arrowSize'] as num?)?.toDouble() ?? 12.0,
        );
      case 'rectangle':
        final rectJson = json['rect'] as Map<String, dynamic>;
        return RectangleElement(
          id: json['id'],
          layerOrder: json['layerOrder'] ?? 0,
          rect: Rect.fromLTWH(
            (rectJson['left'] as num).toDouble(),
            (rectJson['top'] as num).toDouble(),
            (rectJson['width'] as num).toDouble(),
            (rectJson['height'] as num).toDouble(),
          ),
          strokeColor: _parseColor(json['strokeColor']),
          strokeWidth: (json['strokeWidth'] as num).toDouble(),
          fillColor: json['fillColor'] != null
              ? _parseColor(json['fillColor'])
              : null,
          fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 0.3,
          rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        );
      case 'ellipse':
        final rectJson = json['rect'] as Map<String, dynamic>;
        return EllipseElement(
          id: json['id'],
          layerOrder: json['layerOrder'] ?? 0,
          rect: Rect.fromLTWH(
            (rectJson['left'] as num).toDouble(),
            (rectJson['top'] as num).toDouble(),
            (rectJson['width'] as num).toDouble(),
            (rectJson['height'] as num).toDouble(),
          ),
          strokeColor: _parseColor(json['strokeColor']),
          strokeWidth: (json['strokeWidth'] as num).toDouble(),
          fillColor: json['fillColor'] != null
              ? _parseColor(json['fillColor'])
              : null,
          fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 0.3,
        );
      case 'spot':
        return SpotElement(
          id: json['id'],
          layerOrder: json['layerOrder'] ?? 0,
          points: (json['points'] as List)
              .map(
                (p) => Offset(
                  (p['dx'] as num).toDouble(),
                  (p['dy'] as num).toDouble(),
                ),
              )
              .toList(),
          fillColor: _parseColor(json['fillColor']),
          fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 0.5,
          strokeColor: _parseColor(json['strokeColor']),
          strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
        );
      case 'text':
        return TextElement(
          id: json['id'],
          layerOrder: json['layerOrder'] ?? 0,
          position: _parseOffset(json['position']),
          text: json['text'] as String,
          textColor: _parseColor(json['textColor']),
          fontSize: (json['fontSize'] as num).toDouble(),
          fontWeight: FontWeight.values[json['fontWeight'] as int? ?? 6],
          hasBackground: json['hasBackground'] as bool? ?? true,
          backgroundColor: json['backgroundColor'] != null
              ? _parseColor(json['backgroundColor'])
              : null,
        );
      case 'equipment':
        return EquipmentElement(
          id: json['id'],
          layerOrder: json['layerOrder'] ?? 0,
          position: _parseOffset(json['position']),
          equipmentType: DrawingTool.values.firstWhere(
            (e) => e.name == json['equipmentType'],
            orElse: () => DrawingTool.cone,
          ),
          color: _parseColor(json['color']),
          size: (json['size'] as num).toDouble(),
          rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        );
      default:
        return null;
    }
  }

  Offset _parseOffset(Map<String, dynamic> json) {
    return Offset(
      (json['dx'] as num).toDouble(),
      (json['dy'] as num).toDouble(),
    );
  }

  Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse(hexCode, radix: 16));
  }
}

/// Drawing painter
class DrawingPainter extends CustomPainter {
  final List<DrawingElement> elements;
  final DrawingElement? currentDrawing;
  final String? excludeId;

  DrawingPainter({required this.elements, this.currentDrawing, this.excludeId});

  @override
  void paint(Canvas canvas, Size size) {
    for (var element in elements) {
      if (element.id == excludeId) continue;
      _paintElement(canvas, element);
    }
    if (currentDrawing != null) {
      _paintElement(canvas, currentDrawing!);
    }
  }

  void _paintElement(Canvas canvas, DrawingElement element) {
    if (element is FreehandElement) {
      _paintFreehand(canvas, element);
    } else if (element is LineElement) {
      _paintLine(canvas, element);
    } else if (element is ArrowElement) {
      _paintArrow(canvas, element);
    } else if (element is RectangleElement) {
      _paintRectangle(canvas, element);
    } else if (element is EllipseElement) {
      _paintEllipse(canvas, element);
    } else if (element is SpotElement) {
      _paintSpot(canvas, element);
    } else if (element is TextElement) {
      _paintText(canvas, element);
    } else if (element is EquipmentElement) {
      _paintEquipment(canvas, element);
    }

    // Draw selection handles
    if (element.isSelected) {
      _paintSelectionHandles(canvas, element.visualBounds);
    }
  }

  void _paintFreehand(Canvas canvas, FreehandElement element) {
    if (element.points.length < 2) return;
    final paint = Paint()
      ..color = element.strokeColor.withValues(alpha: element.opacity)
      ..strokeWidth = element.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = element.points;
    path.moveTo(points.first.dx, points.first.dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
    } else {
      // Use quadratic bezier curves for smooth lines
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final midX = (p0.dx + p1.dx) / 2;
        final midY = (p0.dy + p1.dy) / 2;

        if (i == 0) {
          path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
        } else {
          path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
        }
      }
      // Draw to the last point
      final lastPoint = points.last;
      path.lineTo(lastPoint.dx, lastPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _paintLine(Canvas canvas, LineElement element) {
    final paint = Paint()
      ..color = element.strokeColor
      ..strokeWidth = element.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    _applyLineStyle(paint, element.lineStyle, element.strokeWidth);

    // Draw smooth curved line through all control points
    final handles = element.handlePositions;
    final path = _createSmoothPath(handles);
    canvas.drawPath(path, paint);

    // Draw handles if selected
    if (element.isSelected) {
      _paintLineHandles(canvas, handles);
    }
  }

  /// Create a smooth curved path through the given points using Catmull-Rom spline
  /// This ensures the curve passes THROUGH all control points
  Path _createSmoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    if (points.length == 1) {
      path.moveTo(points[0].dx, points[0].dy);
      return path;
    }

    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // Use Catmull-Rom spline converted to cubic Bezier for smooth curves through all points
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[0];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length
          ? points[i + 2]
          : points[points.length - 1];

      // Catmull-Rom to Cubic Bezier conversion
      // Control point 1: p1 + (p2 - p0) / 6
      // Control point 2: p2 - (p3 - p1) / 6
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  void _paintArrow(Canvas canvas, ArrowElement element) {
    final paint = Paint()
      ..color = element.strokeColor
      ..strokeWidth = element.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    _applyLineStyle(paint, element.lineStyle, element.strokeWidth);

    // Draw smooth curved line through all control points
    final handles = element.handlePositions;
    final path = _createSmoothPath(handles);
    canvas.drawPath(path, paint);

    // Draw arrow heads - calculate angle from last segment
    final lastIdx = handles.length - 1;
    final endAngle = math.atan2(
      handles[lastIdx].dy - handles[lastIdx - 1].dy,
      handles[lastIdx].dx - handles[lastIdx - 1].dx,
    );
    final startAngle = math.atan2(
      handles[1].dy - handles[0].dy,
      handles[1].dx - handles[0].dx,
    );

    if (element.arrowHead == ArrowHeadPosition.end ||
        element.arrowHead == ArrowHeadPosition.both) {
      _drawArrowHead(
        canvas,
        handles[lastIdx],
        endAngle,
        element.arrowSize,
        paint,
      );
    }
    if (element.arrowHead == ArrowHeadPosition.start ||
        element.arrowHead == ArrowHeadPosition.both) {
      _drawArrowHead(
        canvas,
        handles[0],
        startAngle + math.pi,
        element.arrowSize,
        paint,
      );
    }

    // Draw handles if selected
    if (element.isSelected) {
      _paintLineHandles(canvas, handles);
    }
  }

  void _paintLineHandles(Canvas canvas, List<Offset> handles) {
    const handleSize = 10.0;

    // Draw connecting lines between handles (visual guide)
    final guidePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < handles.length - 1; i++) {
      canvas.drawLine(handles[i], handles[i + 1], guidePaint);
    }

    // Draw handles
    for (int i = 0; i < handles.length; i++) {
      final handle = handles[i];
      final isEndpoint = i == 0 || i == handles.length - 1;

      final paint = Paint()
        ..color = isEndpoint ? Colors.blue : Colors.orange
        ..style = PaintingStyle.fill;

      if (isEndpoint) {
        // Square handles for endpoints
        canvas.drawRect(
          Rect.fromCenter(
            center: handle,
            width: handleSize,
            height: handleSize,
          ),
          paint,
        );
      } else {
        // Circle handles for control points
        canvas.drawCircle(handle, handleSize / 2, paint);
      }

      // White border
      paint
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      if (isEndpoint) {
        canvas.drawRect(
          Rect.fromCenter(
            center: handle,
            width: handleSize,
            height: handleSize,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(handle, handleSize / 2, paint);
      }
    }
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    double angle,
    double size,
    Paint paint,
  ) {
    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - size * math.cos(angle - math.pi / 6),
      tip.dy - size * math.sin(angle - math.pi / 6),
    );
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - size * math.cos(angle + math.pi / 6),
      tip.dy - size * math.sin(angle + math.pi / 6),
    );
    canvas.drawPath(path, paint);
  }

  void _paintRectangle(Canvas canvas, RectangleElement element) {
    if (element.fillColor != null) {
      final fillPaint = Paint()
        ..color = element.fillColor!.withValues(alpha: element.fillOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(element.rect, fillPaint);
    }

    final strokePaint = Paint()
      ..color = element.strokeColor
      ..strokeWidth = element.strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawRect(element.rect, strokePaint);
  }

  void _paintEllipse(Canvas canvas, EllipseElement element) {
    if (element.fillColor != null) {
      final fillPaint = Paint()
        ..color = element.fillColor!.withValues(alpha: element.fillOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawOval(element.rect, fillPaint);
    }

    final strokePaint = Paint()
      ..color = element.strokeColor
      ..strokeWidth = element.strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawOval(element.rect, strokePaint);
  }

  void _paintSpot(Canvas canvas, SpotElement element) {
    if (element.points.length < 2) return;

    final path = Path();
    path.moveTo(element.points.first.dx, element.points.first.dy);
    for (int i = 1; i < element.points.length; i++) {
      path.lineTo(element.points[i].dx, element.points[i].dy);
    }
    path.close(); // Close the path to create a filled shape

    // Draw fill
    final fillPaint = Paint()
      ..color = element.fillColor.withValues(alpha: element.fillOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw stroke
    if (element.strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = element.strokeColor
        ..strokeWidth = element.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, strokePaint);
    }
  }

  void _paintText(Canvas canvas, TextElement element) {
    if (element.hasBackground) {
      final bgPaint = Paint()
        ..color = element.backgroundColor ?? Colors.black54
        ..style = PaintingStyle.fill;
      final textSpan = TextSpan(
        text: element.text,
        style: TextStyle(
          fontFamily: 'Raleway',
          fontSize: element.fontSize,
          fontWeight: element.fontWeight,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      final bgRect = Rect.fromLTWH(
        element.position.dx - 4,
        element.position.dy - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
        bgPaint,
      );
    }

    final textSpan = TextSpan(
      text: element.text,
      style: TextStyle(
        fontFamily: 'Raleway',
        color: element.textColor,
        fontSize: element.fontSize,
        fontWeight: element.fontWeight,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, element.position);
  }

  void _paintEquipment(Canvas canvas, EquipmentElement element) {
    final paint = Paint()
      ..color = element.color
      ..style = PaintingStyle.fill;

    switch (element.equipmentType) {
      case DrawingTool.cone:
        _drawCone(canvas, element.position, element.size, paint);
        break;
      case DrawingTool.pole:
        _drawPole(canvas, element.position, element.size, paint);
        break;
      case DrawingTool.mannequin:
        _drawMannequin(canvas, element.position, element.size, paint);
        break;
      case DrawingTool.miniGoal:
        _drawMiniGoal(canvas, element.position, element.size, paint);
        break;
      default:
        canvas.drawCircle(element.position, element.size / 2, paint);
    }
  }

  void _drawCone(Canvas canvas, Offset position, double size, Paint paint) {
    final path = Path();
    path.moveTo(position.dx, position.dy - size / 2);
    path.lineTo(position.dx - size / 3, position.dy + size / 2);
    path.lineTo(position.dx + size / 3, position.dy + size / 2);
    path.close();
    canvas.drawPath(path, paint);

    // Orange stripes
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(position.dx - size / 6, position.dy),
      Offset(position.dx + size / 6, position.dy),
      paint,
    );
  }

  void _drawPole(Canvas canvas, Offset position, double size, Paint paint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: position, width: size / 4, height: size),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, paint);
  }

  void _drawMannequin(
    Canvas canvas,
    Offset position,
    double size,
    Paint paint,
  ) {
    // Head
    canvas.drawCircle(
      Offset(position.dx, position.dy - size / 3),
      size / 6,
      paint,
    );
    // Body
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(position.dx, position.dy + size / 6),
        width: size / 2,
        height: size / 2,
      ),
      paint,
    );
  }

  void _drawMiniGoal(Canvas canvas, Offset position, double size, Paint paint) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    final rect = Rect.fromCenter(
      center: position,
      width: size,
      height: size * 0.6,
    );
    canvas.drawRect(rect, paint);
    // Net pattern
    paint.strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(rect.left + rect.width * i / 4, rect.top),
        Offset(rect.left + rect.width * i / 4, rect.bottom),
        paint,
      );
    }
  }

  void _paintSelectionHandles(Canvas canvas, Rect bounds) {
    const borderColor = Color(0xFF18A0FB); // Figma blue
    const handleSize = 8.0;
    const half = handleSize / 2;

    // Selection border — 1px, sits exactly on the bounding box
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(bounds, borderPaint);

    // Handle positions — corners and edge midpoints
    final handles = [
      bounds.topLeft,
      bounds.topCenter,
      bounds.topRight,
      bounds.centerLeft,
      bounds.centerRight,
      bounds.bottomLeft,
      bounds.bottomCenter,
      bounds.bottomRight,
    ];

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final h in handles) {
      final rect = Rect.fromLTWH(h.dx - half, h.dy - half, handleSize, handleSize);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }

  void _applyLineStyle(Paint paint, LineStyle style, double width) {
    // Note: For dashed/dotted lines, you would need to use a custom path effect
    // This is a simplified version
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

/// Drawing toolbar widget
class DrawingToolbar extends StatefulWidget {
  final DrawingState state;
  final VoidCallback? onClose;
  final void Function(Offset globalPos)? onDragStart;
  final void Function(Offset globalPos)? onDragUpdate;
  final VoidCallback? onDragEnd;
  final ToolbarSide side;

  const DrawingToolbar({
    super.key,
    required this.state,
    this.onClose,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.side = ToolbarSide.bottom,
  });

  @override
  State<DrawingToolbar> createState() => _DrawingToolbarState();
}

class _DrawingToolbarState extends State<DrawingToolbar> {
  bool _isDragHandleHovered = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        // Local aliases so existing button references still compile
        final state = widget.state;
        final onClose = widget.onClose;
        final bool isVertical = widget.side == ToolbarSide.left;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Flex(
                direction: isVertical ? Axis.vertical : Axis.horizontal,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Semantics(
                    label: 'drawing-toolbar-drag-handle',
                    child: GestureDetector(
                      onPanStart: (d) =>
                          widget.onDragStart?.call(d.globalPosition),
                      onPanUpdate: (d) =>
                          widget.onDragUpdate?.call(d.globalPosition),
                      onPanEnd: (_) => widget.onDragEnd?.call(),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        onEnter: (_) =>
                            setState(() => _isDragHandleHovered = true),
                        onExit: (_) =>
                            setState(() => _isDragHandleHovered = false),
                        child: Tooltip(
                          message: 'Drag to move toolbar',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: isVertical
                                ? const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  )
                                : const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                            decoration: BoxDecoration(
                              color: _isDragHandleHovered
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              isVertical
                                  ? LucideIcons.gripVertical
                                  : LucideIcons.gripHorizontal,
                              color: _isDragHandleHovered
                                  ? Colors.white60
                                  : Colors.white30,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: isVertical ? 20 : 1,
                    height: isVertical ? 1 : 20,
                    margin: isVertical
                        ? const EdgeInsets.symmetric(vertical: 4)
                        : const EdgeInsets.symmetric(horizontal: 4),
                    color: Colors.white12,
                  ),
                  _ToolButton(
                    icon: LucideIcons.mousePointer2,
                    isSelected: state.currentTool == DrawingTool.select,
                    onPressed: () => state.setTool(DrawingTool.select),
                    tooltip: 'Select',
                  ),
                  _ToolButton(
                    icon: LucideIcons.pencil,
                    isSelected: state.currentTool == DrawingTool.freehand,
                    onPressed: () => state.setTool(DrawingTool.freehand),
                    tooltip: 'Freehand',
                  ),
                  _ToolButton(
                    icon: LucideIcons.minus,
                    isSelected: state.currentTool == DrawingTool.line,
                    onPressed: () => state.setTool(DrawingTool.line),
                    tooltip: 'Line',
                  ),
                  _ToolButton(
                    icon: LucideIcons.moveRight,
                    isSelected: state.currentTool == DrawingTool.arrow,
                    onPressed: () => state.setTool(DrawingTool.arrow),
                    tooltip: 'Arrow',
                  ),
                  _ToolButton(
                    icon: LucideIcons.square,
                    isSelected: state.currentTool == DrawingTool.rectangle,
                    onPressed: () => state.setTool(DrawingTool.rectangle),
                    tooltip: 'Rectangle',
                  ),
                  _ToolButton(
                    icon: LucideIcons.circle,
                    isSelected: state.currentTool == DrawingTool.ellipse,
                    onPressed: () => state.setTool(DrawingTool.ellipse),
                    tooltip: 'Ellipse',
                  ),
                  _ToolButton(
                    icon: LucideIcons.circleDot,
                    isSelected: state.currentTool == DrawingTool.spot,
                    onPressed: () => state.setTool(DrawingTool.spot),
                    tooltip: 'Spot',
                  ),
                  _ToolButton(
                    icon: LucideIcons.type,
                    isSelected: state.currentTool == DrawingTool.text,
                    onPressed: () => state.setTool(DrawingTool.text),
                    tooltip: 'Text',
                  ),

                  isVertical
                      ? const SizedBox(height: 8)
                      : const SizedBox(width: 8),
                  Container(
                    width: isVertical ? 24 : 1,
                    height: isVertical ? 1 : 24,
                    color: Colors.white24,
                  ),
                  isVertical
                      ? const SizedBox(height: 8)
                      : const SizedBox(width: 8),

                  // Equipment
                  _ToolButton(
                    icon: LucideIcons.triangle,
                    isSelected: state.currentTool == DrawingTool.cone,
                    onPressed: () => state.setTool(DrawingTool.cone),
                    tooltip: 'Cone',
                    iconColor: Colors.orange,
                  ),
                  _ToolButton(
                    icon: LucideIcons.pilcrow,
                    isSelected: state.currentTool == DrawingTool.pole,
                    onPressed: () => state.setTool(DrawingTool.pole),
                    tooltip: 'Pole',
                    iconColor: Colors.yellow,
                  ),
                  _ToolButton(
                    icon: LucideIcons.user,
                    isSelected: state.currentTool == DrawingTool.mannequin,
                    onPressed: () => state.setTool(DrawingTool.mannequin),
                    tooltip: 'Mannequin',
                    iconColor: Colors.blue,
                  ),

                  isVertical
                      ? const SizedBox(height: 8)
                      : const SizedBox(width: 8),
                  Container(
                    width: isVertical ? 24 : 1,
                    height: isVertical ? 1 : 24,
                    color: Colors.white24,
                  ),
                  isVertical
                      ? const SizedBox(height: 8)
                      : const SizedBox(width: 8),

                  // Color picker
                  _ColorPickerButton(state: state),

                  isVertical
                      ? const SizedBox(height: 8)
                      : const SizedBox(width: 8),
                  Container(
                    width: isVertical ? 24 : 1,
                    height: isVertical ? 1 : 24,
                    color: Colors.white24,
                  ),
                  isVertical
                      ? const SizedBox(height: 8)
                      : const SizedBox(width: 8),

                  // Actions
                  _ToolButton(
                    icon: LucideIcons.undo2,
                    onPressed: state.canUndo ? state.undo : null,
                    tooltip: 'Undo',
                  ),
                  _ToolButton(
                    icon: LucideIcons.redo2,
                    onPressed: state.canRedo ? state.redo : null,
                    tooltip: 'Redo',
                  ),
                  _ToolButton(
                    icon: LucideIcons.trash2,
                    onPressed: state.selectedElement != null
                        ? state.deleteSelected
                        : null,
                    tooltip: 'Delete',
                    iconColor: Colors.redAccent,
                  ),
                  _ToolButton(
                    icon: LucideIcons.eraser,
                    onPressed: state.elements.isNotEmpty
                        ? state.clearAll
                        : null,
                    tooltip: 'Clear All',
                  ),

                  if (onClose != null) ...[
                    isVertical
                        ? const SizedBox(height: 8)
                        : const SizedBox(width: 8),
                    Container(
                      width: isVertical ? 24 : 1,
                      height: isVertical ? 1 : 24,
                      color: Colors.white24,
                    ),
                    isVertical
                        ? const SizedBox(height: 8)
                        : const SizedBox(width: 8),
                    _ToolButton(
                      icon: LucideIcons.x,
                      onPressed: onClose,
                      tooltip: 'Close Drawing',
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToolButton extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? iconColor;

  const _ToolButton({
    required this.icon,
    this.isSelected = false,
    this.onPressed,
    required this.tooltip,
    this.iconColor,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : _isHovered
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: isDisabled
                  ? Colors.white38
                  : widget.iconColor ??
                        (widget.isSelected ? Colors.white : Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Color picker – button + popup
// ═══════════════════════════════════════════════════════════════════════════

class _ColorPickerButton extends StatefulWidget {
  final DrawingState state;
  const _ColorPickerButton({required this.state});

  @override
  State<_ColorPickerButton> createState() => _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<_ColorPickerButton> {
  OverlayEntry? _overlay;

  bool get _isOpen => _overlay != null;

  void _open() {
    if (_isOpen) {
      _close();
      return;
    }

    final overlayState = Overlay.of(context);
    final overlayBox = overlayState.context.findRenderObject() as RenderBox;
    final buttonBox = context.findRenderObject() as RenderBox;
    final buttonPos = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final buttonSize = buttonBox.size;

    const double popupW = 268.0;
    const double popupH = 430.0;

    double left = buttonPos.dx - (popupW - buttonSize.width) / 2;
    double top = buttonPos.dy - popupH - 10;

    left = left.clamp(8.0, overlayBox.size.width - popupW - 8);
    if (top < 8) top = buttonPos.dy + buttonSize.height + 10;

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: _ColorPickerPopup(state: widget.state, onClose: _close),
          ),
        ],
      ),
    );

    overlayState.insert(_overlay!);
    if (mounted) setState(() {});
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.state.currentColor;
    return Tooltip(
      message: 'Color',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _open,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isOpen ? Colors.white : Colors.white38,
                width: _isOpen ? 2 : 1,
              ),
              boxShadow: _isOpen
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ColorPickerPopup extends StatefulWidget {
  final DrawingState state;
  final VoidCallback onClose;

  const _ColorPickerPopup({required this.state, required this.onClose});

  @override
  State<_ColorPickerPopup> createState() => _ColorPickerPopupState();
}

class _ColorPickerPopupState extends State<_ColorPickerPopup> {
  static const List<Color> _presets = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.white,
    Colors.black,
    Color(0xFF00FF94),
  ];

  late double _hue; // 0–360
  late double _saturation; // 0–1
  late double _brightness; // 0–1
  late Color _initialColor; // snapshot when picker opened (shown as "recent")

  late final TextEditingController _hexCtrl;
  late final TextEditingController _rCtrl;
  late final TextEditingController _gCtrl;
  late final TextEditingController _bCtrl;

  @override
  void initState() {
    super.initState();
    _initialColor = widget.state.currentColor;
    final hsv = HSVColor.fromColor(widget.state.currentColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _brightness = hsv.value;

    final c = _buildColor();
    _hexCtrl = TextEditingController(text: _toHex(c));
    _rCtrl = TextEditingController(text: '${(c.r * 255).round()}');
    _gCtrl = TextEditingController(text: '${(c.g * 255).round()}');
    _bCtrl = TextEditingController(text: '${(c.b * 255).round()}');
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    _rCtrl.dispose();
    _gCtrl.dispose();
    _bCtrl.dispose();
    super.dispose();
  }

  Color _buildColor() =>
      HSVColor.fromAHSV(1.0, _hue, _saturation, _brightness).toColor();

  String _toHex(Color c) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  void _commit() {
    final c = _buildColor();
    widget.state.setColor(c);
    _hexCtrl.text = _toHex(c);
    _rCtrl.text = '${(c.r * 255).round()}';
    _gCtrl.text = '${(c.g * 255).round()}';
    _bCtrl.text = '${(c.b * 255).round()}';
  }

  void _pickPreset(Color c) {
    final hsv = HSVColor.fromColor(c);
    setState(() {
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _brightness = hsv.value;
    });
    _commit();
  }

  void _applyHex(String value) {
    var trimmed = value.replaceAll('#', '').trim();
    if (trimmed.length == 3) {
      trimmed = trimmed.split('').map((c) => '$c$c').join();
    }
    if (trimmed.length != 6) return;
    final parsed = int.tryParse(trimmed, radix: 16);
    if (parsed == null) return;
    final c = Color(0xFF000000 | parsed);
    final hsv = HSVColor.fromColor(c);
    setState(() {
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _brightness = hsv.value;
    });
    _commit();
  }

  void _applyRgb() {
    final r = (int.tryParse(_rCtrl.text) ?? 0).clamp(0, 255);
    final g = (int.tryParse(_gCtrl.text) ?? 0).clamp(0, 255);
    final b = (int.tryParse(_bCtrl.text) ?? 0).clamp(0, 255);
    final c = Color.fromARGB(255, r, g, b);
    final hsv = HSVColor.fromColor(c);
    setState(() {
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _brightness = hsv.value;
    });
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    final current = _buildColor();
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 268,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: const [
            BoxShadow(
              color: Color(0xCC000000),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
              child: Row(
                children: [
                  const Text(
                    'Color',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.x,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── SV picker ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SvPickerArea(
                hue: _hue,
                saturation: _saturation,
                brightness: _brightness,
                onChanged: (s, v) {
                  setState(() {
                    _saturation = s;
                    _brightness = v;
                  });
                  _commit();
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── Hue slider ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _HueSlider(
                hue: _hue,
                onChanged: (h) {
                  setState(() => _hue = h);
                  _commit();
                },
              ),
            ),

            const SizedBox(height: 14),

            // ── Hex + RGB inputs ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 34,
                          child: const Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Hex',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: current,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        SizedBox(
                          width: 136,
                          height: 34,
                          child: _PickerTextField(
                            controller: _hexCtrl,
                            onSubmitted: _applyHex,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          height: 34,
                          child: const Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'RGB',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        _RgbField(controller: _rCtrl, onSubmitted: _applyRgb),
                        const SizedBox(width: 4),
                        _RgbField(controller: _gCtrl, onSubmitted: _applyRgb),
                        const SizedBox(width: 4),
                        _RgbField(controller: _bCtrl, onSubmitted: _applyRgb),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Presets ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presets',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ColorSwatch(
                        color: _initialColor,
                        isSelected:
                            current.toARGB32() == _initialColor.toARGB32(),
                        onTap: () => _pickPreset(_initialColor),
                        showClock: true,
                      ),
                      const SizedBox(width: 6),
                      Container(width: 1, height: 24, color: Colors.white12),
                      const SizedBox(width: 6),
                      ...List.generate(_presets.length, (i) {
                        final c = _presets[i];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: i < _presets.length - 1 ? 5 : 0,
                          ),
                          child: _ColorSwatch(
                            color: c,
                            isSelected: current.toARGB32() == c.toARGB32(),
                            onTap: () => _pickPreset(c),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SV picker area
// ─────────────────────────────────────────────────────────────────────────────

class _SvPickerArea extends StatelessWidget {
  final double hue;
  final double saturation;
  final double brightness;
  final void Function(double s, double v) onChanged;

  const _SvPickerArea({
    required this.hue,
    required this.saturation,
    required this.brightness,
    required this.onChanged,
  });

  void _update(Offset pos, double w, double h) {
    onChanged((pos.dx / w).clamp(0.0, 1.0), 1.0 - (pos.dy / h).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    const double areaH = 156.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cx = saturation * w;
        final cy = (1 - brightness) * areaH;
        return SizedBox(
          height: areaH,
          child: GestureDetector(
            onPanDown: (d) => _update(d.localPosition, w, areaH),
            onPanUpdate: (d) => _update(d.localPosition, w, areaH),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(painter: _SvPainter(hue: hue)),
                  ),
                ),
                // Explicit cursor ring
                Positioned(
                  left: cx - 12,
                  top: cy - 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x88000000),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SvPainter extends CustomPainter {
  final double hue;
  _SvPainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SvPainter old) => old.hue != hue;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hue slider
// ─────────────────────────────────────────────────────────────────────────────

class _HueSlider extends StatelessWidget {
  final double hue; // 0–360
  final ValueChanged<double> onChanged;

  const _HueSlider({required this.hue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const double trackH = 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final knobX = (hue / 360 * w).clamp(trackH / 2, w - trackH / 2);
        return GestureDetector(
          onPanDown: (d) =>
              onChanged((d.localPosition.dx / w * 360).clamp(0, 360)),
          onPanUpdate: (d) =>
              onChanged((d.localPosition.dx / w * 360).clamp(0, 360)),
          child: SizedBox(
            width: w,
            height: trackH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(trackH / 2),
                    child: CustomPaint(painter: _HuePainter()),
                  ),
                ),
                Positioned(
                  left: knobX - trackH / 2,
                  top: 0,
                  child: Container(
                    width: trackH,
                    height: trackH,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x88000000), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HuePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: List.generate(
            13,
            (i) => HSVColor.fromAHSV(1, i * 30.0, 1, 1).toColor(),
          ),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_HuePainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Text fields
// ─────────────────────────────────────────────────────────────────────────────

class _PickerTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const _PickerTextField({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF333333),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        isDense: true,
      ),
      onSubmitted: onSubmitted,
      onEditingComplete: () => onSubmitted(controller.text),
    );
  }
}

class _RgbField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  const _RgbField({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 34,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white, fontSize: 13),
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF333333),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          isDense: true,
        ),
        onSubmitted: (_) => onSubmitted(),
        onEditingComplete: onSubmitted,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Color swatch
// ─────────────────────────────────────────────────────────────────────────────

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showClock;

  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.showClock = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white30,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.55),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: showClock
              ? const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      LucideIcons.clock4,
                      size: 8,
                      color: Colors.white70,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Main drawing layer widget to be used on top of the football pitch
class DrawingLayer extends StatefulWidget {
  final double width;
  final double height;
  final bool isEnabled;

  /// Callback when toolbar visibility changes - use this to render toolbar externally
  final void Function(bool isVisible)? onToolbarVisibilityChanged;

  /// Whether to render the toolbar internally (default) or let parent handle it
  final bool renderToolbarInternally;

  /// Callback when the toolbar is being dragged (isDragging, current global pos)
  final void Function(bool isDragging, Offset? globalPos)? onBarDragChanged;

  /// Callback when drawing elements change (add, remove, undo, redo, clear)
  final VoidCallback? onChanged;

  const DrawingLayer({
    super.key,
    required this.width,
    required this.height,
    this.isEnabled = true,
    this.onToolbarVisibilityChanged,
    this.renderToolbarInternally = true,
    this.onBarDragChanged,
    this.onChanged,
  });

  @override
  State<DrawingLayer> createState() => DrawingLayerState();
}

class DrawingLayerState extends State<DrawingLayer>
    with TickerProviderStateMixin {
  final DrawingState _state = DrawingState();
  bool _showToolbar = false;
  ToolbarSide _toolbarSide = ToolbarSide.bottom;
  Offset _lastBarDragPos = Offset.zero;

  ToolbarSide get toolbarSide => _toolbarSide;

  void setToolbarSide(ToolbarSide side) {
    if (_toolbarSide != side) {
      setState(() => _toolbarSide = side);
    }
  }

  /// Load drawing elements from a snapshot map: {'elements': [...]}
  void loadFromSnapshot(Map<String, dynamic> drawingJson) {
    _state.fromJson(drawingJson);
  }

  /// Rotate all drawing elements when the field orientation changes.
  /// [toVertical]: true = horizontal→vertical, false = vertical→horizontal.
  /// [oldSize]: field pixel size before rotation.
  /// [newSize]: field pixel size after rotation.
  void rotateElements(bool toVertical, Size oldSize, Size newSize) {
    if (_state.elements.isEmpty) return;
    if (oldSize.isEmpty || newSize.isEmpty) return;

    // Rotate a single pixel-coordinate point.
    Offset rotatePoint(Offset p) {
      final nx = p.dx / oldSize.width;
      final ny = p.dy / oldSize.height;
      final double nx2, ny2;
      if (toVertical) {
        // horizontal → vertical: (nx,ny) → (ny, 1-nx)
        nx2 = ny;
        ny2 = 1.0 - nx;
      } else {
        // vertical → horizontal: (nx,ny) → (1-ny, nx)
        nx2 = 1.0 - ny;
        ny2 = nx;
      }
      return Offset(nx2 * newSize.width, ny2 * newSize.height);
    }

    // Rotate a Rect defined by two corner points.
    Rect rotateRect(Rect r) {
      final tl = rotatePoint(r.topLeft);
      final br = rotatePoint(r.bottomRight);
      return Rect.fromPoints(tl, br);
    }

    for (final el in _state.elements) {
      if (el is FreehandElement) {
        el.points = el.points.map(rotatePoint).toList();
      } else if (el is LineElement) {
        el.start = rotatePoint(el.start);
        el.end = rotatePoint(el.end);
        if (el.control1 != null) el.control1 = rotatePoint(el.control1!);
        if (el.control2 != null) el.control2 = rotatePoint(el.control2!);
      } else if (el is ArrowElement) {
        el.start = rotatePoint(el.start);
        el.end = rotatePoint(el.end);
        if (el.control1 != null) el.control1 = rotatePoint(el.control1!);
        if (el.control2 != null) el.control2 = rotatePoint(el.control2!);
      } else if (el is RectangleElement) {
        el.rect = rotateRect(el.rect);
      } else if (el is EllipseElement) {
        el.rect = rotateRect(el.rect);
      } else if (el is SpotElement) {
        el.points = el.points.map(rotatePoint).toList();
      } else if (el is TextElement) {
        el.position = rotatePoint(el.position);
      } else if (el is EquipmentElement) {
        el.position = rotatePoint(el.position);
      }
    }
    _state.notifyExternalChange();
    setState(() {});
  }

  Offset clamp(Offset p) => Offset(
    p.dx.clamp(0.0, widget.width),
    p.dy.clamp(0.0, widget.height),
  );

  TextElement? _editingElement;
  final TextEditingController _inlineEditCtrl = TextEditingController();
  final FocusNode _inlineFocus = FocusNode();

  void _onDoubleTap(Offset position) {
    if (_state.currentTool != DrawingTool.select) return;
    final el = _state.elementAt(position);
    if (el is TextElement) {
      _startInlineEdit(el);
    }
  }

  void _startInlineEdit(TextElement element) {
    setState(() {
      _editingElement = element;
      _inlineEditCtrl.text = element.text;
      _inlineEditCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: element.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _inlineFocus.requestFocus());
  }

  void _commitInlineEdit() {
    if (_editingElement == null) return;
    final newText = _inlineEditCtrl.text.trim();
    if (newText.isNotEmpty) {
      _editingElement!.text = newText;
    }
    _state.notifyExternalChange();
    setState(() => _editingElement = null);
  }

  late final AnimationController _toolbarController;
  late final AnimationController _buttonController;
  late final Animation<double> _toolbarSlide;
  late final Animation<double> _toolbarFade;
  late final Animation<double> _buttonScale;
  late final Animation<double> _buttonRotation;

  DrawingState get state => _state;

  @override
  void initState() {
    super.initState();

    _state.fieldSize = Size(widget.width, widget.height);

    _toolbarController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _toolbarSlide = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(parent: _toolbarController, curve: Curves.easeOutBack),
    );

    _toolbarFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _toolbarController, curve: Curves.easeOut),
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInBack),
    );

    _buttonRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Notify parent when drawing elements change
    _state.addListener(_onDrawingStateChanged);

    // Open the toolbar by default at the bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openToolbar();
    });
  }

  void _onDrawingStateChanged() {
    widget.onChanged?.call();
  }

  @override
  void didUpdateWidget(DrawingLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width || oldWidget.height != widget.height) {
      _state.fieldSize = Size(widget.width, widget.height);
    }
  }

  @override
  void dispose() {
    _state.removeListener(_onDrawingStateChanged);
    _inlineEditCtrl.dispose();
    _inlineFocus.dispose();
    _toolbarController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void toggleToolbar() {
    setState(() {
      _showToolbar = !_showToolbar;
      widget.onToolbarVisibilityChanged?.call(_showToolbar);
      if (_showToolbar) {
        _buttonController.forward().then((_) {
          _toolbarController.forward();
        });
      } else {
        // Clear selection when closing toolbar
        _state.clearSelection();
        _toolbarController.reverse().then((_) {
          _buttonController.reverse();
        });
      }
    });
  }

  void _openToolbar() {
    if (!_showToolbar) {
      setState(() => _showToolbar = true);
      widget.onToolbarVisibilityChanged?.call(true);
      _buttonController.forward().then((_) {
        _toolbarController.forward();
      });
    }
  }

  void _closeToolbar() {
    _state.clearSelection();
    _toolbarController.reverse().then((_) {
      _buttonController.reverse();
      setState(() => _showToolbar = false);
      widget.onToolbarVisibilityChanged?.call(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allow toolbar to overflow
      children: [
        // Always show drawings - clipped to field bounds
        Positioned.fill(
          child: ClipRect(
            child: ListenableBuilder(
              listenable: _state,
              builder: (context, _) {
                final editingId = _editingElement?.id;

                // When toolbar is closed: just show drawings (no interaction)
                if (!_showToolbar) {
                  return IgnorePointer(
                    ignoring: true,
                    child: CustomPaint(
                      painter: DrawingPainter(
                        elements: _state.elements,
                        currentDrawing: null,
                        excludeId: editingId,
                      ),
                      size: Size(widget.width, widget.height),
                    ),
                  );
                }

                // When toolbar is open: interactive mode
                final isSelectMode = _state.currentTool == DrawingTool.select;
                final isDragging = _state.draggingHandle != HandleType.none;
                final hasSelectedElement = _state.selectedElement != null;

                // In select mode without selection: allow player placement
                if (isSelectMode && !isDragging && !hasSelectedElement) {
                  return IgnorePointer(
                    ignoring: true,
                    child: CustomPaint(
                      painter: DrawingPainter(
                        elements: _state.elements,
                        currentDrawing: _state.currentDrawing,
                        excludeId: editingId,
                      ),
                      size: Size(widget.width, widget.height),
                    ),
                  );
                }

                // In draw mode or when dragging/has selection: intercept all events
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) =>
                      _state.onPanStart(clamp(details.localPosition)),
                  onPanUpdate: (details) =>
                      _state.onPanUpdate(clamp(details.localPosition)),
                  onPanEnd: (_) => _state.onPanEnd(),
                  onTapUp: (details) =>
                      _state.onTap(clamp(details.localPosition)),
                  onDoubleTapDown: (details) =>
                      _onDoubleTap(clamp(details.localPosition)),
                  child: CustomPaint(
                    painter: DrawingPainter(
                      elements: _state.elements,
                      currentDrawing: _state.currentDrawing,
                      excludeId: editingId,
                    ),
                    size: Size(widget.width, widget.height),
                  ),
                );
              },
            ),
          ),
        ),

        // Separate layer for selecting drawing elements (only in select mode)
        if (_showToolbar)
          Positioned.fill(
            child: ListenableBuilder(
              listenable: _state,
              builder: (context, _) {
                final isSelectMode = _state.currentTool == DrawingTool.select;
                final isDragging = _state.draggingHandle != HandleType.none;
                final hasSelectedElement = _state.selectedElement != null;

                // Only show clickable areas for elements in select mode without selection
                if (!isSelectMode || isDragging || hasSelectedElement) {
                  return const SizedBox.shrink();
                }

                // Build clickable areas for each element
                return Stack(
                  children: _state.elements.map((element) {
                    final bounds = element.boundingBox;
                    return Positioned(
                      left: bounds.left,
                      top: bounds.top,
                      width: bounds.width,
                      height: bounds.height,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _state.onTap(bounds.center),
                        onPanStart: (details) => _state.onPanStart(
                          bounds.topLeft + details.localPosition,
                        ),
                        onPanUpdate: (details) => _state.onPanUpdate(
                          bounds.topLeft + details.localPosition,
                        ),
                        onPanEnd: (_) => _state.onPanEnd(),
                        child: const SizedBox.expand(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

        // Only render toolbar internally if configured to do so
        if (widget.renderToolbarInternally) ...[
          // Animated Toolbar - positioned to overflow to the right
          if (_showToolbar)
            Positioned(
              right: -16, // Offset outside the field
              bottom: 16,
              child: AnimatedBuilder(
                animation: _toolbarController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_toolbarSlide.value, 0),
                    child: Opacity(opacity: _toolbarFade.value, child: child),
                  );
                },
                child: DrawingToolbar(state: _state, onClose: _closeToolbar),
              ),
            ),

          // Animated Toggle button
          Positioned(
            right: -16, // Offset outside the field
            bottom: 16,
            child: AnimatedBuilder(
              animation: _buttonController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _buttonScale.value,
                  child: Transform.rotate(
                    angle: _buttonRotation.value * math.pi,
                    child: child,
                  ),
                );
              },
              child: _DrawingToggleButton(onPressed: _openToolbar),
            ),
          ),
        ],

        // Inline text editor — shown directly on the element when double-tapped
        if (_editingElement != null)
          Positioned(
            left: _editingElement!.position.dx,
            top: _editingElement!.position.dy,
            child: IntrinsicWidth(
              child: CallbackShortcuts(
                bindings: {
                  // Enter → commit
                  const SingleActivator(LogicalKeyboardKey.enter): _commitInlineEdit,
                  // Shift+Enter → insert newline
                  const SingleActivator(LogicalKeyboardKey.enter, shift: true): () {
                    final ctrl = _inlineEditCtrl;
                    final sel = ctrl.selection;
                    final text = ctrl.text;
                    final newText = text.replaceRange(sel.start, sel.end, '\n');
                    ctrl.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: sel.start + 1),
                    );
                  },
                },
                child: TextField(
                  controller: _inlineEditCtrl,
                  focusNode: _inlineFocus,
                  autofocus: true,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: _editingElement!.fontSize,
                    fontWeight: _editingElement!.fontWeight,
                    color: _editingElement!.textColor,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    border: InputBorder.none,
                  ),
                  onTapOutside: (_) => _commitInlineEdit(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build the toolbar widget (to be positioned externally)
  Widget buildToolbar() {
    if (!_showToolbar) {
      return AnimatedBuilder(
        animation: _buttonController,
        builder: (context, child) {
          return Transform.scale(
            scale: _buttonScale.value,
            child: Transform.rotate(
              angle: _buttonRotation.value * math.pi,
              child: child,
            ),
          );
        },
        child: _DrawingToggleButton(onPressed: _openToolbar),
      );
    }

    return AnimatedBuilder(
      animation: _toolbarController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_toolbarSlide.value, 0),
          child: Opacity(opacity: _toolbarFade.value, child: child),
        );
      },
      child: DrawingToolbar(state: _state, onClose: _closeToolbar),
    );
  }

  /// Build only the toolbar for external rendering (returns SizedBox if hidden)
  Widget buildToolbarOnly() {
    if (!_showToolbar) return const SizedBox.shrink();
    final sideLabel = _toolbarSide == ToolbarSide.left
        ? 'drawing-toolbar-left'
        : 'drawing-toolbar-bottom';
    return Semantics(
      label: sideLabel,
      container: true,
      child: AnimatedBuilder(
        animation: _toolbarController,
        builder: (context, child) {
          final isLeft = _toolbarSide == ToolbarSide.left;
          return Transform.translate(
            offset: isLeft
                ? Offset(-_toolbarSlide.value, 0)
                : Offset(0, _toolbarSlide.value),
            child: Opacity(opacity: _toolbarFade.value, child: child),
          );
        },
        child: DrawingToolbar(
          state: _state,
          onClose: _closeToolbar,
          side: _toolbarSide,
          onDragStart: (pos) {
            _lastBarDragPos = pos;
            widget.onBarDragChanged?.call(true, pos);
          },
          onDragUpdate: (pos) {
            _lastBarDragPos = pos;
            widget.onBarDragChanged?.call(true, pos);
          },
          onDragEnd: () {
            widget.onBarDragChanged?.call(false, _lastBarDragPos);
          },
        ),
      ),
    );
  }

  /// Build floating toolbar for drag preview (no animations, no drag callbacks)
  Widget buildFloatingToolbar() {
    if (!_showToolbar) return const SizedBox.shrink();
    return DrawingToolbar(state: _state, side: _toolbarSide);
  }

  /// Build only the toggle button for external rendering
  Widget buildToggleButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScale.value,
          child: Transform.rotate(
            angle: _buttonRotation.value * math.pi,
            child: child,
          ),
        );
      },
      child: _DrawingToggleButton(onPressed: _openToolbar),
    );
  }
}

class _DrawingToggleButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _DrawingToggleButton({required this.onPressed});

  @override
  State<_DrawingToggleButton> createState() => _DrawingToggleButtonState();
}

class _DrawingToggleButtonState extends State<_DrawingToggleButton>
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
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    // Shake rotation: 0 -> -15° -> 15° -> -10° -> 10° -> 0
    _shakeAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.15), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.15), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.1), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _shakeAnimation.value,
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
