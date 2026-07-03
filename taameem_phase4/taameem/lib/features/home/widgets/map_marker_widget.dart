import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class MapMarkerWidget extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;

  const MapMarkerWidget({
    super.key,
    required this.color,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── الدبوس الرئيسي ─────────────────────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.nearBlack : Colors.white,
                width: isSelected ? 2.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: isSelected ? 16 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: _getTextColor(color),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // ─── مثلث أسفل الدبوس ──────────────────────────────────────────
          CustomPaint(
            size: const Size(12, 6),
            painter: _MarkerTrianglePainter(color: color),
          ),
        ],
      ),
    );
  }

  Color _getTextColor(Color bgColor) {
    // اختر لون النص (أسود أو أبيض) بناءً على سطوع اللون
    final luminance = bgColor.computeLuminance();
    return luminance > 0.4 ? AppColors.nearBlack : AppColors.white;
  }
}

class _MarkerTrianglePainter extends CustomPainter {
  final Color color;
  const _MarkerTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MarkerTrianglePainter old) => old.color != color;
}
