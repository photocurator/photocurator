import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/widgets/view_more_icon.dart';

//이미지를 복사 후 이동할 프로젝트를 선택하는 하위 페이지
class TrashScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: DetailAppBar(
        title: "프로젝트 선택",
        rightWidget: GestureDetector(
            onTap: () {
              print("우측 버튼 클릭");
            },
            child: Container(
              width: deviceWidth * (50 / 375) * (20 / 50) * (1 / 6),
              height: deviceWidth * (50 / 375) * (20 / 50),
              alignment: Alignment.center,
              child: MoreIcon(
                totalHeight: deviceWidth * (50 / 375) * (20 / 50),
                dotDiameter: deviceWidth * (50 / 375) * (20 / 50) * (1 / 6),
              ),
            )
        ),
      ),
      //body:
    );
  }
}