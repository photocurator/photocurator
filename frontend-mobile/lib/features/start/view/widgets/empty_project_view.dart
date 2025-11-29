import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyProjectView extends StatelessWidget {
  final VoidCallback onCreateTap;
  final bool isSearchResult; // 검색 결과가 없는 경우인지 구분

  const EmptyProjectView({
    super.key,
    required this.onCreateTap,
    this.isSearchResult = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearchResult) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다.',
          style: TextStyle(
            fontFamily: 'NotoSansMedium',
            fontSize: 16,
            color: AppColors.lgADB5BD,
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          child: SvgPicture.asset(
            'assets/icons/button/no_project_img.svg', // Using 'back.svg' rotated as per design analysis or find a 'next' icon
            width: 140,
            height: 140,
            colorFilter: const ColorFilter.mode(
              AppColors.lgE9ECEF,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '생성된 프로젝트가 없습니다',
          style: TextStyle(
            fontFamily: 'NotoSansMedium',
            fontSize: 16,
            color: AppColors.dg495057,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onCreateTap,
          child: const Text(
            '생성하기',
            style: TextStyle(
              fontFamily: 'NotoSansRegular',
              fontSize: 13,
              color: AppColors.lg6C757D,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.lg6C757D,
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}