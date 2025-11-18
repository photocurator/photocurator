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


// BackIcon을 좌우 반전
// 다음 페이지로 이동하는 아이콘...chevron
class ChevronIcon extends StatelessWidget {
  final double barHeight;

  const ChevronIcon({
    super.key,
    required this.barHeight,
  });

  @override
  Widget build(BuildContext context) {
    // BackIcon과 동일한 크기 계산 로직 사용
    final iconWidth = barHeight * (8 / 50);
    final iconHeight = barHeight * (16 / 50);

    return CustomPaint(
      size: Size(iconWidth, iconHeight),
      // 반전된 CustomPainter 사용
      painter: _NextPainter(barHeight),
    );
  }
}

class _NextPainter extends CustomPainter {
  final double barHeight;

  _NextPainter(this.barHeight);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 캔버스를 좌우 반전시키기 위한 변환 적용

    // 1-1. X축을 기준으로 -1 배 스케일 (좌우 반전)
    // canvas.scale(-1.0, 1.0);

    // 1-2. X축 방향으로 캔버스 너비만큼 이동 (반전 후 원래 위치로 되돌리기)
    // canvas.translate(-size.width, 0);

    // ** 두 변환을 합쳐서 한 번에 실행 **
    canvas.translate(size.width, 0);
    canvas.scale(-1.0, 1.0);

    // 2. _BackPainter의 로직 그대로 사용
    final strokeWidth = barHeight * (1.7 / 50);

    final paint = Paint()
      ..color = AppColors.lgADB5BD
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