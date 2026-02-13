import 'package:flutter/material.dart';
import '../../../shared/models/mindmap.dart';

class MindmapViewerScreen extends StatelessWidget {
  final Mindmap mindmap;

  const MindmapViewerScreen({
    super.key,
    required this.mindmap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(mindmap.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mindmap Viewer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      const _GridBackground(),
                      InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 2.5,
                        boundaryMargin: const EdgeInsets.all(80),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _buildNode(context, mindmap.root, 0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNode(BuildContext context, MindmapNode node, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 24.0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: depth == 0
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: depth == 0
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300]!,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                depth == 0 ? Icons.circle : Icons.label,
                size: 16,
                color: depth == 0
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.text,
                  style: TextStyle(
                    fontWeight: depth == 0 ? FontWeight.bold : FontWeight.normal,
                    fontSize: depth == 0 ? 18 : 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (node.children.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...node.children.map((child) => _buildNode(context, child, depth + 1)),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
