import 'dart:math';
import 'package:flutter/material.dart';
import '../../../shared/models/mindmap.dart';

// ── colour palette per depth level ──────────────────────────────────────────
const _kDepthColors = [
  Color(0xFF7C5CBF), // root – deep purple
  Color(0xFF4A90D9), // level 1 – sky blue
  Color(0xFF27AE8F), // level 2 – teal
  Color(0xFFE67E40), // level 3 – warm orange
  Color(0xFFE84393), // level 4 – pink
  Color(0xFF8BC34A), // level 5 – lime
];

const double _kNodeW = 148.0;
const double _kNodeH = 48.0;
const double _kLevelGap = 88.0; // vertical gap between depth levels
const double _kSibGap = 20.0; // horizontal gap between siblings
const double _kHPad = 24.0; // canvas horizontal padding

Color _colorAt(int depth) => _kDepthColors[depth % _kDepthColors.length];

// ── layout algorithm ────────────────────────────────────────────────────────

class _LayoutResult {
  final Map<String, Offset> positions; // node id → top-left corner
  final double totalWidth;
  final double totalHeight;
  _LayoutResult(this.positions, this.totalWidth, this.totalHeight);
}

double _measureWidth(MindmapNode node) {
  if (node.children.isEmpty) return _kNodeW;
  final childrenW = node.children.fold<double>(
        0,
        (sum, c) => sum + _measureWidth(c),
      ) +
      max(0, node.children.length - 1) * _kSibGap;
  return max(_kNodeW, childrenW);
}

/// Returns the total width consumed and fills [positions] with each node's
/// top-left offset.
double _assignPositions(
  MindmapNode node,
  int depth,
  double startX,
  Map<String, Offset> positions,
) {
  final subtreeW = _measureWidth(node);
  final nodeX = startX + (subtreeW - _kNodeW) / 2;
  final nodeY = depth * (_kNodeH + _kLevelGap);
  positions[node.id] = Offset(nodeX, nodeY);

  if (node.children.isNotEmpty) {
    final totalChildW =
        node.children.fold<double>(0, (s, c) => s + _measureWidth(c)) +
            max(0, node.children.length - 1) * _kSibGap;
    double childX = startX + (subtreeW - totalChildW) / 2;
    for (final child in node.children) {
      _assignPositions(child, depth + 1, childX, positions);
      childX += _measureWidth(child) + _kSibGap;
    }
  }
  return subtreeW;
}

_LayoutResult _buildLayout(MindmapNode root) {
  final positions = <String, Offset>{};
  final totalW = _assignPositions(root, 0, _kHPad, positions);

  // Compute max depth
  int maxDepth = 0;
  void calcDepth(MindmapNode n, int d) {
    if (d > maxDepth) maxDepth = d;
    for (final c in n.children) {
      calcDepth(c, d + 1);
    }
  }

  calcDepth(root, 0);
  final totalH = (maxDepth + 1) * (_kNodeH + _kLevelGap);

  return _LayoutResult(positions, totalW + _kHPad * 2, totalH + _kHPad);
}

// ── custom painter (lines) ───────────────────────────────────────────────────

class _TreeLinesPainter extends CustomPainter {
  final MindmapNode root;
  final Map<String, Offset> positions;

  _TreeLinesPainter({required this.root, required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    _drawLines(canvas, root, 0);
  }

  void _drawLines(Canvas canvas, MindmapNode node, int depth) {
    final parentPos = positions[node.id];
    if (parentPos == null) return;

    final parentCenter = Offset(
      parentPos.dx + _kNodeW / 2,
      parentPos.dy + _kNodeH,
    );

    for (final child in node.children) {
      final childPos = positions[child.id];
      if (childPos == null) continue;

      final childCenter = Offset(childPos.dx + _kNodeW / 2, childPos.dy);

      final paint = Paint()
        ..color = _colorAt(depth + 1).withOpacity(0.55)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(parentCenter.dx, parentCenter.dy);
      path.cubicTo(
        parentCenter.dx,
        parentCenter.dy + (_kLevelGap * 0.5),
        childCenter.dx,
        childCenter.dy - (_kLevelGap * 0.5),
        childCenter.dx,
        childCenter.dy,
      );
      canvas.drawPath(path, paint);

      _drawLines(canvas, child, depth + 1);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── main screen ─────────────────────────────────────────────────────────────

class MindmapViewerScreen extends StatefulWidget {
  final Mindmap mindmap;

  const MindmapViewerScreen({super.key, required this.mindmap});

  @override
  State<MindmapViewerScreen> createState() => _MindmapViewerScreenState();
}

class _MindmapViewerScreenState extends State<MindmapViewerScreen> {
  late final _LayoutResult _layout;
  final _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _layout = _buildLayout(widget.mindmap.root);
    // Start slightly zoomed-out so the tree fits comfortably
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final screenW = MediaQuery.of(context).size.width;
      final scale = (screenW / (_layout.totalWidth)).clamp(0.4, 1.0);
      _transformController.value = Matrix4.identity()..scale(scale);
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mindmap.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const Text(
              'Pinch to zoom · Drag to pan',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fit_screen_rounded, color: Colors.white70),
            tooltip: 'Reset zoom',
            onPressed: () {
              _transformController.value = Matrix4.identity();
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformController,
        minScale: 0.2,
        maxScale: 3.0,
        boundaryMargin: const EdgeInsets.all(200),
        child: SizedBox(
          width: _layout.totalWidth,
          height: _layout.totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Grid background
              Positioned.fill(child: const _DotGrid()),
              // Lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _TreeLinesPainter(
                    root: widget.mindmap.root,
                    positions: _layout.positions,
                  ),
                ),
              ),
              // Nodes
              ..._buildNodeWidgets(widget.mindmap.root, 0),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNodeWidgets(MindmapNode node, int depth) {
    final pos = _layout.positions[node.id];
    if (pos == null) return [];

    final color = _colorAt(depth);
    final isRoot = depth == 0;

    final widgets = <Widget>[
      Positioned(
        left: pos.dx,
        top: pos.dy,
        child: _NodeCard(
          text: node.text,
          color: color,
          isRoot: isRoot,
          width: _kNodeW,
          height: _kNodeH,
        ),
      ),
    ];

    for (final child in node.children) {
      widgets.addAll(_buildNodeWidgets(child, depth + 1));
    }

    return widgets;
  }
}

// ── node card widget ─────────────────────────────────────────────────────────

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.text,
    required this.color,
    required this.isRoot,
    required this.width,
    required this.height,
  });

  final String text;
  final Color color;
  final bool isRoot;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isRoot ? color : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(isRoot ? 20 : 14),
        border: Border.all(color: color, width: isRoot ? 0 : 1.6),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isRoot ? 0.45 : 0.2),
            blurRadius: isRoot ? 18 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isRoot ? Colors.white : color.withOpacity(0.95),
          fontWeight: isRoot ? FontWeight.w800 : FontWeight.w600,
          fontSize: isRoot ? 14 : 12,
          height: 1.3,
        ),
      ),
    );
  }
}

// ── dot-grid background ──────────────────────────────────────────────────────

class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotGridPainter());
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 28.0;
    final paint = Paint()
      ..color = const Color(0xFF2A2A3E)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
