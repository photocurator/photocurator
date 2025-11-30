import 'package:flutter/material.dart';
//import 'package:photocurator/common/bar/view/app_bar.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view_model/home_tab_section.dart';
import 'package:photocurator/common/widgets/more_dropdown.dart';

import '../detail_view/trash_screen.dart';
import '../detail_view/compare_screen.dart';
import '../detail_view/pj_setting_screen.dart';

import '../dashboard_view/dashboard_screen.dart';
import './highlight_screen.dart';
import './like_screen.dart';
import './date_screen.dart';
import './grade_screen.dart';
import './subject_screen.dart';
import './setting_screen.dart';

// 홈 화면
class HomeScreen extends StatelessWidget {
  final String projectId;

  const HomeScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    final String pjname = "Project name"; // 나중에 실제 데이터로 교체

    return Scaffold(
      backgroundColor: AppColors.wh1,

      // 👉 더보기 드롭다운 포함된 커스텀 앱바 유지
      appBar: HomeAppBar(
        projectName: pjname,
        menuItems: [
          DropdownItem(
            text: "이미지 업로드",
            onTap: () => print("업로드 클릭"),
          ),
          DropdownItem(
            text: "검색",
            onTap: () => print("검색 클릭"),
          ),
          DropdownItem(
            text: "휴지통",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TrashScreen()),
              );
            },
          ),
          DropdownItem(
            text: "비교 뷰",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CompareScreen()),
              );
            },
          ),
          DropdownItem(
            text: "프로젝트 설정",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PjSettingScreen()),
              );
            },
          ),
        ],
      ),

      // 👉 main 브랜치의 body 구조 유지
      body: Column(
        children: [
          Container(height: 1),
          Expanded(
            child: HomeTabSection(
              pages: [
                HighlightScreen(),
                LikeScreen(),
                DateScreen(),
                GradeScreen(),
                SubjectScreen(),
                SettingScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
