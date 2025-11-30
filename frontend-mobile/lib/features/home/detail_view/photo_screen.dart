import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/widgets/view_more_icon.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/preview_bar.dart';

// 사진 상세 화면
class PhotoScreen extends StatefulWidget {
  final List<ImageItem> images; // 전체 이미지 리스트
  final int initialIndex;       // 초기 선택된 이미지 인덱스

  const PhotoScreen({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final currentImage = widget.images[currentIndex];

    return Scaffold(
      appBar: DetailAppBar(
        rightWidget: GestureDetector(
          onTap: () => print("우측 버튼 클릭"),
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
      body: Column(
        children: [
          // 1. 점수/모델 표시
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Brisque
                SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Brisque',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansRegular',
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        currentImage.qualityScore?.brisque?.toString() ?? "-",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansRegular',
                          color: AppColors.dg495057,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tenegrad
                SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tenegrad',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansRegular',
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        currentImage.qualityScore?.tenegrad?.toString() ?? "-",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansRegular',
                          color: AppColors.dg495057,
                        ),
                      ),
                    ],
                  ),
                ),

                // Musiq
                SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Musiq',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansRegular',
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        currentImage.qualityScore?.musiq?.toString() ?? "-",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansRegular',
                          color: AppColors.dg495057,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. 이미지 상세
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.lgE9ECEF,
              child: Image.network(
                currentImage.thumbnailUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 3. 이미지 프리뷰 가로 스크롤
          PreviewBar(
            images: widget.images,
            currentImage: currentImage,
            onImageSelected: (img) {
              final newIndex = widget.images.indexOf(img);
              if (newIndex != -1) setState(() => currentIndex = newIndex);
            },
            deviceWidth: deviceWidth,
          ),
        ],
      ),
    );
  }
}
