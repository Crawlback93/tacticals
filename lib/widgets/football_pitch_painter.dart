import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

enum FieldStyle { classic, dark, blueprint }

class FootballPitchPainter extends CustomPainter {
  final bool isVertical;
  final FieldStyle fieldStyle;

  FootballPitchPainter({
    required this.isVertical,
    this.fieldStyle = FieldStyle.classic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final margin = size.shortestSide * 0.045;
    final fieldSize = Size(size.width - 2 * margin, size.height - 2 * margin);
    final grassRadius = size.shortestSide * 0.06;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(grassRadius),
    );

    // Style-specific colours
    final Color grassColor;
    final Color lineColor;
    final Color stripeColor;

    switch (fieldStyle) {
      case FieldStyle.classic:
        grassColor = const Color(0xFF3E7C28);
        lineColor = const Color(0xFF9DCCAA);
        stripeColor = Colors.white.withValues(alpha: 0.05);
      case FieldStyle.dark:
        grassColor = const Color(0xFF1A1A2E);
        lineColor = const Color(0xFF00C8E0);
        stripeColor = Colors.white.withValues(alpha: 0.03);
      case FieldStyle.blueprint:
        grassColor = const Color(0xFF0D3B6E);
        lineColor = const Color(0xFFD0E8FF);
        stripeColor = Colors.white.withValues(alpha: 0.04);
    }

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = fieldStyle == FieldStyle.blueprint ? 1.5 : 2.0;

    final grassPaint = Paint()
      ..color = grassColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, grassPaint);

    canvas.save();
    canvas.clipRRect(rrect);

    if (fieldStyle == FieldStyle.classic) {
      _drawGrassTexture(canvas, size);
    }

    if (fieldStyle == FieldStyle.blueprint) {
      _drawBlueprintGrid(canvas, size);
    }

    final stripePaint = Paint()
      ..color = stripeColor
      ..style = PaintingStyle.fill;
    int stripes = 10;
    if (isVertical) {
      double stripeHeight = size.height / stripes;
      for (int i = 0; i < stripes; i += 2) {
        canvas.drawRect(
          Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
          stripePaint,
        );
      }
    } else {
      double stripeWidth = size.width / stripes;
      for (int i = 0; i < stripes; i += 2) {
        canvas.drawRect(
          Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
          stripePaint,
        );
      }
    }

    canvas.restore();

    canvas.save();
    canvas.translate(margin, margin);

    // Outer Boundary
    canvas.drawRect(
      Rect.fromLTWH(0, 0, fieldSize.width, fieldSize.height),
      paint,
    );

    // Corner Arcs
    double cornerRadius = fieldSize.shortestSide * 0.03;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, 0), radius: cornerRadius),
      0,
      math.pi / 2,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(fieldSize.width, 0), radius: cornerRadius),
      math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(fieldSize.width, fieldSize.height),
        radius: cornerRadius,
      ),
      math.pi,
      math.pi / 2,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(0, fieldSize.height),
        radius: cornerRadius,
      ),
      math.pi * 1.5,
      math.pi / 2,
      false,
      paint,
    );

    // Center Line & Circle
    if (isVertical) {
      canvas.drawLine(
        Offset(0, fieldSize.height / 2),
        Offset(fieldSize.width, fieldSize.height / 2),
        paint,
      );
      canvas.drawCircle(
        Offset(fieldSize.width / 2, fieldSize.height / 2),
        fieldSize.width * 0.15,
        paint,
      );
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(fieldSize.width / 2, fieldSize.height / 2),
        4,
        paint,
      );
      canvas.drawCircle(
        Offset(fieldSize.width / 2, fieldSize.height * 0.12),
        4,
        paint,
      );
      canvas.drawCircle(
        Offset(fieldSize.width / 2, fieldSize.height * 0.88),
        4,
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(fieldSize.width / 2, 0),
        Offset(fieldSize.width / 2, fieldSize.height),
        paint,
      );
      canvas.drawCircle(
        Offset(fieldSize.width / 2, fieldSize.height / 2),
        fieldSize.height * 0.15,
        paint,
      );
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(fieldSize.width / 2, fieldSize.height / 2),
        4,
        paint,
      );
      canvas.drawCircle(
        Offset(fieldSize.width * 0.12, fieldSize.height / 2),
        4,
        paint,
      );
      canvas.drawCircle(
        Offset(fieldSize.width * 0.88, fieldSize.height / 2),
        4,
        paint,
      );
    }

    paint.style = PaintingStyle.stroke;

    // Penalty Areas
    if (isVertical) {
      _drawPenaltyAreaVertical(canvas, fieldSize, paint, true);
      _drawPenaltyAreaVertical(canvas, fieldSize, paint, false);
    } else {
      _drawPenaltyAreaHorizontal(canvas, fieldSize, paint, true);
      _drawPenaltyAreaHorizontal(canvas, fieldSize, paint, false);
    }

    _drawGoals(canvas, fieldSize, paint);

    canvas.restore();
  }

  void _drawGoals(Canvas canvas, Size size, Paint paint) {
    double goalWidth = isVertical ? size.width * 0.12 : size.height * 0.12;
    double goalDepth = goalWidth * 0.3;

    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    if (isVertical) {
      double leftX = (size.width - goalWidth) / 2;
      double rightX = (size.width + goalWidth) / 2;

      Path topGoal = Path()
        ..moveTo(leftX, 0)
        ..lineTo(leftX, -goalDepth)
        ..lineTo(rightX, -goalDepth)
        ..lineTo(rightX, 0);
      canvas.drawPath(topGoal, paint);
      _drawGoalNet(
        canvas,
        Rect.fromLTRB(leftX, -goalDepth, rightX, 0),
        goalDepth / 5,
        netPaint,
      );

      Path bottomGoal = Path()
        ..moveTo(leftX, size.height)
        ..lineTo(leftX, size.height + goalDepth)
        ..lineTo(rightX, size.height + goalDepth)
        ..lineTo(rightX, size.height);
      canvas.drawPath(bottomGoal, paint);
      _drawGoalNet(
        canvas,
        Rect.fromLTRB(leftX, size.height, rightX, size.height + goalDepth),
        goalDepth / 5,
        netPaint,
      );
    } else {
      double topY = (size.height - goalWidth) / 2;
      double bottomY = (size.height + goalWidth) / 2;

      Path leftGoal = Path()
        ..moveTo(0, topY)
        ..lineTo(-goalDepth, topY)
        ..lineTo(-goalDepth, bottomY)
        ..lineTo(0, bottomY);
      canvas.drawPath(leftGoal, paint);
      _drawGoalNet(
        canvas,
        Rect.fromLTRB(-goalDepth, topY, 0, bottomY),
        goalDepth / 5,
        netPaint,
      );

      Path rightGoal = Path()
        ..moveTo(size.width, topY)
        ..lineTo(size.width + goalDepth, topY)
        ..lineTo(size.width + goalDepth, bottomY)
        ..lineTo(size.width, bottomY);
      canvas.drawPath(rightGoal, paint);
      _drawGoalNet(
        canvas,
        Rect.fromLTRB(size.width, topY, size.width + goalDepth, bottomY),
        goalDepth / 5,
        netPaint,
      );
    }
  }

  void _drawGoalNet(Canvas canvas, Rect rect, double cellSize, Paint netPaint) {
    double x = rect.left + cellSize;
    while (x < rect.right) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), netPaint);
      x += cellSize;
    }
    double y = rect.top + cellSize;
    while (y < rect.bottom) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), netPaint);
      y += cellSize;
    }
  }

  void _drawPenaltyAreaVertical(
    Canvas canvas,
    Size size,
    Paint paint,
    bool isTop,
  ) {
    double boxWidth = size.width * 0.6;
    double boxHeight = size.height * 0.18;
    double smallBoxWidth = size.width * 0.3;
    double smallBoxHeight = size.height * 0.06;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(
          size.width / 2,
          isTop ? boxHeight / 2 : size.height - boxHeight / 2,
        ),
        width: boxWidth,
        height: boxHeight,
      ),
      paint,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(
          size.width / 2,
          isTop ? smallBoxHeight / 2 : size.height - smallBoxHeight / 2,
        ),
        width: smallBoxWidth,
        height: smallBoxHeight,
      ),
      paint,
    );

    Offset center = Offset(
      size.width / 2,
      isTop ? size.height * 0.12 : size.height * 0.88,
    );
    double radius = size.width * 0.15;
    double lineY = isTop ? boxHeight : size.height - boxHeight;

    double dy = lineY - center.dy;
    double sinTheta = (dy / radius).clamp(-1.0, 1.0);
    double theta = math.asin(sinTheta);

    if (isTop) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        theta,
        math.pi - 2 * theta,
        false,
        paint,
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi - theta,
        math.pi + 2 * theta,
        false,
        paint,
      );
    }
  }

  void _drawPenaltyAreaHorizontal(
    Canvas canvas,
    Size size,
    Paint paint,
    bool isLeft,
  ) {
    double boxHeight = size.height * 0.6;
    double boxWidth = size.width * 0.18;
    double smallBoxHeight = size.height * 0.3;
    double smallBoxWidth = size.width * 0.06;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(
          isLeft ? boxWidth / 2 : size.width - boxWidth / 2,
          size.height / 2,
        ),
        width: boxWidth,
        height: boxHeight,
      ),
      paint,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(
          isLeft ? smallBoxWidth / 2 : size.width - smallBoxWidth / 2,
          size.height / 2,
        ),
        width: smallBoxWidth,
        height: smallBoxHeight,
      ),
      paint,
    );

    Offset center = Offset(
      isLeft ? size.width * 0.12 : size.width * 0.88,
      size.height / 2,
    );
    double radius = size.height * 0.15;
    double lineX = isLeft ? boxWidth : size.width - boxWidth;

    double dx = lineX - center.dx;
    double cosTheta = (dx / radius).clamp(-1.0, 1.0);
    double theta = math.acos(cosTheta);

    if (isLeft) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -theta,
        2 * theta,
        false,
        paint,
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        theta,
        2 * (math.pi - theta),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FootballPitchPainter oldDelegate) =>
      oldDelegate.isVertical != isVertical ||
      oldDelegate.fieldStyle != fieldStyle;

  void _drawGrassTexture(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..strokeWidth = 1.5;

    final List<Offset> darkPoints = [];
    final List<Offset> lightPoints = [];

    int count = (size.width * size.height / 40).round().clamp(500, 10000);

    for (int i = 0; i < count; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      if (random.nextBool()) {
        darkPoints.add(Offset(x, y));
      } else {
        lightPoints.add(Offset(x, y));
      }
    }

    paint.color = Colors.black.withValues(alpha: 0.08);
    canvas.drawPoints(ui.PointMode.points, darkPoints, paint);

    paint.color = Colors.white.withValues(alpha: 0.08);
    canvas.drawPoints(ui.PointMode.points, lightPoints, paint);
  }

  void _drawBlueprintGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }
}
