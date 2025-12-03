import 'package:flutter/material.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/bar/view/selectable_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:provider/provider.dart';

import '../../../provider/current_project_provider.dart';

class GradeScreen extends StatefulWidget {
  const GradeScreen({Key? key}) : super(key: key);

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen> {

  int selectedTabIndex = 0;
  List<String> ratingLabels = ["베스트 샷", "A컷", "B컷"]; // 초기값

  void _prepareRatingLabels() {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final length = imageProvider.allImages.length; // viewType이 ALL이라면 allImages

    if (length<=3)
      ratingLabels = ["베스트 샷"];

    /*
    // 존재하는 등급만 추출 후 내림차순 정렬
    final existingRatings = allImages
        .map((img) => img.rating)
        .toSet()
        .where((r) => r != null)
        .map((r) => r!)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    ratingLabels = ["베스트 샷"];
    ratingLabels.addAll(existingRatings.map((r) => "$r점"));
     */
  }

  List<ImageItem> get currentImages {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final allImages = List<ImageItem>.from(imageProvider.allImages);

    if (allImages.isEmpty) return [];

    // 1) musiqScore 기준 정렬 (내림차순)
    allImages.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

    final total = allImages.length;

    // 2) 베스트샷 개수 계산
    int bestCount = (total * 0.3).floor(); // 상위 30%
    if (bestCount < 3) bestCount = 3;
    if (bestCount > 20) bestCount = 20;
    if (bestCount > total) bestCount = total;

    final bestShots = allImages.take(bestCount).toList();

    // 3) 나머지 → A컷 / B컷
    final remain = allImages.skip(bestCount).toList();
    final remainCount = remain.length;

    int aCutCount = (remainCount / 2).floor();
    final aCuts = remain.take(aCutCount).toList();
    final bCuts = remain.skip(aCutCount).toList();

    // 4) 탭 선택 반영
    if (selectedTabIndex == 0) return bestShots;
    if (selectedTabIndex == 1) return aCuts;
    if (selectedTabIndex == 2) return bCuts;

    return [];
  }


  void _onTabSelected(int index) {
    setState(() => selectedTabIndex = index);
  }

  @override
  void onImagesLoaded() {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final allImages = imageProvider.allImages; // viewType이 ALL이라면 allImages
    if (allImages.isEmpty) return;
    _prepareRatingLabels();
    if (selectedTabIndex >= ratingLabels.length) selectedTabIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: Column(
        children: [
          // 1. 등급 선택 바
          SelectableBar(
            items: ratingLabels,
            selectedIndex: selectedTabIndex,
            onItemSelected: _onTabSelected,
            height: deviceWidth * (44 / 375),
          ),

          Expanded(
            child: GradeScreenContent(images: currentImages),
          )
        ],
      ),
    );
  }
}


class GradeScreenContent extends StatefulWidget {
  final List<ImageItem> images;

  const GradeScreenContent({
    Key? key,
    required this.images,
  }) : super(key: key);

  @override
  _GradeScreenContentState createState() => _GradeScreenContentState();
}

class _GradeScreenContentState extends BasePhotoContent<GradeScreenContent> {
  @override
  String get viewType => 'ALL';

  @override
  String get screenTitle => '날짜별 사진';

  // 그룹핑 필요 없으므로 null 반환
  @override
  String? get groupBy => null;

  // StatefulWidget의 images를 참조하려면 widget.images 사용
  @override
  List<ImageItem> get imageItems => widget.images;
}

