// photo_screen_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../../provider/current_project_provider.dart';
import './photo_item.dart';
import './action_bar.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/theme/colors.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:photocurator/provider/current_project_provider.dart';

abstract class BasePhotoScreen<T extends StatefulWidget> extends State<T> {
  String get screenTitle;
  String get viewType; // 'ALL', 'TRASH', 'BEST_SHOTS', 'I_PICKED', 'HIDDEN'
  bool get showBottomActionBar => false; // 기본은 하단 액션바 숨김

  bool isSelecting = false;
  List<ImageItem> selectedImages = [];

  Future<void> refreshImages() async {
    final projectId = context.read<CurrentProjectProvider>().currentProject?.id;
    if (projectId == null) return;
    await context.read<CurrentProjectImagesProvider>().loadAllImages(projectId);
  }

  Future<void> onDeleteSelected() async {
    if (selectedImages.isEmpty) {
      cancelSelection();
      return;
    }
    final ids = selectedImages.map((e) => e.id).toList();
    final success = await ApiService().batchRejectImages(imageIds: ids);
    if (!mounted) return;
    if (success) {
      context.read<CurrentProjectImagesProvider>().markAsRejected(ids);
      setState(() {
        isSelecting = false;
        selectedImages.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 이미지를 삭제했습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제에 실패했습니다.')),
      );
    }
  }

  Future<void> togglePick(ImageItem item, bool newValue) async {
    final success = await ApiService().updateImageSelection(
      imageId: item.id,
      isPicked: newValue,
      rating: item.rating,
    );
    if (!mounted) return;
    if (success) {
      context.read<CurrentProjectImagesProvider>().updatePickStatus(item.id, newValue);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아요를 변경하지 못했습니다.')),
      );
    }
  }

  void toggleSelection(ImageItem item) {
    setState(() {
      if (selectedImages.contains(item)) {
        selectedImages.remove(item);
      } else {
        selectedImages.add(item);
      }
    });
  }

  void selectAll(List<ImageItem> images) => setState(() => selectedImages = List.from(images));
  void cancelSelection() => setState(() => isSelecting = false);

  // --- 추가: 하단 액션바 ---
  Widget _buildBottomActionBar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
          color: AppColors.wh1,
          border: Border(top: BorderSide(color: AppColors.lgE9ECEF))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton('좋아요', 'assets/icons/button/empty_heart_gray.svg'),
          _buildActionButton('복사', 'assets/icons/button/duplicate_gray.svg'),
          _buildActionButton('다운로드', 'assets/icons/button/arrow_collapse_down_gray.svg'),
          _buildActionButton('삭제', 'assets/icons/button/empty_bin_gray.svg'),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, String iconPath) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(iconPath, width: 20, height: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.dg495057)),
      ],
    );
  }
  // --- 여기까지 액션바 추가 ---

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final imageProvider = context.watch<CurrentProjectImagesProvider>();
    final images = _getImagesFromProvider(imageProvider);
    final isLoading = imageProvider.isLoading;

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
        onDeleteSelected: onDeleteSelected,
        onCancel: () => cancelSelection(),
        isAllSelected: selectedImages.length == images.length,
      )
          : DetailAppBar(
        title: screenTitle,
        rightWidget: GestureDetector(
          onTap: () => setState(() => isSelecting = true),
          child: Text(
            "선택",
            style: TextStyle(
              fontSize: deviceWidth * (50 / 375) * (14 / 50),
              color: AppColors.lgADB5BD,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: refreshImages,
        child: PhotoGrid(
          images: images,
          isSelecting: isSelecting,
          selectedImages: selectedImages,
          onSelectToggle: toggleSelection,
          onLongPressItem: () => setState(() => isSelecting = true),
          onTogglePick: togglePick,
        ),
      ),

        bottomSheet:
        (!isSelecting && showBottomActionBar) ? _buildBottomActionBar() : null,
    );
  }

  List<ImageItem> _getImagesFromProvider(CurrentProjectImagesProvider provider) {
    switch (viewType) {
      case 'ALL':
        return provider.allImages;
      case 'TRASH':
        return provider.trashImages;
      case 'BEST_SHOTS':
        return provider.bestShotImages;
      case 'I_PICKED':
      case 'PICKED':
        return provider.pickedImages;
      case 'HIDDEN':
        return provider.hiddenImages;
      default:
        return [];
    }
  }
}

abstract class BasePhotoContent<T extends StatefulWidget> extends State<T> {
  String get screenTitle;
  String get viewType;
  bool get showBottomActionBar => false; // 기본은 하단 액션바 숨김
  String sortType = "recommend"; // 기본 정렬

  bool isSelecting = false;
  List<ImageItem> selectedImages = [];

  Future<void> refreshImages() async {
    final projectId = context.read<CurrentProjectProvider>().currentProject?.id;
    if (projectId == null) return;
    await context.read<CurrentProjectImagesProvider>().loadAllImages(projectId);
  }

  Future<void> onDeleteSelected() async {
    if (selectedImages.isEmpty) {
      cancelSelection();
      return;
    }
    final ids = selectedImages.map((e) => e.id).toList();
    final success = await ApiService().batchRejectImages(imageIds: ids);
    if (!mounted) return;
    if (success) {
      context.read<CurrentProjectImagesProvider>().markAsRejected(ids);
      setState(() {
        isSelecting = false;
        selectedImages.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 이미지를 삭제했습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제에 실패했습니다.')),
      );
    }
  }

  Future<void> togglePick(ImageItem item, bool newValue) async {
    final success = await ApiService().updateImageSelection(
      imageId: item.id,
      isPicked: newValue,
      rating: item.rating,
    );
    if (!mounted) return;
    if (success) {
      context.read<CurrentProjectImagesProvider>().updatePickStatus(item.id, newValue);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아요를 변경하지 못했습니다.')),
      );
    }
  }

  void toggleSelection(ImageItem item) {
    setState(() {
      if (selectedImages.contains(item)) {
        selectedImages.remove(item);
      } else {
        selectedImages.add(item);
      }
    });
  }

  void selectAll(List<ImageItem> images) => setState(() => selectedImages = List.from(images));
  void cancelSelection() => setState(() => isSelecting = false);

  // --- 추가: 하단 액션바 ---
  Widget _buildBottomActionBar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
          color: AppColors.wh1,
          border: Border(top: BorderSide(color: AppColors.lgE9ECEF))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton('좋아요', 'assets/icons/button/empty_heart_gray.svg'),
          _buildActionButton('복사', 'assets/icons/button/duplicate_gray.svg'),
          _buildActionButton('비교 뷰', 'assets/icons/button/full_screen_gray.svg'),
          _buildActionButton('다운로드', 'assets/icons/button/arrow_collapse_down_gray.svg'),
          _buildActionButton('삭제', 'assets/icons/button/empty_bin_gray.svg'),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, String iconPath) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(iconPath, width: 20, height: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.dg495057)),
      ],
    );
  }
  // --- 여기까지 액션바 추가 ---

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final imageProvider = context.watch<CurrentProjectImagesProvider>();
    final images = _getImagesFromProvider(imageProvider);
    final isLoading = imageProvider.isLoading;

    // 정렬
    _sortImages(images);

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
        onDeleteSelected: onDeleteSelected,
        onCancel: () => cancelSelection(),
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
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: refreshImages,
        child: PhotoGrid(
          images: images,
          isSelecting: isSelecting,
          selectedImages: selectedImages,
          onSelectToggle: toggleSelection,
          onLongPressItem: () => setState(() => isSelecting = true),
          onTogglePick: togglePick,
        ),
      ),

        bottomSheet: (!isSelecting && showBottomActionBar)
            ? Container(
          margin: EdgeInsets.only(bottom: deviceWidth * (60 / 375)),
          child: ActionBottomBar(
            selectedImages: selectedImages,
          ),
        )
            : null

    );
  }

  void _sortImages(List<ImageItem> images) {
    if (sortType == "recommend") {
      images.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    } else if (sortType == "time") {
      images.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  List<ImageItem> _getImagesFromProvider(CurrentProjectImagesProvider provider) {
    switch (viewType) {
      case 'ALL':
        return provider.allImages;
      case 'TRASH':
        return provider.trashImages;
      case 'BEST_SHOTS':
        return provider.bestShotImages;
      case 'I_PICKED':
      case 'PICKED':
        return provider.pickedImages;
      case 'HIDDEN':
        return provider.hiddenImages;
      default:
        return [];
    }
  }
}



