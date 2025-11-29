import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/widgets/view_more_icon.dart';

// 사진 상세 화면
class PhotoScreen extends StatelessWidget {
  final String imageId;

  const PhotoScreen({Key? key, required this.imageId}) : super(key: key);

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
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '사진 상세 화면',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.dg1C1F23,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'imageId: $imageId',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.dg1C1F23,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: deviceWidth * 0.8,
              height: deviceWidth * 0.8,
              color: Colors.grey[300],
              child: const Center(child: Text('이미지 자리')),
            ),
          ],
        ),
      ),
    );
  }
}
