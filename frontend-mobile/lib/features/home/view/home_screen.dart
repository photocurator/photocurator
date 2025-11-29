import 'package:flutter/material.dart';
import 'package:photocurator/common/bar/view/app_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view_model/home_tab_section.dart';
import './highlight_screen.dart';
import './like_screen.dart';
import './date_screen.dart';
import './grade_screen.dart';
import './subject_screen.dart';
import './setting_screen.dart';

// 추후 데이터 교체 요망
// 홈 화면 로드
class HomeScreen extends StatelessWidget {
  final String projectId;

  const HomeScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch project details using projectId
    final String pjname = "Project name"; // Placeholder

    return Scaffold(
      backgroundColor: AppColors.wh1,

      appBar: HomeAppBar(projectName: pjname),
      body: HomeTabSection(
// ...
        pages: [
          HighlightScreen(),
          LikeScreen(),
          DateScreen(),
          GradeScreen(),
          SubjectScreen(),
          SettingScreen(),
        ],
      ),
    );
  }
}