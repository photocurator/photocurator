import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photocurator/common/theme/colors.dart';

class NewProjectCard extends StatelessWidget {
  final VoidCallback onTap;

  const NewProjectCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 177,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lgE9ECEF, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 10,
              right: 12,
              child: Text(
                '새 프로젝트',
                style: TextStyle(
                  fontFamily: 'NotoSansRegular',
                  fontSize: 10,
                  color: AppColors.dg495057,
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  'assets/icons/button/folder.svg',
                  width: 30,
                  height: 30,
                  placeholderBuilder: (context) => const Icon(
                    Icons.create_new_folder,
                    size: 30,
                    color: AppColors.dg1C1F23,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}