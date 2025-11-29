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

// 추후 데이터 교체 요망
// 홈 화면 핸들링
class HomeScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final String pjname = "Project name";  //추후에 프로젝트 이름 데이터 넣을 것

    return Scaffold(
      backgroundColor: AppColors.wh1,

      appBar: HomeAppBar(
        projectName: pjname,
        // 더보기 메뉴
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
        )

    );
  }
}