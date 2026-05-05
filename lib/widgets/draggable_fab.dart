import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/solar_icons.dart';

/// Draggable FAB that expands from a pill into an action bar.
/// Matches #fab-wrap in the HTML prototype.
///
/// Closed: 48×48 dark circle with a "+" icon
/// Open:   pill expands horizontally revealing action icon buttons
///         The "+" rotates 45° to become "×"
///
/// Draggable anywhere on screen; snap stays within safe bounds.
class DraggableFab extends StatefulWidget {
  final VoidCallback? onAddMessage;
  final VoidCallback? onAddNote;

  const DraggableFab({
    super.key,
    this.onAddMessage,
    this.onAddNote,
  });

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab>
    with SingleTickerProviderStateMixin {
  // --- Constants ---
  static const double _btnSize = 48.0;
  static const double _safeGap = 20.0;
  static const double _actionBtnSize = 40.0;
  static const double _panelItemGap = 2.0;

  // Number of action buttons (message + note)
  static const int _numActions = 2;
  // Expanded pill width = btnSize + gap + numActions * (actionBtnSize + gap) + padding
  static const double _expandedWidth =
      _btnSize + (_actionBtnSize + _panelItemGap) * _numActions + 16;

  // --- State ---
  late AnimationController _ctrl;
  late Animation<double> _expandAnim; // 0→1 pill expansion
  late Animation<double> _panelOpacity;
  late Animation<double> _panelScale;
  late Animation<double> _iconRotation; // + → ×

  // Action button stagger animations
  late List<Animation<double>> _itemAnims;

  bool _isOpen = false;
  bool _openRight = true; // panel opens to the right of the button

  // Position (bottom-left anchor of FAB)
  late Offset _anchor;
  bool _positionInitialized = false;

  // Drag state
  bool _isDragging = false;
  Offset _dragStartLocal = Offset.zero;
  Offset _anchorAtDragStart = Offset.zero;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    final curve = CurvedAnimation(
      parent: _ctrl,
      curve: const Cubic(0.32, 0.72, 0.20, 1.0),
    );

    _expandAnim = curve;

    _panelOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.06, 1.0, curve: Curves.easeOut),
      ),
    );

    _panelScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.03, 1.0, curve: Cubic(0.32, 0.72, 0.20, 1.0)),
      ),
    );

    _iconRotation = Tween<double>(begin: 0.0, end: 0.125).animate(
      // 0.125 turns = 45°
      CurvedAnimation(
        parent: _ctrl,
        curve: const Cubic(0.32, 0.72, 0.20, 1.0),
      ),
    );

    // Stagger animations for each action button
    _itemAnims = List.generate(_numActions, (i) {
      final start = 0.04 + i * 0.04;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, (start + 0.36).clamp(0.0, 1.0),
              curve: const Cubic(0.32, 0.72, 0.20, 1.0)),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _initPosition(Size screenSize) {
    if (_positionInitialized) return;
    _positionInitialized = true;
    // Default: bottom-left, matching HTML default
    _anchor = Offset(
      _safeGap,
      screenSize.height - _safeGap - _btnSize - MediaQuery.of(context).padding.bottom,
    );
  }

  void _toggleOpen() {
    HapticFeedback.lightImpact();
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _closeIfOpen() {
    if (_isOpen) {
      _isOpen = false;
      _ctrl.reverse();
    }
  }

  void _clampPosition(Size size) {
    final maxX = size.width - _safeGap - _btnSize;
    final maxY = size.height - _safeGap - _btnSize - MediaQuery.of(context).padding.bottom;
    _anchor = Offset(
      _anchor.dx.clamp(_safeGap, maxX),
      _anchor.dy.clamp(_safeGap + MediaQuery.of(context).padding.top + 60, maxY),
    );
    // Decide opening direction based on available space
    _openRight = (_anchor.dx + _expandedWidth) < size.width - _safeGap;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    _initPosition(screenSize);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // Current pill width: lerp between closed (48) and open (expanded)
        final currentWidth =
            _btnSize + (_expandedWidth - _btnSize) * _expandAnim.value;

        // Position the pill: if opening right, anchor stays at _anchor.dx
        // If opening left, the right edge stays fixed
        final left = _openRight
            ? _anchor.dx
            : _anchor.dx + _btnSize - currentWidth;

        return Positioned(
          left: left,
          top: _anchor.dy,
          child: GestureDetector(
            // Drag handling on the FAB button itself
            onPanStart: (details) {
              _isDragging = false;
              _dragStartLocal = details.globalPosition;
              _anchorAtDragStart = _anchor;
              _closeIfOpen();
            },
            onPanUpdate: (details) {
              final delta = details.globalPosition - _dragStartLocal;
              if (!_isDragging && (delta.distance > 6)) {
                _isDragging = true;
                HapticFeedback.selectionClick();
              }
              if (_isDragging) {
                setState(() {
                  _anchor = _anchorAtDragStart + delta;
                  _clampPosition(screenSize);
                });
              }
            },
            onPanEnd: (_) {
              if (!_isDragging) {
                // It was a tap
                _toggleOpen();
              }
              _isDragging = false;
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Pill background ──────────────────────────────────
                _PillBackground(
                  width: currentWidth,
                  height: _btnSize,
                ),

                // ── Action buttons panel ─────────────────────────────
                Positioned(
                  top: (_btnSize - _actionBtnSize) / 2,
                  left: _openRight ? _btnSize + 4 : 0,
                  right: _openRight ? 0 : _btnSize + 4,
                  child: Opacity(
                    opacity: _panelOpacity.value,
                    child: Transform.scale(
                      scale: _panelScale.value,
                      alignment:
                          _openRight ? Alignment.centerLeft : Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: _openRight
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        children: [
                          _ActionBtn(
                            anim: _itemAnims[0],
                            icon: SolarIcons.chatRound,
                            color: AppColors.accent,
                            tooltip: 'Сообщение',
                            onTap: () {
                              _closeIfOpen();
                              widget.onAddMessage?.call();
                            },
                          ),
                          SizedBox(width: _panelItemGap),
                          _ActionBtn(
                            anim: _itemAnims[1],
                            icon: SolarIcons.notes,
                            color: AppColors.accent5,
                            tooltip: 'Заметка',
                            onTap: () {
                              _closeIfOpen();
                              widget.onAddNote?.call();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Plus / Close button ──────────────────────────────
                Positioned(
                  left: _openRight ? 0 : currentWidth - _btnSize,
                  top: 0,
                  child: SizedBox(
                    width: _btnSize,
                    height: _btnSize,
                    child: Center(
                      child: RotationTransition(
                        turns: _iconRotation,
                        child: _PlusIcon(isOpen: _isOpen),
                      ),
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

/// Dark glass pill background using BackdropFilter
class _PillBackground extends StatelessWidget {
  final double width;
  final double height;

  const _PillBackground({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF161616).withOpacity(0.94),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              // Inner top highlight (glass effect)
              BoxShadow(
                color: Colors.white.withOpacity(0.04),
                blurRadius: 0,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated "+" / "×" icon
class _PlusIcon extends StatelessWidget {
  final bool isOpen;

  const _PlusIcon({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _PlusPainter(
          color: Colors.white.withOpacity(0.92),
        ),
      ),
    );
  }
}

class _PlusPainter extends CustomPainter {
  final Color color;

  const _PlusPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = size.width * 0.44;

    // Horizontal bar
    canvas.drawLine(
      Offset(cx - half, cy),
      Offset(cx + half, cy),
      paint,
    );
    // Vertical bar
    canvas.drawLine(
      Offset(cx, cy - half),
      Offset(cx, cy + half),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PlusPainter old) => old.color != color;
}

/// Single action button inside the FAB panel
class _ActionBtn extends StatefulWidget {
  final Animation<double> anim;
  final String icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.anim,
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.anim,
      builder: (context, child) {
        return Opacity(
          opacity: widget.anim.value,
          child: Transform.scale(
            scale: 0.6 + 0.4 * widget.anim.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            width: _DraggableFabState._actionBtnSize,
            height: _DraggableFabState._actionBtnSize,
            child: Center(
              child: SvgPicture.string(
                widget.icon,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
