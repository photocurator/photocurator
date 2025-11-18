import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';

//프로필 설정 화면
class TrashScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: DetailAppBar(
        title: "프로필 설정",
        rightWidget: null
      ),
      //body:
    );
  }
}