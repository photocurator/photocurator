import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';

//세션 바 ui 구현
class SessionBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const SessionBar({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : super(key: key);

  static const List<String> tabs = ["하이라이트", "좋아요", "날짜", "등급", "주제", "세팅"]; // 고정 탭 이름

  // 탭 아이템 빌드 함수
  Widget buildTabItem({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    required double fontSize,
    required String fontFamily,
    required Color circleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 수직 가운데 정렬
        children: [
          Transform.translate(
            offset: const Offset(0, -1), // y축 -1 → 위로 1픽셀
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(height: 2), // 원과 텍스트 간 간격
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    color: color,
                    fontSize: fontSize,
                    letterSpacing: 0, // 자간 0으로 설정
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barHeight = screenWidth * (54 / 375); // 반응형 높이

    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: barHeight,
            color: AppColors.wh1,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20), // 화면 좌우 패딩
              itemCount: tabs.length,
              separatorBuilder: (_, __) => SizedBox(width: 30), // 아이템 간격
              itemBuilder: (context, index) {
                final isSelected = index == selectedIndex;

                // 색상 결정 로직
                Color textColor;
                if (index == 0) {
                  textColor = AppColors.primary;
                } else if (index == 1) {
                  textColor = AppColors.secondary;
                } else {
                  textColor = isSelected ? AppColors.dg1C1F23 : AppColors.lgADB5BD;
                }

                return buildTabItem(
                  text: tabs[index],
                  isSelected: isSelected,
                  onTap: () => onTabSelected(index),
                  color: textColor,
                  fontSize: barHeight * (14 / 54),
                  fontFamily: 'NotoSansRegular', //isSelected ? 'NotoSansMedium' : 'NotoSansRegular',
                  //왜????? 굵기가 변경이 안 될까??? 도대체 왜????
                  //추후 한글 전용 폰트인 notosansKR 받아서 해결할 것.
                  circleColor: textColor.withOpacity(isSelected ? 1.0 : 0.0),
                );
              },
            ),
          ),
          Container(
            height: 1,
            color: AppColors.lgE9ECEF,
          ),
        ],
      ),
    );
  }
}
