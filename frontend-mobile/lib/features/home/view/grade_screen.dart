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
  List<String> ratingLabels = ["베스트 샷", "A컷", "B컷"];

  List<ImageItem> _bestShots = [];
  List<ImageItem> _aCuts = [];
  List<ImageItem> _bCuts = [];

  @override
  Widget build(BuildContext context) {
    // Provider 변경 즉시 감지됨
    final imageProvider = context.watch<CurrentProjectImagesProvider>();
    final allImages = imageProvider.allImages;

    // 라벨 구성
    if (allImages.length <= 3) {
      ratingLabels = ["베스트 샷"];
      if (selectedTabIndex > 0) selectedTabIndex = 0;
    } else {
      ratingLabels = ["베스트 샷", "A컷", "B컷"];
    }

    // 컷 재계산
    _recalculateCuts(allImages);

    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: Column(
        children: [
          SelectableBar(
            items: ratingLabels,
            selectedIndex: selectedTabIndex,
            onItemSelected: (i) => setState(() => selectedTabIndex = i),
            height: deviceWidth * (44 / 375),
          ),
          Expanded(
            child: GradeScreenContent(images: currentImages),
          ),
        ],
      ),
    );
  }

  void _recalculateCuts(List<ImageItem> allImages) {
    if (allImages.isEmpty) {
      _bestShots = [];
      _aCuts = [];
      _bCuts = [];
      return;
    }

    final sorted = List<ImageItem>.from(allImages)
      ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

    final total = sorted.length;

    // 베스트샷 계산
    int bestCount = (total * 0.3).floor();
    if (bestCount > 20) bestCount = 20;
    if (bestCount > total) bestCount = total;

    _bestShots = sorted.take(bestCount).toList();

    // 나머지 A/B컷 나누기
    final remain = sorted.skip(bestCount).toList();
    final remainCount = remain.length;

    int aCutCount = (remainCount / 2).floor();
    _aCuts = remain.take(aCutCount).toList();
    _bCuts = remain.skip(aCutCount).toList();
  }

  List<ImageItem> get currentImages {
    if (selectedTabIndex == 0) return _bestShots;
    if (selectedTabIndex == 1) return _aCuts;
    return _bCuts;
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

  @override
  String? get groupBy => null;

  @override
  List<ImageItem> get imageItems => widget.images;
}
