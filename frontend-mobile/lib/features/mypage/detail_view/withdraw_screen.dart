import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';

//회원 탈퇴 상세
class WithdrawScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.wh1,

      appBar: DetailAppBar(
          title: "회원 탈퇴",
          rightWidget: null
      ),
      //body:
    );
  }
}