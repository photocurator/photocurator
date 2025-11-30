// date_screen.dart
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

  @override
  String get sortType => "time";

  @override
  String? get groupBy => "date";

  int selectedTabIndex = 0;
  List<String> dateLabels = ["전체"]; // 초기값

  // 이미지 로드 완료 후 라벨 준비
  void _prepareDateLabels() {
    final dates = images
        .map((img) => img.captureDatetime ?? img.createdAt)
        .map((d) => "${d.month}월 ${d.day}일")
        .toSet()
        .toList()
      ..sort((a, b) {
        final aParts = a.split(RegExp(r"[월일 ]")).where((e) => e.isNotEmpty).toList();
        final bParts = b.split(RegExp(r"[월일 ]")).where((e) => e.isNotEmpty).toList();
        return DateTime(DateTime.now().year, int.parse(aParts[0]), int.parse(aParts[1]))
            .compareTo(DateTime(DateTime.now().year, int.parse(bParts[0]), int.parse(bParts[1])));
      });
    dateLabels.addAll(dates);
  }

  List<ImageItem> get currentImages {
    if (selectedTabIndex == 0) return images;

    final label = dateLabels[selectedTabIndex];
    return images.where((img) {
      final date = img.captureDatetime ?? img.createdAt;
      return label == "${date.month}월 ${date.day}일";
    }).toList();
  }

  void _onTabSelected(int index) {
    setState(() => selectedTabIndex = index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isLoading && images.isNotEmpty && dateLabels.length <= 1) {
      _prepareDateLabels();
      setState(() {}); // 날짜 라벨 적용
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: Column(
        children: [
          // 1. 날짜 선택 바
          SelectableBar(
            items: dateLabels,
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
              sortType: sortType ?? "time",
              deviceWidth: deviceWidth,
              onSelectMode: () => setState(() => isSelecting = true),
              onSortRecommend: () =>
                  setState(() => sortType = "recommend"),
              onSortTime: () => setState(() => sortType = "time"),
            ),
          ),

          // 3. 이미지 그리드
          Expanded(
            child: isLoading
                ? Container(color: AppColors.wh1)
                : currentImages.isEmpty
                ? const Center(
              child: Text(
                '선택된 날짜의 이미지가 없습니다.',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
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
