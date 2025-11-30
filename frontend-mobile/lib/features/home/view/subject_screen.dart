// subject_screen.dart
import 'package:flutter/material.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/bar/view/selectable_bar.dart';
import 'package:photocurator/common/theme/colors.dart';

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
  String? get groupBy => null; // 백엔드에서 주제 그룹화 지원 X

  int selectedTabIndex = 0;
  List<String> subjectLabels = []; // API 호출 후 objectTags에서 추출
  Map<String, List<ImageItem>> tabImages = {};

  List<ImageItem> get currentImages {
    if (selectedTabIndex >= subjectLabels.length) return [];
    final label = subjectLabels[selectedTabIndex];
    return tabImages[label] ?? [];
  }

  @override
  void didUpdateWidget(covariant SubjectScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isLoading && images.isNotEmpty && subjectLabels.isEmpty) {
      _prepareSubjectLabels();
    }
  }

  void _prepareSubjectLabels() {
    final allTags = <String>{};
    for (var img in images) {
      for (var tag in img.objectTags ?? []) {
        if (tag.tagCategory != null && tag.tagCategory!.isNotEmpty) {
          allTags.add(tag.tagCategory!);
        }
      }
    }

    subjectLabels = allTags.toList();
    subjectLabels.sort();

    // 이미지 그룹핑
    tabImages = {for (var label in subjectLabels) label: []};
    for (var img in images) {
      final categories = (img.objectTags ?? [])
          .map((t) => t.tagCategory)
          .where((c) => c != null)
          .cast<String>()
          .toList();
      for (var cat in categories) {
        if (tabImages.containsKey(cat)) {
          tabImages[cat]!.add(img);
        }
      }
    }
    setState(() {}); // UI 갱신
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
          // 1. 주제 선택 바
          if (subjectLabels.isNotEmpty)
            SelectableBar(
              items: subjectLabels,
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
              onCancel: () => setState(() => isSelecting = false),
              isAllSelected:
              selectedImages.length == currentImages.length,
            )
                : SortingAppBar(
              screenTitle: screenTitle,
              imagesCount: currentImages.length,
              sortType: sortType,
              deviceWidth: deviceWidth,
              onSelectMode: () => setState(() => isSelecting = true),
              onSortRecommend: () => setState(() => sortType = "recommend"),
              onSortTime: () => setState(() => sortType = "time"),
            ),
          ),

          // 3. 이미지 그리드
          Expanded(
            child: isLoading
                ? const SizedBox.shrink()
                : currentImages.isEmpty
                ? const Center(
              child: Text(
                '선택된 주제의 이미지가 없습니다.',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
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
