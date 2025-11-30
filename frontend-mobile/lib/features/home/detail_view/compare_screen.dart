import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';

//비교 뷰 상세 화면
class CompareScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: DetailAppBar(
        title: "비교 뷰",
        rightWidget: GestureDetector(
          onTap: () {
            print("우측 버튼 클릭");
          },
          child: Text(
            "완료",
            style: TextStyle(
                fontSize: deviceWidth * (50 / 375) * (14 / 50),
                color: AppColors.lgADB5BD
            ),
          ),
        ),
      ),
      //body:
    );
  }
}