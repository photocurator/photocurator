import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';

//뒤로가기 아이콘...svg가 안 되길래 그냥 그림..
class BackIcon extends StatelessWidget {
  final double barHeight;

  const BackIcon({
    super.key,
    required this.barHeight,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidth = barHeight * (10 / 50);
    final iconHeight = barHeight * (20 / 50);

    return CustomPaint(
      size: Size(iconWidth, iconHeight),
      painter: _BackPainter(barHeight),
    );
  }
}

class _BackPainter extends CustomPainter {
  final double barHeight;

  _BackPainter(this.barHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = barHeight * (1.7 / 50);

    final paint = Paint()
      ..color = AppColors.dg1C1F23
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.9, size.height * 0.1)
      ..lineTo(size.width * 0.1, size.height * 0.5)
      ..lineTo(size.width * 0.9, size.height * 0.9);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
