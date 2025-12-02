// date_screen.dart
import 'package:flutter/material.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/bar/view/selectable_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:provider/provider.dart';

import '../../../provider/current_project_provider.dart';


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
  List<String> dateLabels = ["전체"];
  List<String> normalizedDates = []; // 내부 필터용

  // =============================
  // 날짜 탭 생성 (중복 제거 버전)
  // =============================
  void _prepareDateLabels() {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final images = imageProvider.allImages;

    dateLabels = ["전체"];
    normalizedDates = [];

    // yyyy-MM-dd 로 날짜를 정규화 → Set으로 중복제거
    final dateKeySet = images.map((img) {
      final d = img.createdAt;
      return "${d.year}-${d.month}-${d.day}";
    }).toSet().toList()
      ..sort();

    normalizedDates = dateKeySet;

    // UI에서는 "12월 1일" 형태로 표시
    dateLabels.addAll(dateKeySet.map((dateKey) {
      final parts = dateKey.split("-");
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      return "$month월 $day일";
    }));
  }

  // =============================
  // 현재 탭에서 보여줄 이미지 필터링
  // =============================
  List<ImageItem> get currentImages {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final images = imageProvider.allImages;

    // "전체" 탭
    if (selectedTabIndex == 0) return images;

    // 날짜 탭 → normalizedDates 기준으로 필터링
    final normalizedKey = normalizedDates[selectedTabIndex - 1];
    final parts = normalizedKey.split("-");
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    return images.where((img) {
      final d = img.createdAt;
      return d.month == month && d.day == day;
    }).toList();
  }

  // =============================
  // Dependency 변경 시 날짜 라벨 업데이트
  // =============================
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final imageProvider = context.watch<CurrentProjectImagesProvider>();
    if (!imageProvider.isLoading) {
      _prepareDateLabels();
      if (selectedTabIndex >= dateLabels.length) {
        selectedTabIndex = 0;
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() => selectedTabIndex = index);
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final imageProvider = context.watch<CurrentProjectImagesProvider>();
    final isLoading = imageProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: Column(
        children: [
          // 날짜 선택 탭
          SelectableBar(
            items: dateLabels,
            selectedIndex: selectedTabIndex,
            onItemSelected: _onTabSelected,
            height: deviceWidth * (44 / 375),
          ),

          // 상단 앱바 (정렬/선택 모드)
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

          // 본문 영역
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
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



/*
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

  void _prepareDateLabels() {
    // 기존 라벨 초기화 (항상 "전체" 하나만 유지)
    dateLabels = ["전체"];

    final uniqueDates = images
        .map((img) => img.createdAt)
        .toSet()
        .toList()
      ..sort();

    dateLabels.addAll(uniqueDates.map((d) => "${d.month}월 ${d.day}일"));
  }


  List<ImageItem> get currentImages {
    if (selectedTabIndex == 0) return images;

    final label = dateLabels[selectedTabIndex];
    return images.where((img) {
      final date = img.createdAt;
      return label == "${date.month}월 ${date.day}일";
    }).toList();
  }

  @override
  void onImagesLoaded() {
    // images는 이 State의 멤버이므로 바로 접근 가능
    if (images.isEmpty) return;

    final uniqueDates = images
        .map((img) => img.createdAt)
        .toSet()
        .toList()
      ..sort();

    setState(() {
      dateLabels = ["전체"] + uniqueDates.map((d) => "${d.month}월 ${d.day}일").toList();
      // 선택된 탭 초기화 등 추가 로직 필요하면 여기서 처리
      if (selectedTabIndex >= dateLabels.length) selectedTabIndex = 0;
    });
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
*/