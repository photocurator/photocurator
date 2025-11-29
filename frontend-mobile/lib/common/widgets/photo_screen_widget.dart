import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/current_project_provider.dart';
import './photo_item.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/theme/colors.dart';


mixin BaseScreenMixin<T extends StatefulWidget> on State<T> {
  bool isSelecting = false;
  bool isLoading = true;
  bool _hasLoadedImages = false;

  List<ImageItem> images = [];
  List<ImageItem> selectedImages = [];

  String? projectId;

  // 각 화면마다 viewType만 다르게 override함
  String get viewType;

  void toggleSelection(ImageItem item) {
    setState(() {
      if (selectedImages.contains(item)) {
        selectedImages.remove(item);
      } else {
        selectedImages.add(item);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentProject = context.watch<CurrentProjectProvider>();

    if (!_hasLoadedImages &&
        currentProject.projectId != null &&
        currentProject.projectId != projectId) {
      projectId = currentProject.projectId;
      _loadImages();
      _hasLoadedImages = true;
    }
  }

  Future<void> _loadImages() async {
    if (projectId == null) return;
    setState(() => isLoading = true);

    final api = ApiService();
    try {
      final fetchedImages = await api.fetchProjectImages(
        projectId!,
        viewType: 'ALL',
      );

      // 숨긴 사진만 필터
      final hiddenImages = fetchedImages.where((img) => img.isRejected).toList();

      setState(() {
        images = hiddenImages;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("이미지 불러오기 실패: $e");
    }
  }

  void selectAll() {
    setState(() {
      selectedImages = List.from(images);
    });
  }

  void cancelSelection() {
    setState(() => isSelecting = false);
  }
}

abstract class BasePhotoScreen<T extends StatefulWidget> extends State<T>
    with BaseScreenMixin<T> {

  String get screenTitle;

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      appBar: isSelecting
          ? SelectModeAppBar(
        title: selectedImages.isEmpty
            ? "전체 선택"
            : "${selectedImages.length}개 선택됨",
        deviceWidth: deviceWidth,

        // 전체 선택 토글
        onSelectAll: () {
          setState(() {
            if (selectedImages.length == images.length) {
              selectedImages.clear();      // 전체 해제
            } else {
              selectedImages = List.from(images); // 전체 선택
            }
          });
        },

        onCancel: () => setState(() => isSelecting = false),

        // 전체 선택 여부 전달
        isAllSelected: (selectedImages.length > 0) && (selectedImages.length == images.length),
      )
          : DetailAppBar(
        title: screenTitle,
        rightWidget: GestureDetector(
          onTap: () {
            setState(() => isSelecting = true);
          },
          child: Text(
            "선택",
            style: TextStyle(
              fontSize:
              deviceWidth * (50 / 375) * (14 / 50),
              color: AppColors.lgADB5BD,
            ),
          ),
        ),
      ),
      body: isLoading
          ? Container(height: 1, color: AppColors.lgE9ECEF)
          : Column(
        children: [
          Container(height: 1, color: AppColors.lgE9ECEF),
          Expanded(
            child: PhotoGrid(
              images: images,
              isSelecting: isSelecting,
              selectedImages: selectedImages,
              onSelectToggle: toggleSelection,
            ),
          ),
        ],
      ),
    );
  }
}

// 홈 화면에 쓸 거
abstract class BasePhotoContent<T extends StatefulWidget> extends State<T>
    with BaseScreenMixin<T> {
  String get screenTitle;
  String sortType = "recommend";

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    sortImages(images, sortType);

    return Scaffold(
      backgroundColor: AppColors.wh1,
      appBar: isSelecting
          ? SelectModeAppBar(
        title: selectedImages.isEmpty
            ? "전체 선택"
            : "${selectedImages.length}개 선택됨",
        deviceWidth: deviceWidth,
        onSelectAll: () {
          setState(() {
            if (selectedImages.length == images.length) {
              selectedImages.clear();
            } else {
              selectedImages = List.from(images);
            }
          });
        },
        onCancel: () => setState(() => isSelecting = false),
        isAllSelected: selectedImages.length == images.length,
      )
          : SortingAppBar(
        screenTitle: screenTitle,
        imagesCount: images.length,
        sortType: sortType,
        deviceWidth: deviceWidth,
        onSelectMode: () => setState(() => isSelecting = true),
        onSortRecommend: () => setState(() => sortType = "recommend"),
        onSortTime: () => setState(() => sortType = "time"),
      ),
      body: isLoading
          ? SizedBox(height: 1,)
          : PhotoGrid(
        images: images,
        isSelecting: isSelecting,
        selectedImages: selectedImages,
        onSelectToggle: toggleSelection,
        onLongPressItem: () => setState(() => isSelecting = true),
      ),
    );
  }

  void sortImages(List<ImageItem> images, String sortType) {
    if (sortType == "recommend") {
      images.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    } else if (sortType == "time") {
      images.sort((a, b) {
        final timeA = a.captureDatetime ?? a.createdAt;
        final timeB = b.captureDatetime ?? b.createdAt;
        return timeB.compareTo(timeA);
      });
    }
  }
}


