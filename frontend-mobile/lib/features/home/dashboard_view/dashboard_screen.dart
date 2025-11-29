import 'package:flutter/material.dart';
import 'package:photocurator/common/bar/view/app_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view_model/home_tab_section.dart';
import 'package:photocurator/common/widgets/more_dropdown.dart';
import '../detail_view/trash_screen.dart';
import '../detail_view/compare_screen.dart';
import '../detail_view/pj_setting_screen.dart';

class DashboardScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final barHeight = deviceWidth * (50/375);

    return Scaffold(
      backgroundColor: AppColors.wh1,

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(barHeight),
        child: SafeArea(
          child: Container(
            height: barHeight,
          ),
        ),
      ),
      //body: ,
    );
  }
}