import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/features/start/view_model/project_model.dart';

class ProjectListItem extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const ProjectListItem({
    super.key,
    required this.project,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.transparent, // No separator lines in design
              width: 0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                project.name,
                style: const TextStyle(
                  fontFamily: 'NotoSansRegular',
                  fontSize: 16,
                  color: AppColors.dg1C1F23,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SvgPicture.asset(
              'assets/icons/button/go_to_prj_gray.svg', // Using 'back.svg' rotated as per design analysis or find a 'next' icon
              width: 6,
              height: 12,
              colorFilter: const ColorFilter.mode(
                AppColors.lgADB5BD,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

