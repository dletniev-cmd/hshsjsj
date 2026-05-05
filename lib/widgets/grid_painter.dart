import 'package:flutter/material.dart';

/// Draws the dot-grid canvas background matching the HTML prototype.
/// Dots: 1.2px radius, very dark (#1a1a1a), spaced 28px apart.
/// The grid scrolls with the canvas offset.
class GridPainter extends CustomPainter {
  final Offset offset;
  final double scale;
  final double dotSpacing;

  const GridPainter({
    required this.offset,
    required this.scale,
    this.dotSpacing = 28.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..style = PaintingStyle.fill;

    // Effective spacing at current zoom
    final spacing = dotSpacing * scale;

    // Compute starting dot positions considering pan offset
    final offsetX = offset.dx % spacing;
    final offsetY = offset.dy % spacing;

    final startX = offsetX <= 0 ? offsetX : offsetX - spacing;
    final startY = offsetY <= 0 ? offsetY : offsetY - spacing;

    double x = startX;
    while (x < size.width + spacing) {
      double y = startY;
      while (y < size.height + spacing) {
        // Dot size scales with zoom but clamped
        final radius = (1.2 * scale).clamp(0.6, 2.4);
        canvas.drawCircle(Offset(x, y), radius, paint);
        y += spacing;
      }
      x += spacing;
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.scale != scale;
  }
}
