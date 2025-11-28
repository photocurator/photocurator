import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photocurator/common/theme/colors.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Project Count
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: const [
                      Text(
                        '0',
                        style: TextStyle(
                          fontFamily: 'NotoSansRegular',
                          fontSize: 60,
                          height: 1.0,
                          color: AppColors.dg1C1F23,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '프로젝트',
                        style: TextStyle(
                          fontFamily: 'NotoSansRegular',
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // New Project Button
                  _NewProjectButton(),
                ],
              ),
              const SizedBox(height: 20),
              // Search Bar
              Container(
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lgE9ECEF),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/button/search.svg', // Using existing search icon
                      width: 15,
                      height: 15,
                      colorFilter: const ColorFilter.mode(
                        AppColors.lgADB5BD, 
                        BlendMode.srcIn
                      ),
                    ),
                  ],
                ),
              ),
              
              // Empty State
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/button/image_auto_adjust.svg', // Using likely match for the folder/sparkle icon
                      width: 100, 
                      height: 100, // Approximating size
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '생성된 프로젝트가 없습니다',
                      style: TextStyle(
                        fontFamily: 'NotoSansMedium',
                        fontSize: 16,
                        color: AppColors.dg1C1F23,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                         // Define action for creating project
                         print("Create Project Tapped");
                      },
                      child: Column(
                        children: [
                          const Text(
                            '생성하기',
                            style: TextStyle(
                              fontFamily: 'NotoSansRegular',
                              fontSize: 12,
                              color: AppColors.dg495057, // #6C757D is close to dg495057 or lgADB5BD. Using dg495057 for better contrast.
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Arrow icon or similar indicator if needed, visually it looks like a small arrow might be there in Figma but code didn't explicitly show one besides "LineButton".
                          // The react code showed imgVector21 which is a line/arrow.
                          // I'll skip the arrow for now or use a simple icon if found.
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewProjectButton extends StatelessWidget {
  const _NewProjectButton();

  @override
  Widget build(BuildContext context) {
    // Matches the "New Project" card in top right
    return Container(
      width: 100, // Approx width based on design
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lgE9ECEF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/button/new_project_button_gray.svg',
            width: 30,
            height: 30,
          ),
          const SizedBox(height: 8),
          const Text(
            '새 프로젝트',
            style: TextStyle(
              fontFamily: 'NotoSansRegular',
              fontSize: 10,
              color: AppColors.dg495057,
            ),
          ),
        ],
      ),
    );
  }
}

