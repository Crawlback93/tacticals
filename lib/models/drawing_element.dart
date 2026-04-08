import 'package:flutter/material.dart';

/// Enum for drawing tool types
enum DrawingTool {
  select,
  freehand,
  line,
  arrow,
  rectangle,
  ellipse,
  polygon,
  text,
  cone,
  pole,
  mannequin,
  miniGoal,
}

/// Enum for line styles
enum LineStyle { solid, dashed, dotted }

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

/// Extension to convert Color to hex string
extension ColorToHex on Color {
  String toHex() =>
      '#${(toARGB32() & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0')}';
}

/// Extension to parse hex string to Color
extension HexToColor on String {
  Color toColor() {
    final hexCode = replaceAll('#', '');
    return Color(int.parse(hexCode, radix: 16));
  }
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

  bool containsPoint(Offset point);

  DrawingElement copyWith();

  /// Factory constructor to create DrawingElement from JSON
  static DrawingElement fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'freehand':
        return FreehandElement.fromJson(json);
      case 'line':
        return LineElement.fromJson(json);
      case 'arrow':
        return ArrowElement.fromJson(json);
      case 'rectangle':
        return RectangleElement.fromJson(json);
      case 'ellipse':
        return EllipseElement.fromJson(json);
      case 'polygon':
        return PolygonElement.fromJson(json);
      case 'text':
        return TextElement.fromJson(json);
      case 'equipment':
        return EquipmentElement.fromJson(json);
      default:
        throw ArgumentError('Unknown drawing element type: $type');
    }
  }
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

  factory FreehandElement.fromJson(Map<String, dynamic> json) {
    return FreehandElement(
      id: json['id'] as String?,
      layerOrder: json['layerOrder'] as int? ?? 0,
      points: (json['points'] as List)
          .map(
            (p) => Offset(
              (p['dx'] as num).toDouble(),
              (p['dy'] as num).toDouble(),
            ),
          )
          .toList(),
      strokeColor: (json['strokeColor'] as String).toColor(),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

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
    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(10);
  }

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
  Offset? control1;
  Offset? control2;
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

  factory LineElement.fromJson(Map<String, dynamic> json) {
    return LineElement(
      id: json['id'] as String?,
      layerOrder: json['layerOrder'] as int? ?? 0,
      start: Offset(
        (json['start']['dx'] as num).toDouble(),
        (json['start']['dy'] as num).toDouble(),
      ),
      end: Offset(
        (json['end']['dx'] as num).toDouble(),
        (json['end']['dy'] as num).toDouble(),
      ),
      control1: json['control1'] != null
          ? Offset(
              (json['control1']['dx'] as num).toDouble(),
              (json['control1']['dy'] as num).toDouble(),
            )
          : null,
      control2: json['control2'] != null
          ? Offset(
              (json['control2']['dx'] as num).toDouble(),
              (json['control2']['dy'] as num).toDouble(),
            )
          : null,
      strokeColor: (json['strokeColor'] as String).toColor(),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      lineStyle: LineStyle.values.firstWhere(
        (e) => e.name == json['lineStyle'],
        orElse: () => LineStyle.solid,
      ),
    );
  }

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

  @override
  Rect get boundingBox {
    final points = handlePositions;
    double minX = points[0].dx, maxX = points[0].dx;
    double minY = points[0].dy, maxY = points[0].dy;
    for (var p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(10);
  }

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

  factory ArrowElement.fromJson(Map<String, dynamic> json) {
    return ArrowElement(
      id: json['id'] as String?,
      layerOrder: json['layerOrder'] as int? ?? 0,
      start: Offset(
        (json['start']['dx'] as num).toDouble(),
        (json['start']['dy'] as num).toDouble(),
      ),
      end: Offset(
        (json['end']['dx'] as num).toDouble(),
        (json['end']['dy'] as num).toDouble(),
      ),
      control1: json['control1'] != null
          ? Offset(
              (json['control1']['dx'] as num).toDouble(),
              (json['control1']['dy'] as num).toDouble(),
            )
          : null,
      control2: json['control2'] != null
          ? Offset(
              (json['control2']['dx'] as num).toDouble(),
              (json['control2']['dy'] as num).toDouble(),
            )
          : null,
      strokeColor: (json['strokeColor'] as String).toColor(),
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
  }

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

  @override
  Rect get boundingBox {
    final points = handlePositions;
    double minX = points[0].dx, maxX = points[0].dx;
    double minY = points[0].dy, maxY = points[0].dy;
    for (var p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(arrowSize + 10);
  }

  @override
  bool containsPoint(Offset point) => boundingBox.contains(point);

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

  factory RectangleElement.fromJson(Map<String, dynamic> json) {
    final rectJson = json['rect'] as Map<String, dynamic>;
    return RectangleElement(
      id: json['id'] as String?,
      layerOrder: json['layerOrder'] as int? ?? 0,
      rect: Rect.fromLTWH(
        (rectJson['left'] as num).toDouble(),
        (rectJson['top'] as num).toDouble(),
        (rectJson['width'] as num).toDouble(),
        (rectJson['height'] as num).toDouble(),
      ),
      strokeColor: (json['strokeColor'] as String).toColor(),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      fillColor: json['fillColor'] != null
          ? (json['fillColor'] as String).toColor()
          : null,
      fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 0.3,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

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
  Rect get boundingBox => rect.inflate(5);

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

  factory EllipseElement.fromJson(Map<String, dynamic> json) {
    final rectJson = json['rect'] as Map<String, dynamic>;
    return EllipseElement(
      id: json['id'] as String?,
      layerOrder: json['layerOrder'] as int? ?? 0,
      rect: Rect.fromLTWH(
        (rectJson['left'] as num).toDouble(),
        (rectJson['top'] as num).toDouble(),
        (rectJson['width'] as num).toDouble(),
        (rectJson['height'] as num).toDouble(),
      ),
      strokeColor: (json['strokeColor'] as String).toColor(),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      fillColor: json['fillColor'] != null
          ? (json['fillColor'] as String).toColor()
          : null,
      fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 0.3,
    );
  }

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
  Rect get boundingBox => rect.inflate(5);

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

/// Polygon / Area element
class PolygonElement extends DrawingElement {
  List<Offset> points;
  Color strokeColor;
  double strokeWidth;
  Color? fillColor;
  double fillOpacity;
  bool isClosed;

  PolygonElement({
    super.id,
    super.layerOrder,
    super.isSelected,
    required this.points,
    this.strokeColor = Colors.red,
    this.strokeWidth = 2.0,
    this.fillColor,
    this.fillOpacity = 0.3,
    this.isClosed = true,
  });

  factory PolygonElement.fromJson(Map<String, dynamic> json) {
    return PolygonElement(
      id: json['id'] as String?,
      layerOrder: json['layerOrder'] as int? ?? 0,
      points: (json['points'] as List)
          .map(
            (p) => Offset(
              (p['dx'] as num).toDouble(),
              (p['dy'] as num).toDouble(),
            ),
          )
          .toList(),
      strokeColor: (json['strokeColor'] as String).toColor(),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      fillColor: json['fillColor'] != null
          ? (json['fillColor'] as String).toColor()
          : null,
      fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 0.3,
      isClosed: json['isClosed'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'polygon',
    'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    'strokeColor': strokeColor.toHex(),
    'strokeWidth': strokeWidth,
    'fillColor': fillColor?.toHex(),
    'fillOpacity': fillOpacity,
    'isClosed': isClosed,
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
    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(10);
  }

  @override
  bool containsPoint(Offset point) => boundingBox.contains(point);

  @override
  PolygonElement copyWith() => PolygonElement(
    id: id,
    layerOrder: layerOrder,
    isSelected: isSelected,
    points: List.from(points),
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
    fillColor: fillColor,
    fillOpacity: fillOpacity,
    isClosed: isClosed,
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

  factory TextElement.fromJson(Map<String, dynamic> json) {
    return TextElement(
      id: json['id'] as String?,
      layerOrder: json['layerOrder'] as int? ?? 0,
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      text: json['text'] as String,
      textColor: (json['textColor'] as String).toColor(),
      fontSize: (json['fontSize'] as num).toDouble(),
      fontWeight: FontWeight.values[json['fontWeight'] as int? ?? 6],
      hasBackground: json['hasBackground'] as bool? ?? true,
      backgroundColor: json['backgroundColor'] != null
          ? (json['backgroundColor'] as String).toColor()
          : null,
    );
  }

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

  @override
  Rect get boundingBox {
    final width = text.length * fontSize * 0.6;
    final height = fontSize * 1.5;
    return Rect.fromLTWH(position.dx, position.dy, width, height).inflate(5);
  }

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

  factory EquipmentElement.fromJson(Map<String, dynamic> json) {
    return EquipmentElement(
      id: json['id'] as String?,
      layerOrder: json['layerOrder'] as int? ?? 0,
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      equipmentType: DrawingTool.values.firstWhere(
        (e) => e.name == json['equipmentType'],
        orElse: () => DrawingTool.cone,
      ),
      color: (json['color'] as String).toColor(),
      size: (json['size'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

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
  Rect get boundingBox =>
      Rect.fromCenter(center: position, width: size + 10, height: size + 10);

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
