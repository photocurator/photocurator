import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';

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
            fontFamily: 'NotoSansRegular',
            fontSize: 14,
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
          decoration: BoxDecoration(
            color: AppColors.lgE9ECEF.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.folder_open, size: 48, color: AppColors.lgADB5BD),
        ),
        const SizedBox(height: 24),
        const Text(
          '생성된 프로젝트가 없습니다',
          style: TextStyle(
            fontFamily: 'NotoSansMedium',
            fontSize: 15,
            color: AppColors.dg495057,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onCreateTap,
          child: const Text(
            '생성하기',
            style: TextStyle(
              fontFamily: 'NotoSansMedium',
              fontSize: 13,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}