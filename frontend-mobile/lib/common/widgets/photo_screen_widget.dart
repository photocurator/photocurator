// photo_screen_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../../provider/current_project_provider.dart';
import './photo_item.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/theme/colors.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:photocurator/provider/current_project_provider.dart';
import 'photo_item.dart';

abstract class BasePhotoScreen<T extends StatefulWidget> extends State<T> {
  String get screenTitle;
  String get viewType; // 'ALL', 'TRASH', 'BEST_SHOTS', 'I_PICKED', 'HIDDEN'

  bool isSelecting = false;
  List<ImageItem> selectedImages = [];

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
          : PhotoGrid(
        images: images,
        isSelecting: isSelecting,
        selectedImages: selectedImages,
        onSelectToggle: toggleSelection,
        onLongPressItem: () => setState(() => isSelecting = true),
      ),
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
  String sortType = "recommend"; // 기본 정렬

  bool isSelecting = false;
  List<ImageItem> selectedImages = [];

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
          : PhotoGrid(
        images: images,
        isSelecting: isSelecting,
        selectedImages: selectedImages,
        onSelectToggle: toggleSelection,
        onLongPressItem: () => setState(() => isSelecting = true),
      ),
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
        return provider.pickedImages;
      case 'HIDDEN':
        return provider.hiddenImages;
      default:
        return [];
    }
  }
}




typedef FilterFunction = List<ImageItem> Function(List<ImageItem>);
typedef GroupFunction = Map<String, List<ImageItem>> Function(List<ImageItem>);

class BaseImageState extends StatefulWidget {
  final Future<List<ImageItem>> Function() loadImages;
  final FilterFunction? filterFunction;
  final GroupFunction? groupFunction;
  final Widget Function(List<ImageItem> images, bool isSelecting, List<ImageItem> selectedImages, Function(ImageItem) toggleSelection) gridBuilder;

  const BaseImageState({
    super.key,
    required this.loadImages,
    required this.gridBuilder,
    this.filterFunction,
    this.groupFunction,
  });

  @override
  State<BaseImageState> createState() => _BaseImageStateState();
}

class _BaseImageStateState extends State<BaseImageState> {
  bool isLoading = true;
  bool isSelecting = false;
  List<ImageItem> images = [];
  List<ImageItem> selectedImages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    images = await widget.loadImages();
    setState(() => isLoading = false);
  }

  void updateImage(ImageItem updated) {
    final index = images.indexWhere((img) => img.id == updated.id);
    if (index != -1) {
      setState(() => images[index] = updated);
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (widget.groupFunction != null) {
      final groups = widget.groupFunction!(images);
      return DefaultTabController(
        length: groups.keys.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: groups.keys.map((k) => Tab(text: k)).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: groups.values.map((imgs) {
                  return widget.gridBuilder(imgs, isSelecting, selectedImages, toggleSelection);
                }).toList(),
              ),
            ),
          ],
        ),
      );
    } else {
      final displayImages = widget.filterFunction != null ? widget.filterFunction!(images) : images;
      return widget.gridBuilder(displayImages, isSelecting, selectedImages, toggleSelection);
    }
  }
}
