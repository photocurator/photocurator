import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';

/*
//숨긴 사진 상세 화면
class HideScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.wh1,

      appBar: DetailAppBar(
        title: "숨긴 사진",
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start, // start, center, end, spaceBetween, spaceAround, spaceEvenly 중 선택
        crossAxisAlignment: CrossAxisAlignment.center, // start, center, end, stretch, baseline 중 선택
        mainAxisSize: MainAxisSize.min, // max (최대), min (자식 크기에 맞게 최소) 중 선택
        // 내용
        children: [
          Container(height: 1, color: AppColors.lgE9ECEF), //구분선
          //이미지 리스트 구현
        ],
      ),
    );
  }
}
*/


class HideScreen extends StatefulWidget {
  @override
  State<HideScreen> createState() => _HiddenScreenState();
}

class _HiddenScreenState extends BasePhotoScreen<HideScreen> {
  @override
  String get viewType => 'ALL'; // API 호출은 전체를 가져오고 아래에서 필터링

  @override
  String get screenTitle => '숨긴 사진';

  @override
  Future<void> _loadImages() async {
    if (projectId == null) return;

    setState(() => isLoading = true);

    final api = ApiService();
    try {
      final fetchedImages = await api.fetchProjectImages(
        projectId!,
        viewType: viewType,
      );

      // 숨긴 사진만 필터링
      final hiddenImages =
      fetchedImages.where((img) => img.isRejected == true).toList();

      setState(() {
        images = hiddenImages;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("이미지 불러오기 실패: $e");
    }
  }
}