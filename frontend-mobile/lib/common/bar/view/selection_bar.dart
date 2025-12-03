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
  final VoidCallback onDownloadSelected;
  final VoidCallback onDeleteSelected;
  final VoidCallback onCancel;
  final double deviceWidth;
  final bool isAllSelected;

  const SelectModeAppBar({
    required this.title,
    required this.onSelectAll,
    required this.onAddToCompare,
    required this.onDownloadSelected,
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
            fontFamily: 'NotoSansMedium',
            fontSize: deviceWidth * (12 / 375),
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
              _SelectionActionButton(
                label: "비교뷰 담기",
                iconPath: 'assets/icons/button/full_screen_gray.svg',
                deviceWidth: deviceWidth,
                onTap: onAddToCompare,
              ),
              const SizedBox(width: 8),
              _SelectionActionButton(
                label: "다운로드",
                iconPath: 'assets/icons/button/download_gray.svg',
                deviceWidth: deviceWidth,
                onTap: onDownloadSelected,
                showLabel: false,
              ),
              const SizedBox(width: 8),
              _SelectionActionButton(
                label: "삭제",
                iconPath: 'assets/icons/button/trash_bin_gray.svg',
                deviceWidth: deviceWidth,
                onTap: onDeleteSelected,
                showLabel: false,
              ),
              const SizedBox(width: 12),
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

class _SelectionActionButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final double deviceWidth;
  final VoidCallback onTap;
  final bool showLabel;

  const _SelectionActionButton({
    required this.label,
    required this.iconPath,
    required this.deviceWidth,
    required this.onTap,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final double height = deviceWidth * (30 / 375);
    final double iconSize = deviceWidth * (14 / 375);
    final double minWidth = showLabel ? 0 : deviceWidth * (34 / 375);

    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: Size(minWidth, height),
      side: const BorderSide(color: AppColors.lgE9ECEF),
      padding: showLabel
          ? EdgeInsets.symmetric(horizontal: deviceWidth * (10 / 375))
          : EdgeInsets.all(deviceWidth * (6 / 375)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: AppColors.wh1,
    );

    if (showLabel) {
      return SizedBox(
        height: height,
        child: OutlinedButton.icon(
          onPressed: onTap,
          style: buttonStyle,
          icon: SvgPicture.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
            colorFilter: const ColorFilter.mode(AppColors.dg1C1F23, BlendMode.srcIn),
          ),
          label: Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSansMedium',
              fontSize: deviceWidth * (12 / 375),
              color: AppColors.dg1C1F23,
              letterSpacing: 0,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onTap,
        style: buttonStyle,
        child: SvgPicture.asset(
          iconPath,
          width: iconSize,
          height: iconSize,
          colorFilter: const ColorFilter.mode(AppColors.dg1C1F23, BlendMode.srcIn),
        ),
      ),
    );
  }
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
              "최신순",
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
