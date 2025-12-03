import 'package:flutter/material.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 선택 모드 전환 바
// app bar
class SelectModeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onSelectAll;
  final VoidCallback onAddToCompare;
  final VoidCallback onDeleteSelected;
  final VoidCallback onCancel;
  final double deviceWidth;
  final bool isAllSelected;

  const SelectModeAppBar({
    required this.title,
    required this.onSelectAll,
    required this.onAddToCompare,
    required this.onDeleteSelected,
    required this.onCancel,
    required this.deviceWidth,
    required this.isAllSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.wh1,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: deviceWidth * (50 / 375),
      title: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: GestureDetector(
          onTap: onSelectAll,
          child: Row(
        children: [
          SvgPicture.asset(
            isAllSelected
                ? 'assets/icons/button/select_button_blue.svg' // 체크된 원
                : 'assets/icons/button/select_button0.svg', // 빈 원
            width: deviceWidth * (14 / 375),
            height: deviceWidth * (14 / 375),
            //colorFilter:
            //ColorFilter.mode(AppColors.lgADB5BD, BlendMode.srcIn),
          ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'NotoSansRegular',
            fontSize: 13,
            color: AppColors.dg1C1F23,
            letterSpacing: 0,
          ),
        ),
        ],
      ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: onAddToCompare,
                child: Text(
                  "비교뷰 담기",
                  style: TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: deviceWidth * (14 / 375),
                    color: AppColors.dg1C1F23,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onDeleteSelected,
                child: Text(
                  "선택 삭제",
                  style: TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: 14,
                    color: AppColors.dg1C1F23,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onCancel,
                child: Center(
                  child: Text(
                    "취소",
                    style: TextStyle(
                      fontFamily: 'NotoSansMedium',
                      fontSize: 14,
                      color: AppColors.lgADB5BD,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(deviceWidth * (50 / 375));
}


// 중간 bar
class SortingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String screenTitle;
  final int imagesCount;
  final String sortType;
  final double deviceWidth;
  final VoidCallback onSelectMode;
  final VoidCallback onSortRecommend;
  final VoidCallback onSortTime;

  const SortingAppBar({
    super.key,
    required this.screenTitle,
    required this.imagesCount,
    required this.sortType,
    required this.deviceWidth,
    required this.onSelectMode,
    required this.onSortRecommend,
    required this.onSortTime,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: deviceWidth * (40 / 375),
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.wh1,
      ),
      child: Row(
        children: [
          // 이미지 n개
          Text(
            "이미지 $imagesCount개",
            style: TextStyle(
              fontFamily: 'NotoSansRegular',
              fontSize: deviceWidth * (12 / 375),
              color: AppColors.lgADB5BD,
              letterSpacing: 0,
            ),
          ),

          Spacer(),

          // 추천순
          GestureDetector(
            onTap: onSortRecommend,
            child: Text(
              "추천순",
              style: TextStyle(
                fontFamily: 'NotoSansRegular',
                fontSize: deviceWidth * (12 / 375),
                color: sortType == "recommend" ? AppColors.dg495057 : AppColors.lgADB5BD,
              ),
            ),
          ),
          SizedBox(width: 12),

          // 시간순
          GestureDetector(
            onTap: onSortTime,
            child: Text(
              "시간순",
              style: TextStyle(
                fontFamily: 'NotoSansRegular',
                fontSize: deviceWidth * (12 / 375),
                color: sortType == "time" ? AppColors.dg495057 : AppColors.lgADB5BD,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
