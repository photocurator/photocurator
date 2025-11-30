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

mixin BaseScreenMixin<T extends StatefulWidget> on State<T> {
  bool isSelecting = false;
  bool isLoading = true;

  List<ImageItem> images = [];
  List<ImageItem> selectedImages = [];

  String? projectId;

  String get viewType;
  String? get sortType;
  String? get groupBy;

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

    final currentProjectProvider = context.watch<CurrentProjectProvider>();
    final currentProjectId = currentProjectProvider.currentProject?.id;

    // 프로젝트가 있고, 이전과 다른 경우에만 _loadImages 호출
    if (currentProjectId != null && currentProjectId != projectId) {
      projectId = currentProjectId;
      _loadImages();
    }
  }

  @protected
  void onImagesLoaded() {
    // 기본 구현은 빈 함수. 하위 클래스에서 override 가능.
  }

  Future<void> _loadImages() async {
    if (projectId == null) return;

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final dio = FlutterBetterAuth.dioClient; // 인증 적용

      final response = await dio.get(
        '${dotenv.env['API_BASE_URL']}/projects/$projectId/images',
        queryParameters: {
          'viewType': viewType,
          'sortType': sortType,
          'groupBy': groupBy,
        },
      );

      List<ImageItem> fetchedImages = [];
      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        fetchedImages = dataList.map((json) => ImageItem.fromJson(json)).toList();
      } else {
        print('이미지 불러오기 실패: ${response.statusCode}');
      }

      print('fetchedImages: $fetchedImages');

      if (!mounted) return;
      setState(() {
        images = fetchedImages;
        isLoading = false;
      });

      // 이미지를 세팅한 직후에 훅 호출
      onImagesLoaded();

    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      print("이미지 불러오기 실패: $e");
    }
  }

  void selectAll() => setState(() => selectedImages = List.from(images));
  void cancelSelection() => setState(() => isSelecting = false);
}


abstract class BasePhotoScreen<T extends StatefulWidget> extends State<T>
    with BaseScreenMixin<T> {
  String get screenTitle;

  @protected
  void onImagesLoaded() {}

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
          ? const SizedBox(height: 1)
          : PhotoGrid(
        images: images,
        isSelecting: isSelecting,
        selectedImages: selectedImages,
        onSelectToggle: toggleSelection,
        onLongPressItem: () => setState(() => isSelecting = true),
      ),
    );
  }
}

abstract class BasePhotoContent<T extends StatefulWidget> extends State<T>
    with BaseScreenMixin<T> {
  String get screenTitle;
  String sortType = "recommend";

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    _sortImages();

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
          ? const SizedBox(height: 1)
          : PhotoGrid(
        images: images,
        isSelecting: isSelecting,
        selectedImages: selectedImages,
        onSelectToggle: toggleSelection,
        onLongPressItem: () => setState(() => isSelecting = true),
      ),
    );
  }

  void _sortImages() {
    if (sortType == "recommend") {
      images.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    } else if (sortType == "time") {
      images.sort((a, b) {
        final timeA = a.createdAt;
        final timeB = b.createdAt;
        return timeB.compareTo(timeA);
      });
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
