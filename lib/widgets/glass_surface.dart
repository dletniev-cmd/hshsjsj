import 'dart:ui';
import 'package:flutter/material.dart';

/// iOS-style liquid glass surface widget.
/// Uses BackdropFilter + semi-transparent dark container
/// with gradient border and inner highlight for the glass look.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double blurSigma;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 999,
    this.padding,
    this.color,
    this.blurSigma = 18,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? const Color(0xFF282828).withOpacity(0.82),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: Colors.white.withOpacity(0.10),
                  width: 1,
                ),
            boxShadow: boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glass pill button — matches .tb-btn in HTML
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double height;
  final double? minWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool isPrimary;

  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.height = 40,
    this.minWidth,
    this.padding,
    this.backgroundColor,
    this.isPrimary = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Cubic(0.2, 0.8, 0.2, 1),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: widget.height,
              constraints: BoxConstraints(
                minWidth: widget.minWidth ?? widget.height,
              ),
              padding: widget.padding ??
                  EdgeInsets.symmetric(
                    horizontal: widget.minWidth == widget.height ? 0 : 14,
                  ),
              decoration: BoxDecoration(
                color: widget.isPrimary
                    ? const Color(0xFF8774E1)
                    : (widget.backgroundColor ??
                        const Color(0xFF282828).withOpacity(0.82)),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white
                      .withOpacity(widget.isPrimary ? 0.18 : 0.10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isPrimary
                        ? const Color(0xFF8774E1).withOpacity(0.45)
                        : Colors.black.withOpacity(0.30),
                    blurRadius: widget.isPrimary ? 22 : 18,
                    offset: const Offset(0, widget.isPrimary ? 8 : 6),
                  ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
