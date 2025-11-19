import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/widgets/back_icon.dart';

// [string       string]
// 정보 보여주는 row 아이템
// 프로필 설정, 프로젝트 설정, 사진 상세정보 화면에서 사용
class InfoRowItem extends StatelessWidget {
  final String titleText;
  final String infoText;
  final Color textColor;

  const InfoRowItem({
    super.key,
    required this.titleText, //필수 인자
    required this.infoText, //필수 인자
    this.textColor = AppColors.dg495057, //기본 값 진회색 / 옵션 2 : AppColors.dg1C1F23
  });

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double fontSize = deviceWidth * (12 / 375);

    return Container(
      width: deviceWidth,
      height: deviceWidth * (50 / 375),
      color: AppColors.wh1,

      // ui
      child: Padding(
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
                fontSize: fontSize, // 반응형 fontSize 사용
                color: AppColors.dg1C1F23,
                letterSpacing: 0,
              ),
            ),
            // 오른쪽 텍스트
            Text(
              infoText,
              style: TextStyle(
                fontFamily: 'NotoSansRegular',
                fontSize: fontSize, // 반응형 fontSize 사용
                color: textColor,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
