import 'package:flutter/material.dart';

/// The paid-tier crown, painted rather than fetched from an icon font.
///
/// Neither icon package could supply it on this SDK: Flutter made [IconData] a
/// `final class`, and both `phosphor_flutter` 2.1.0 and `font_awesome_flutter`
/// 10.12.0 do `class XIconData extends IconData`, so importing either fails to
/// compile. (`iconly` survives only because it declares a pre-Dart-3 language
/// version, which exempts it from the class modifier.) Material has no crown —
/// `workspace_premium` is a rosette — and there is no SVG package here.
///
/// Painting it is ~30 lines, adds no dependency, and stays crisp at the 11px the
/// collapsed sidebar rail needs, where a font glyph would turn to mud.
class CrownIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CrownIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CrownPainter(color)),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final Color color;

  const _CrownPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Five-point crown in a normalised 0..1 box, so it scales exactly.
    final crown = Path()
      ..moveTo(w * 0.04, h * 0.28) // left spike
      ..lineTo(w * 0.27, h * 0.54)
      ..lineTo(w * 0.50, h * 0.16) // centre spike
      ..lineTo(w * 0.73, h * 0.54)
      ..lineTo(w * 0.96, h * 0.28) // right spike
      ..lineTo(w * 0.88, h * 0.72)
      ..lineTo(w * 0.12, h * 0.72)
      ..close();
    canvas.drawPath(crown, paint);

    // Band. Drawn separately with a gap above it so the silhouette still reads
    // as a crown when the whole thing is 11px wide.
    final band = RRect.fromLTRBR(
      w * 0.12,
      h * 0.78,
      w * 0.88,
      h * 0.94,
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(band, paint);
  }

  @override
  bool shouldRepaint(_CrownPainter oldDelegate) => oldDelegate.color != color;
}
