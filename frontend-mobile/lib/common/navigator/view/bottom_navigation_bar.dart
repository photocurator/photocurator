import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:photocurator/common/theme/colors.dart';


class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _FancyBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _goBranch,
      ),
    );
  }
}

class _FancyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FancyBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double navHeight = 64;
    const inactive = AppColors.lgADB5BD;

    return SafeArea(
      top: false,        // 위는 안전 영역 필요 없음
      bottom: true,      // 아래만 보호
      child: SizedBox(
        width: double.infinity,
        height: navHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.wh1,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                asset: 'assets/icons/navigator/bottom_search.svg',
                label: '스마트검색',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
                activeColor: AppColors.dg1C1F23,
                inactiveColor: AppColors.lgADB5BD,
              ),
              _CenterCircleItem(
                navHeight: navHeight * 0.85,
                selected: currentIndex == 1,
                onTap: () => onTap(1),
                child: Image.asset(
                  'assets/icons/navigator/logo.png',
                  width: navHeight * 0.35,
                  height: navHeight * 0.35,
                  fit: BoxFit.contain,
                ),
              ),
              _NavItem(
                asset: 'assets/icons/navigator/user.svg',
                label: '마이페이지',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
                activeColor: AppColors.dg1C1F23,
                inactiveColor: inactive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// �????�스???�이�?
class _NavItem extends StatelessWidget {
  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItem({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;

    // ?�트 ?��????�일 (NotoSans 기�? ?�시)
    const selectedTextStyle = TextStyle(
      fontFamily: 'NotoSansRegular',
      fontSize: 10,
    );
    const unselectedTextStyle = TextStyle(
      fontFamily: 'NotoSansRegular',
      fontSize: 10,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              asset,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: (selected ? selectedTextStyle : unselectedTextStyle)
                  .copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterCircleItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double navHeight;

  const _CenterCircleItem({
    required this.selected,
    required this.onTap,
    required this.child,
    required this.navHeight,
  });

  @override
  Widget build(BuildContext context) {
    final circleSize = navHeight * 1.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          color: AppColors.wh1,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.bottomBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

