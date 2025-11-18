import 'package:flutter/material.dart';
import 'package:photocurator/common/bar/view/app_bar.dart';
import 'package:photocurator/common/bar/view_model/home_tab_section.dart';
import './highlight_screen.dart';
import './like_screen.dart';
import './date_screen.dart';
import './grade_screen.dart';
import './subject_screen.dart';
import './setting_screen.dart';

//홈 화면 로드
class HomeScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(projectName: "Project name"), //추후에 프로젝트 이름 데이터 넣을 것
      body: HomeTabSection(
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