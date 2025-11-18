import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/widgets/view_more_icon.dart';

//사진 상세 화면
class TrashScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: DetailAppBar(
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