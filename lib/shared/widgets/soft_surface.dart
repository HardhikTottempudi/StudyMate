import 'package:flutter/material.dart';

const studyInk = Color(0xFF303032);
const studyMuted = Color(0xFF68666C);
const studyAccent = Color(0xFFAC482C);

class SoftBackdrop extends StatelessWidget {
  const SoftBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8E7E6), Color(0xFFE8E5E7), Color(0xFFE8DCE8)],
          stops: [0, .62, 1],
        )),
        child: child,
      );
}

/// Translucent surfaces without a costly live blur on every scrolling card.
class SoftSurface extends StatelessWidget {
  const SoftSurface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.radius = 28});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0x85FFFFFF),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xEFFFFFFF), width: 1.3),
        ),
        child: Material(type: MaterialType.transparency, child: child),
      );
}

class StudyOrb extends StatelessWidget {
  const StudyOrb({super.key, this.size = 38});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
          child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              center: Alignment(-.45, -.5),
              radius: 1,
              colors: [
                Color(0xFFFFE9C7),
                Color(0xFFFFBAAD),
                Color(0xFFE786A7),
                Color(0xFFE66F41)
              ],
              stops: [
                0,
                .4,
                .7,
                1
              ]),
          boxShadow: [
            BoxShadow(
                color: Color(0x20C56FAD), blurRadius: 22, offset: Offset(0, 9))
          ],
        ),
      ));
}

enum DreamPalette { dawn, meadow, lilac }

class DreamArtwork extends StatelessWidget {
  const DreamArtwork({super.key, this.palette = DreamPalette.dawn});
  final DreamPalette palette;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
          child: RepaintBoundary(
        child:
            CustomPaint(painter: _DreamPainter(palette), size: Size.infinite),
      ));
}

class _DreamPainter extends CustomPainter {
  const _DreamPainter(this.palette);
  final DreamPalette palette;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = switch (palette) {
      DreamPalette.dawn => const [
          Color(0xFFBCB8E8),
          Color(0xFFEBA8C4),
          Color(0xFFFFD8B9)
        ],
      DreamPalette.meadow => const [
          Color(0xFFEBB8A6),
          Color(0xFFBAD8AC),
          Color(0xFFF7E6BF)
        ],
      DreamPalette.lilac => const [
          Color(0xFFAAAEE1),
          Color(0xFFD5B4E5),
          Color(0xFFF7BDAD)
        ],
    };
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors)
              .createShader(rect));
    for (var i = 0; i < 5; i++) {
      final y = size.height * (.12 + i * .115);
      final path = Path()
        ..moveTo(-size.width * .1, y)
        ..cubicTo(size.width * .28, y - size.height * .32, size.width * .53,
            y + size.height * .42, size.width * 1.1, y - size.height * .05)
        ..lineTo(size.width * 1.1, size.height)
        ..lineTo(-size.width * .1, size.height)
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors[(i + 1) % 3].withValues(alpha: .75),
                const Color(0x30FFF7E9)
              ],
            ).createShader(rect));
    }
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00FFFAF7), Color(0x20FFFAF7), Color(0xFFFFFAF7)],
            stops: [0, .4, .98],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _DreamPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class DreamTile extends StatelessWidget {
  const DreamTile(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.palette = DreamPalette.dawn,
      this.large = false});
  final String title, subtitle;
  final VoidCallback onTap;
  final DreamPalette palette;
  final bool large;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 5)),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: Material(
              color: Colors.transparent,
              child: Stack(children: [
                Positioned.fill(child: DreamArtwork(palette: palette)),
                InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: large ? 72 : 36),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(title,
                                            style: TextStyle(
                                                fontSize: large ? 27 : 22,
                                                fontWeight: FontWeight.w600,
                                                color: studyInk,
                                                letterSpacing: -.7)),
                                        const SizedBox(height: 4),
                                        Text(subtitle,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: studyMuted,
                                                height: 1.4)),
                                      ])),
                                  if (large)
                                    const Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: CircleAvatar(
                                            backgroundColor: Colors.white,
                                            radius: 23,
                                            child: Icon(
                                                Icons.north_east_rounded,
                                                color: studyAccent,
                                                size: 21))),
                                ]),
                          ]),
                    )),
              ]),
            )),
      );
}
