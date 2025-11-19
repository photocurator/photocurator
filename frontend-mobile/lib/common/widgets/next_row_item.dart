import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/widgets/back_icon.dart';

// [string       >]
// 누르면 상세 페이지로 이동하는 row 아이템
// 레이아웃 및 화면 매핑
class NextRowItem extends StatelessWidget {
  final String titleText;
  final VoidCallback? onTap;
  final Color textColor;
  final double baseFontSize; // 텍스트 크기 계산 기준 값

  const NextRowItem({
    super.key,
    required this.titleText, //필수 인자
    this.onTap,
    this.textColor = AppColors.dg1C1F23, //기본 값 검정
    this.baseFontSize = 16.0, // 기본값 16.0 설정
  });

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double widgetHeight = deviceWidth * (50 / 375);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: deviceWidth,
        height: widgetHeight,
        color: AppColors.wh1,

        // ui 호출 전달
        child: _NextRowItemContent(
          titleText: titleText,
          widgetHeight: widgetHeight,
          textColor: textColor,
          baseFontSize: baseFontSize,
        ),
      ),
    );
  }
}

// ui 담당
// private
class _NextRowItemContent extends StatelessWidget {
  final String titleText;
  final double widgetHeight; // 크기 계산을 위해 높이 값을 받음
  final Color textColor;
  final double baseFontSize; // 텍스트 크기 계산 기준 값

  const _NextRowItemContent({
    required this.titleText,
    required this.widgetHeight,
    required this.textColor,
    required this.baseFontSize,
  });

  @override
  Widget build(BuildContext context) {
    // baseFontSize를 사용하여 폰트 크기 계산
    final double fontSize = widgetHeight * (baseFontSize / 50);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // 왼쪽 텍스트
          Text(
            titleText,
            style: TextStyle(
              fontFamily: 'NotoSansRegular',
              fontSize: fontSize, // 계산된 fontSize 사용
              color: textColor,
              letterSpacing: 0,
            ),
          ),
          // 오른쪽 아이콘
          ChevronIcon(barHeight: widgetHeight),
        ],
      ),
    );
  }
}
