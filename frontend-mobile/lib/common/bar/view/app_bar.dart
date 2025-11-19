import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/widgets/more_dropdown.dart';
import 'package:photocurator/common/widgets/view_more_icon.dart';

//상단 바의 베이직 ui
class BaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? rightWidget; // 오른쪽 요소 (null 가능)...홈 에서만 더보기 아이콘

  const BaseAppBar({
    Key? key,
    required this.title,
    this.rightWidget,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barHeight = screenWidth * (50 / 375); //반응형 높이

    return SafeArea( //상태바랑 겹치지 않도록
      child: Container(
        height: barHeight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.wh1,
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'NotoSansMedium', //'NotoSansRegular',
                fontSize: barHeight * (21 / 50),
                color: AppColors.dg1C1F23,
                letterSpacing: 0, // 자간 0으로 설정
              ),
              maxLines: 1, //한 줄
              overflow: TextOverflow.ellipsis, //넘치면 줄임표 처리
            ),
            const Spacer(), //갭 자동
            if (rightWidget != null) rightWidget!, //null이 아닐 경우 더보기 아이콘 표시
          ],
        ),
      ),
    );
  }
}


// 홈 상단 바
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

    return BaseAppBar(
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


// 스마트 검색 상단 바
class SmartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SmartAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(50); // 기본 높이

  @override
  Widget build(BuildContext context) {
    return BaseAppBar(
      title: "스마트 검색",
      rightWidget: null,
    );
  }
}

//마이페이지 상단 바
class MyPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyPageAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    return const BaseAppBar(
      title: "마이페이지",
      rightWidget: null,
    );
  }
}