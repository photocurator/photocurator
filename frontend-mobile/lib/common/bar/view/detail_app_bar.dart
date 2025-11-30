import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/widgets/back_icon.dart';
import 'package:photocurator/common/widgets/more_dropdown.dart';
import 'package:photocurator/common/widgets/view_more_icon.dart';

//상세 페이지(하위 페이지) 상단 바 ui
class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? rightWidget;
  final VoidCallback? onTap;

  const DetailAppBar({
    super.key,
    this.title,
    this.rightWidget,
    this.onTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  // ↑ 여긴 무시됨. 실제 높이는 build에서 계산됨.
  // 구조상 required라 아무 값 넣는 것.

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = width * (50 / 375); // 반응형으로 세로 길이 설정

    return SafeArea(
      //상태바 겹침 방지
      top: true, // 상단 노치 영역 포함
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        color: AppColors.wh1,
        child: Row(
          children: [
            // 왼쪽: 뒤로가기
            SizedBox(
              width: height,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    Container(
                      width: height * (10 / 50),
                      height: height * (20 / 50),
                      alignment: Alignment.center,
                      child: BackIcon(barHeight: height),
                    ),
                    const Spacer(), // 정렬 맞추는 용도
                  ],
                ),
              ),
            ),

            // 중앙: 제목
            Expanded(
              child: Center(
                child: Text(
                  title ?? '', // 사진 상세는 중앙 비어 있음
                  style: TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: height * (21 / 50),
                    color: AppColors.dg1C1F23,
                    letterSpacing: 0, // 자간 0으로 설정
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // 오른쪽 버튼(텍스트 버튼 or 더보기 버튼 or null)
            SizedBox(
              width: height, // 중앙 정렬을 위해 왼쪽과 동일하게
              child: GestureDetector(
                onTap: () => onTap,
                child: Row(
                  children: [
                    const Spacer(), // 정렬 맞추는 용도
                    rightWidget ?? const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// 홈 상단 바
// 뒤로가기 있는 버전
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String projectName;
  final List<DropdownItem> menuItems;

  const HomeAppBar({super.key, required this.projectName, required this.menuItems});

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barHeight = screenWidth * (50 / 375);

    return DetailAppBar(
      title: projectName,
      rightWidget: Builder(
        builder: (buttonContext) => Container(
          width: barHeight,
          alignment: Alignment.centerRight,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              final renderBox = buttonContext.findRenderObject() as RenderBox;
              showMoreDropdown(
                context: context,
                buttonRenderBox: renderBox,
                items: menuItems,
              );
            },
            icon: Row(
              children: [
                Spacer(),
                Container(
                  width: barHeight * (20 / 50) * (1 / 6),
                  height: barHeight * (20 / 50),
                  alignment: Alignment.center,
                  child: MoreIcon(
                    totalHeight: barHeight * (20 / 50),
                    dotDiameter: barHeight * (20 / 50) * (1 / 6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
