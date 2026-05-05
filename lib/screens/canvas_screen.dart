import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/grid_painter.dart';
import '../widgets/top_bar.dart';
import '../widgets/draggable_fab.dart';

/// The main canvas screen — pannable dot-grid canvas with floating UI.
class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen>
    with TickerProviderStateMixin {
  // Pan + zoom state
  Offset _canvasOffset = Offset.zero;
  double _canvasScale = 1.0;

  // Gesture tracking for pan
  Offset _panStart = Offset.zero;
  Offset _offsetAtPanStart = Offset.zero;

  // Pinch
  double _scaleStart = 1.0;
  double _scaleAtPinchStart = 1.0;

  // Nodes on canvas
  final List<_CanvasNode> _nodes = [];

  // Toast
  OverlayEntry? _toastEntry;

  // Zoom label visibility
  late AnimationController _zoomLabelCtrl;
  late Animation<double> _zoomLabelOpacity;

  @override
  void initState() {
    super.initState();

    _zoomLabelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _zoomLabelOpacity = CurvedAnimation(
      parent: _zoomLabelCtrl,
      curve: Curves.easeOut,
    );

    // Seed demo nodes to make canvas look alive
    _seedDemoNodes();
  }

  @override
  void dispose() {
    _zoomLabelCtrl.dispose();
    super.dispose();
  }

  void _seedDemoNodes() {
    final rng = math.Random(42);
    final types = [NodeType.start, NodeType.message, NodeType.input, NodeType.timer];
    final labels = ['Start', 'Welcome message', 'Wait for input', 'Delay 3s'];
    for (int i = 0; i < 4; i++) {
      _nodes.add(_CanvasNode(
        id: 'n$i',
        type: types[i],
        title: labels[i],
        body: i == 1
            ? 'Hello! How can I help you today?'
            : i == 2
                ? 'Please type your answer below.'
                : '',
        position: Offset(
          80.0 + rng.nextDouble() * 200,
          120.0 + i * 180.0 + rng.nextDouble() * 40,
        ),
      ));
    }
  }

  // ── Canvas transform helpers ────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails d) {
    _panStart = d.focalPoint;
    _offsetAtPanStart = _canvasOffset;
    _scaleAtPinchStart = _canvasScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      // Pan
      _canvasOffset = _offsetAtPanStart + (d.focalPoint - _panStart);

      // Pinch-zoom
      if (d.scale != 1.0) {
        final newScale = (_scaleAtPinchStart * d.scale).clamp(0.25, 3.0);
        // Zoom toward focal point
        final focalCanvas = (d.focalPoint - _canvasOffset) / _canvasScale;
        _canvasScale = newScale;
        _canvasOffset = d.focalPoint - focalCanvas * _canvasScale;
        _showZoomLabel();
      }
    });
  }

  void _showZoomLabel() {
    _zoomLabelCtrl.forward(from: 0.0);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _zoomLabelCtrl.reverse();
    });
  }

  // ── Node management ─────────────────────────────────────────────────────────

  void _addNode(NodeType type) {
    final screenSize = MediaQuery.of(context).size;
    // Place near center of visible canvas
    final centerScreen = Offset(screenSize.width / 2, screenSize.height / 2);
    final canvasCenter = (centerScreen - _canvasOffset) / _canvasScale;

    setState(() {
      _nodes.add(_CanvasNode(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        title: type == NodeType.message ? 'Message' : 'Note',
        body: '',
        position: canvasCenter +
            Offset(
              (math.Random().nextDouble() - 0.5) * 60,
              (math.Random().nextDouble() - 0.5) * 60,
            ),
      ));
    });

    HapticFeedback.mediumImpact();
    _showToast(type == NodeType.message ? '💬 Message node added' : '📝 Note added');
  }

  void _showToast(String message) {
    _toastEntry?.remove();
    _toastEntry = null;

    final entry = OverlayEntry(
      builder: (_) => _Toast(message: message),
    );
    _toastEntry = entry;
    Overlay.of(context).insert(entry);

    Future.delayed(const Duration(milliseconds: 2200), () {
      entry.remove();
      if (_toastEntry == entry) _toastEntry = null;
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Canvas layer (grid + nodes) ──────────────────────────────
          GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  // Dot-grid background
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: GridPainter(
                        offset: _canvasOffset,
                        scale: _canvasScale,
                      ),
                      size: size,
                    ),
                  ),

                  // Canvas items (nodes)
                  ..._nodes.map((node) => _buildNode(node)),
                ],
              ),
            ),
          ),

          // ── Top gradient veil + TopBar ──────────────────────────────
          TopBar(
            nodeCount: _nodes.length,
            onLayersTap: () => _showToast('📚 Layers'),
            onExportTap: () => _showToast('📤 Export'),
          ),

          // ── Zoom label ────────────────────────────────────────────────
          Positioned(
            bottom: bottom + 86,
            right: 12,
            child: FadeTransition(
              opacity: _zoomLabelOpacity,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(_canvasScale * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),

          // ── Draggable FAB ────────────────────────────────────────────
          DraggableFab(
            onAddMessage: () => _addNode(NodeType.message),
            onAddNote: () => _addNode(NodeType.comment),
          ),
        ],
      ),
    );
  }

  // ── Node rendering ──────────────────────────────────────────────────────────

  Widget _buildNode(_CanvasNode node) {
    // Transform position from canvas space to screen space
    final screenPos = _canvasOffset + node.position * _canvasScale;

    return Positioned(
      left: screenPos.dx,
      top: screenPos.dy,
      child: Transform.scale(
        scale: _canvasScale,
        alignment: Alignment.topLeft,
        child: _NodeCard(
          node: node,
          onDragUpdate: (delta) {
            setState(() {
              node.position += delta / _canvasScale;
            });
          },
        ),
      ),
    );
  }
}

// ─── Node data model ────────────────────────────────────────────────────────

enum NodeType { start, message, input, timer, comment }

class _CanvasNode {
  final String id;
  final NodeType type;
  final String title;
  final String body;
  Offset position;

  _CanvasNode({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.position,
  });
}

// ─── Node Card Widget ────────────────────────────────────────────────────────

class _NodeCard extends StatefulWidget {
  final _CanvasNode node;
  final ValueChanged<Offset>? onDragUpdate;

  const _NodeCard({required this.node, this.onDragUpdate});

  @override
  State<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<_NodeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _appearCtrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  bool _selected = false;

  @override
  void initState() {
    super.initState();
    _appearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _appearCtrl,
        curve: const Cubic(0.34, 1.5, 0.64, 1),
      ),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearCtrl, curve: Curves.easeOut),
    );
    _appearCtrl.forward();
  }

  @override
  void dispose() {
    _appearCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.node.type) {
      case NodeType.start:
        return AppColors.nodeStart;
      case NodeType.message:
        return AppColors.nodeMessage;
      case NodeType.input:
        return AppColors.nodeInput;
      case NodeType.timer:
        return AppColors.nodeTimer;
      case NodeType.comment:
        return AppColors.noteYellow1;
    }
  }

  String get _typeLabel {
    switch (widget.node.type) {
      case NodeType.start:
        return 'START';
      case NodeType.message:
        return 'MESSAGE';
      case NodeType.input:
        return 'INPUT';
      case NodeType.timer:
        return 'TIMER';
      case NodeType.comment:
        return 'NOTE';
    }
  }

  IconData get _typeIcon {
    switch (widget.node.type) {
      case NodeType.start:
        return Icons.bolt_rounded;
      case NodeType.message:
        return Icons.chat_bubble_rounded;
      case NodeType.input:
        return Icons.keyboard_alt_rounded;
      case NodeType.timer:
        return Icons.timer_rounded;
      case NodeType.comment:
        return Icons.sticky_note_2_rounded;
    }
  }

  bool get _isComment => widget.node.type == NodeType.comment;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appearCtrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          alignment: Alignment.topLeft,
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => setState(() => _selected = !_selected),
        onPanUpdate: (d) => widget.onDragUpdate?.call(d.delta),
        child: _isComment ? _buildCommentCard() : _buildRegularCard(),
      ),
    );
  }

  Widget _buildRegularCard() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF1c1d2a),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(_selected ? 0.14 : 0.07),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: _selected ? 32 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon, size: 16, color: _accentColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeLabel,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.node.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          if (widget.node.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                widget.node.body,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.92),
                  height: 1.5,
                ),
              ),
            ),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${widget.node.id}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                // Output connector dot
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1c1d28),
                    border: Border.all(
                      color: AppColors.borderBright,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard() {
    return Transform.rotate(
      angle: -1.8 * math.pi / 180,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(0.0, -1.0),
            end: Alignment(0.6, 1.0),
            colors: [AppColors.noteYellow1, AppColors.noteYellow2],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.40),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.55),
              blurRadius: 0,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sticky_note_2_rounded,
                    size: 16,
                    color: Color(0xFF4a3910),
                  ),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOTE',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xA62a230a),
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Comment',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2a230a),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.node.body.isEmpty ? 'Tap to add note...' : widget.node.body,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: widget.node.body.isEmpty
                    ? const Color(0xFF2a230a).withOpacity(0.40)
                    : const Color(0xFF2a230a).withOpacity(0.88),
                height: 1.5,
                fontStyle: widget.node.body.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Toast overlay ──────────────────────────────────────────────────────────

class _Toast extends StatefulWidget {
  final String message;
  const _Toast({required this.message});

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: bottom + 96,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF1c1d28).withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
