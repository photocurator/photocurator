import 'package:flutter/material.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/bar/view/selectable_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';

class DateScreen extends StatefulWidget {
  const DateScreen({Key? key}) : super(key: key);

  @override
  _DateScreenState createState() => _DateScreenState();
}

class _DateScreenState extends BasePhotoContent<DateScreen> {
  @override
  String get screenTitle => "날짜별 사진";

  @override
  String get viewType => "ALL";

  late List<String> dateLabels;
  late Map<String, List<ImageItem>> imagesByDate;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _prepareDateMapping();
  }

  void _prepareDateMapping() {
    imagesByDate = {"전체": List.from(images)};

    for (var img in images) {
      final date = img.captureDatetime ?? img.createdAt;
      final label = "${date.month}월 ${date.day}일";
      imagesByDate.putIfAbsent(label, () => []).add(img);
    }

    final otherDates = imagesByDate.keys.where((k) => k != "전체").toList()
      ..sort((a, b) {
        final aParts =
        a.split(RegExp(r"[월일 ]")).where((e) => e.isNotEmpty).toList();
        final bParts =
        b.split(RegExp(r"[월일 ]")).where((e) => e.isNotEmpty).toList();
        return DateTime(DateTime.now().year, int.parse(aParts[0]),
            int.parse(aParts[1]))
            .compareTo(DateTime(DateTime.now().year, int.parse(bParts[0]),
            int.parse(bParts[1])));
      });

    dateLabels = ["전체", ...otherDates];
  }

  void _onTabSelected(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final currentImages = imagesByDate[dateLabels[selectedIndex]] ?? [];

    sortImages(currentImages, sortType);

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: Column(
        children: [
          // 1. 날짜 선택 바 (항상 보임)
          SelectableBar(
            items: dateLabels,
            selectedIndex: selectedIndex,
            onItemSelected: _onTabSelected,
            height: deviceWidth * (44/375),
          ),
          // 2. 선택 / 정렬 바 (항상 보임)
          SizedBox(
            height: deviceWidth * (40/375),
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
          // 3. 이미지 그리드 / 로딩 표시
          Expanded(
            child: isLoading
                ? SizedBox(height: 1,)
                : currentImages.isEmpty
                ? const Center(
              child: Text(
                '선택된 날짜의 이미지가 없습니다.',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
                : PhotoGrid(
              images: currentImages,
              isSelecting: isSelecting,
              selectedImages: selectedImages,
              onSelectToggle: toggleSelection,
              onLongPressItem: () =>
                  setState(() => isSelecting = true),
            ),
          ),
        ],
      ),
    );
  }
  }
