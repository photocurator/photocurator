import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/features/start/service/project_service.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final bool isRecent;
  final VoidCallback? onTap;

  const ProjectCard({
    super.key,
    required this.project,
    this.isRecent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lgE9ECEF, // Placeholder color from design
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Background Image would go here.
            // Using a simple colored container for now as per design placeholder.
            
            // Content Overlay
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Text(
                    project.projectName,
                    style: const TextStyle(
                      fontFamily: 'NotoSansMedium',
                      fontSize: 16,
                      color: AppColors.wh1, // White text
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 4,
                          color: Color.fromRGBO(28, 31, 35, 0.1),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Date
                  Text(
                    "${project.createdAt.year}.${project.createdAt.month.toString().padLeft(2, '0')}.${project.createdAt.day.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontFamily: 'NotoSansRegular',
                      fontSize: 10,
                      color: AppColors.wh1,
                    ),
                  ),
                ],
              ),
            ),

            // Recent Badge
            if (isRecent)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.wh1,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    border: Border.all(
                      color: const Color.fromRGBO(28, 31, 35, 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/button/history_light_gray.svg',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '최근 열람',
                        style: TextStyle(
                          fontFamily: 'NotoSansRegular',
                          fontSize: 8,
                          color: AppColors.lgADB5BD,
                        ),
                      ),
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

