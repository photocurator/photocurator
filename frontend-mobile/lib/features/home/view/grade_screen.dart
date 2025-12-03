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

  bool _labelsPrepared = false; // 중복 계산 방지

  List<ImageItem> _bestShots = [];
  List<ImageItem> _aCuts = [];
  List<ImageItem> _bCuts = [];

  void _recalculateCuts() {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final allImages = List<ImageItem>.from(imageProvider.allImages);

    if (allImages.isEmpty) {
      _bestShots = [];
      _aCuts = [];
      _bCuts = [];
      return;
    }

    allImages.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

    final total = allImages.length;

    int bestCount = (total * 0.3).floor();
    if (bestCount > 20) bestCount = 20;
    if (bestCount > total) bestCount = total;

    _bestShots = allImages.take(bestCount).toList();

    final remain = allImages.skip(bestCount).toList();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // provider가 바뀌면 여기 호출됨. 단 최초 1회만 라벨 구성
    if (!_labelsPrepared) {
      _prepareRatingLabels();

      if (selectedTabIndex >= ratingLabels.length) {
        selectedTabIndex = 0;
      }

      _labelsPrepared = true;
    }
  }

  void _prepareRatingLabels() {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final allImages = imageProvider.allImages;

    if (allImages.length <= 3) {
      ratingLabels = ["베스트 샷"];
    } else {
      ratingLabels = ["베스트 샷", "A컷", "B컷"];
    }
    _recalculateCuts();
  }

  void _onTabSelected(int index) {
    setState(() => selectedTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: Column(
        children: [
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

  @override
  String? get groupBy => null;

  @override
  List<ImageItem> get imageItems => widget.images;
}


