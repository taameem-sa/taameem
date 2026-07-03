import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// خلفية الأكوار الضوئية المتحركة (زمردية + ذهبية)
class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<Offset> _orb1;
  late Animation<Offset> _orb2;

  @override
  void initState() {
    super.initState();

    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);

    _orb1 = Tween<Offset>(
      begin: const Offset(-0.2, -0.2),
      end: const Offset(0.3, 0.2),
    ).animate(CurvedAnimation(parent: _controller1, curve: Curves.easeInOut));

    _orb2 = Tween<Offset>(
      begin: const Offset(0.8, 0.6),
      end: const Offset(0.4, 0.9),
    ).animate(CurvedAnimation(parent: _controller2, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // خلفية كريمية
        Container(color: AppColors.creamWhite),

        // شبكة خطوط خفيفة
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _GridPainter(),
        ),

        // كُرة زمردية
        AnimatedBuilder(
          animation: _orb1,
          builder: (_, __) => Positioned(
            left: _orb1.value.dx * size.width,
            top: _orb1.value.dy * size.height,
            child: _Orb(
              size: 280,
              color: AppColors.mint.withValues(alpha: 0.25),
            ),
          ),
        ),

        // كُرة ذهبية
        AnimatedBuilder(
          animation: _orb2,
          builder: (_, __) => Positioned(
            left: _orb2.value.dx * size.width,
            top: _orb2.value.dy * size.height,
            child: _Orb(
              size: 240,
              color: AppColors.gold.withValues(alpha: 0.15),
            ),
          ),
        ),

        // المحتوى فوق الخلفية
        widget.child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
