import 'package:flutter/material.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/bar/view/selectable_bar.dart';
import 'package:photocurator/common/theme/colors.dart';

class GradeScreen extends StatefulWidget {
  const GradeScreen({Key? key}) : super(key: key);

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends BasePhotoContent<GradeScreen> {
  @override
  String get screenTitle => "등급별 사진";

  @override
  String get viewType => "ALL";

  @override
  String get sortType => "recommend";

  @override
  String? get groupBy => null;

  final List<String> gradeLabels = ["Best Shot", "A컷", "B컷"];

  Map<String, List<ImageItem>> tabImages = {
    "Best Shot": [],
    "A컷": [],
    "B컷": [],
  };

  int selectedTabIndex = 0;
  bool isLoading = true;

  List<ImageItem> get currentImages {
    final label = gradeLabels[selectedTabIndex];
    return tabImages[label] ?? [];
  }

  Future<void> _loadImages() async {
    if (projectId == null) return;

    setState(() => isLoading = true);

    try {
      final api = ApiService();

      // 1. Best Shot 이미지 가져오기
      final bestImages = await api.fetchProjectImages(
        projectId: projectId!,
        viewType: "BEST",
      );
      final bestIds = bestImages.map((e) => e.id).toSet();

      // 2. 전체 이미지 가져오기 (숨김 제외)
      final allImages = await api.fetchProjectImages(
        projectId: projectId!,
        viewType: "ALL",
      );

      // Best Shot 제외 + 숨김(isRejected) 제외
      final filteredImages = allImages
          .where((img) => !bestIds.contains(img.id) && !img.isRejected)
          .toList();

      // 3. A컷 / B컷 분류
      final aCut = filteredImages
          .where((img) => (img.score ?? 0) >= 50 && (img.score ?? 0) < 80)
          .toList();
      final bCut = filteredImages
          .where((img) => (img.score ?? 0) < 50)
          .toList();

      // 4. 상태 한 번에 갱신
      if (!mounted) return;
      setState(() {
        tabImages["Best Shot"] = bestImages;
        tabImages["A컷"] = aCut;
        tabImages["B컷"] = bCut;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      print("이미지 불러오기 실패: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // images가 비어 있고 아직 로딩 중이 아니면 이미지 로드 시작
    if (!isLoading && images.isEmpty) {
      _loadImages(); // 직접 호출
    }
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
          // 1. 등급 선택 바
          SelectableBar(
            items: gradeLabels,
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

          // 3. 이미지 그리드
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : currentImages.isEmpty
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
            ),
          ),
        ],
      ),
    );
  }
}
