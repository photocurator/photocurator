import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';

//알림 확인 상세
class AlarmScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.wh1,

      appBar: DetailAppBar(
          title: "알림 확인",
          rightWidget: null
      ),
      //body:
    );
  }
}