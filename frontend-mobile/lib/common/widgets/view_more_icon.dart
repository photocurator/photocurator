import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';

//더보기 아이콘 ui
class MoreIcon extends StatelessWidget {
  final double totalHeight; // 전체 높이
  final double dotDiameter; // 원 하나 크기
  final Color color;

  const MoreIcon({
    Key? key,
    this.totalHeight = 20,
    this.dotDiameter = 4,
    this.color = AppColors.dg1C1F23,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gap = (totalHeight - dotDiameter * 3) / 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotDiameter,
          height: dotDiameter,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(height: gap),
        Container(
          width: dotDiameter,
          height: dotDiameter,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(height: gap),
        Container(
          width: dotDiameter,
          height: dotDiameter,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }
}