// subject_screen.dart
import 'package:flutter/material.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/bar/view/selectable_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:provider/provider.dart';

import '../../../provider/current_project_provider.dart';

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({Key? key}) : super(key: key);

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends BasePhotoContent<SubjectScreen> {
  @override
  String get screenTitle => "주제별 사진";

  @override
  String get viewType => "ALL";

  @override
  String get sortType => "recommend";

  @override
  String? get groupBy => null;

  int selectedTabIndex = 0;
  List<String> subjectLabels = []; // objectTags에서 추출
  Map<String, List<ImageItem>> tabImages = {};
  bool isLoading = true;

  /// 이미지에서 태그별 라벨과 매핑 준비
  void _prepareSubjectLabels() {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final images = imageProvider.allImages;

    subjectLabels.clear();
    tabImages.clear();

    for (var img in images) {
      final tags = img.objectTags.map((t) => t.tagCategory).toList();
      if (tags.isEmpty) continue;

      for (var tag in tags) {
        if (!subjectLabels.contains(tag)) subjectLabels.add(tag);
        tabImages.putIfAbsent(tag, () => []);
        tabImages[tag]!.add(img);
      }
    }

    subjectLabels.sort();
  }

  /// 현재 선택된 탭의 이미지
  List<ImageItem> get currentImages {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    if (selectedTabIndex == 0) return imageProvider.allImages; // 전체 탭
    if (selectedTabIndex - 1 >= subjectLabels.length) return [];
    final label = subjectLabels[selectedTabIndex - 1];
    return tabImages[label] ?? [];
  }

  void _onTabSelected(int index) {
    setState(() => selectedTabIndex = index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final imageProvider = context.watch<CurrentProjectImagesProvider>();
    if (!imageProvider.isLoading) {
      _prepareSubjectLabels();
      if (selectedTabIndex >= subjectLabels.length + 1) selectedTabIndex = 0;
      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    final tabs = ["전체", ...subjectLabels];

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: Column(
        children: [
          SelectableBar(
            items: tabs,
            selectedIndex: selectedTabIndex,
            onItemSelected: _onTabSelected,
            height: deviceWidth * (44 / 375),
          ),
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
              onCancel: () => setState(() => isSelecting = false),
              isAllSelected: selectedImages.length == currentImages.length,
            )
                : SortingAppBar(
              screenTitle: screenTitle,
              imagesCount: currentImages.length,
              sortType: sortType ?? "recommend",
              deviceWidth: deviceWidth,
              onSelectMode: () => setState(() => isSelecting = true),
              onSortRecommend: () => setState(() => sortType = "recommend"),
              onSortTime: () => setState(() => sortType = "time"),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : currentImages.isEmpty
                ? const Center(
              child: Text(
                '선택된 주제의 이미지가 없습니다.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
                : PhotoGrid(
              images: currentImages,
              isSelecting: isSelecting,
              selectedImages: selectedImages,
              onSelectToggle: toggleSelection,
              onLongPressItem: () => setState(() => isSelecting = true),
            ),
          ),
        ],
      ),
    );
  }
}
