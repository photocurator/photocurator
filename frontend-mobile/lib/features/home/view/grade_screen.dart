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

class _GradeScreenState extends BasePhotoContent<GradeScreen> {
  @override
  String get screenTitle => "등급별 사진";

  @override
  String get viewType => "ALL"; // 전체 이미지 가져오기

  @override
  String get sortType => "time";
  @override
  String? get groupBy => null;

  int selectedTabIndex = 0;
  List<String> ratingLabels = ["베스트 샷"]; // 초기값

  void _prepareRatingLabels() {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final allImages = imageProvider.allImages; // viewType이 ALL이라면 allImages
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
  }

  List<ImageItem> get currentImages {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final allImages = imageProvider.allImages; // viewType이 ALL이라면 allImages
    final bestShotImages = imageProvider.bestShotImages; // viewType이 ALL이라면 allImages
    if (selectedTabIndex == 0) return bestShotImages;

    final label = ratingLabels[selectedTabIndex];
    final rating = int.tryParse(label.replaceAll("점", "")) ?? 0;
    return allImages.where((img) => img.rating == rating).toList();
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

          // 2. 선택/정렬 바
          SizedBox(
            height: deviceWidth * (40 / 375),
            child: isSelecting
                ? SelectModeAppBar(
              title: selectedImages.isEmpty
                  ? "전체 선택"
                  : "${selectedImages.length}개 선택됨",
              deviceWidth: deviceWidth,
              onSelectAll: () {
                setState(() {
                  if (selectedImages.length == currentImages.length) {
                    selectedImages.clear();
                  } else {
                    selectedImages = List.from(currentImages);
                  }
                });
              },
              onAddToCompare: onAddToCompare,
              onDownloadSelected: onDownloadSelected,
              onDeleteSelected: onDeleteSelected,
              onCancel: () => setState(() => isSelecting = false),
              isAllSelected: selectedImages.length == currentImages.length,
            )
                : SortingAppBar(
              screenTitle: screenTitle,
              imagesCount: currentImages.length,
              sortType: sortType ?? "time",
              deviceWidth: deviceWidth,
              onSelectMode: () => setState(() => isSelecting = true),
              onSortRecommend: () => setState(() => sortType = "recommend"),
              onSortTime: () => setState(() => sortType = "time"),
            ),
          ),

          // 3. 이미지 그리드
          Expanded(
            child: currentImages.isEmpty
                ? const Center(
              child: Text(
                '선택된 등급의 이미지가 없습니다.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
                : PhotoGrid(
              images: currentImages,
              isSelecting: isSelecting,
              selectedImages: selectedImages,
              onSelectToggle: toggleSelection,
              onLongPressItem: () => setState(() => isSelecting = true),
              onTogglePick: togglePick,
            ),
          ),
        ],
      ),
    );
  }
}
