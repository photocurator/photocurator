import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';

class HighlightScreen extends StatelessWidget {
  const HighlightScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: DetailAppBar( //실험용으로 넣어둔 것; 페이지 구현 시 지울 것
        title: "휴지통",
        rightWidget: GestureDetector(
          onTap: () {
            print("우측 버튼 클릭");
          },
          child: Text(
            "선택",
            style: TextStyle(
                fontSize: deviceWidth * (50 / 375) * (14 / 50),
                color: AppColors.lgADB5BD
            ),
          ),
        ),
      ),
      body: const Center(
        child: Text("내용 영역"),
      ),
    );
  }
}