// setting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_better_auth/core/flutter_better_auth.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/bar/view/selectable_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../provider/current_project_provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends BasePhotoContent<SettingScreen> {
  @override
  String get screenTitle => "카메라/렌즈 사진";

  @override
  String get viewType => "ALL";

  @override
  String get sortType => "recommend";

  @override
  String? get groupBy => null;

  bool isLoading = true;
  int selectedTabIndex = 0;
  List<String> tabs = [];
  Map<String, List<ImageItem>> tabImages = {};
  List<ImageItem> selectedImages = [];

  late Dio _dio;

  @override
  void initState() {
    super.initState();
    _initDio();
  }

  void _initDio() {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null) throw Exception("API_BASE_URL missing");

    _dio = FlutterBetterAuth.dioClient;
    _dio.options.baseUrl = baseUrl;
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

  void cancelSelection() => setState(() => isSelecting = false);

  @override
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
        tabImages.updateAll(
          (_, list) => list.where((img) => !ids.contains(img.id)).toList(),
        );
        selectedImages.clear();
        isSelecting = false;
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

  // ------------------------------------------------
  // 🔥 여기에서 직접 /images/{id}/details 호출
  // ------------------------------------------------
  Future<Map<String, dynamic>?> _fetchImageDetail(String id) async {
    try {
      final res = await _dio.get("/images/$id/details");
      return res.data ?? res.data;
    } catch (e) {
      debugPrint("Error fetching detail for $id: $e");
      return null;
    }
  }

  // ------------------------------------------------
  // 🔥 전체 이미지 + 세부정보 불러와서 탭 구성
  // ------------------------------------------------
  Future<void> _loadAndPrepareTabs() async {
    setState(() => isLoading = true);

    final projectProvider = context.read<CurrentProjectProvider>();
    final projectId = projectProvider.currentProject?.id;

    if (projectId == null) {
      debugPrint("No current project selected.");
      setState(() => isLoading = false);
      return;
    }

    try {
      // 1. 프로젝트 모든 이미지 불러오기
      final allImages = await ApiService().fetchProjectImages(
        projectId: projectId,
        viewType: "ALL",
      );

      // 2. 각 이미지 세부 정보 직접 호출
      final futures = allImages.map((img) async {
        final detail = await _fetchImageDetail(img.id);
        if (detail == null) return null;

        final exif = detail['exif'] ?? {};
        final camera = exif['cameraModel'] ?? "Unknown Camera";
        final lens = exif['lensModel'] ?? "Unknown Lens";

        final key = "$camera & $lens";

        return {
          'key': key,
          'image': img,
        };
      });

      final results = await Future.wait(futures);

      Map<String, List<ImageItem>> grouped = {};

      for (var result in results) {
        if (result == null) continue;

        final key = result['key'] as String;
        final img = result['image'] as ImageItem;

        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(img);
      }

      setState(() {
        tabImages = grouped;
        tabs = grouped.keys.toList()..sort();
        selectedTabIndex = 0;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load tabs: $e");
      setState(() => isLoading = false);
    }
  }

  List<ImageItem> get currentImages {
    if (tabs.isEmpty) return [];
    return tabImages[tabs[selectedTabIndex]] ?? [];
  }

  void _onTabSelected(int index) {
    setState(() => selectedTabIndex = index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAndPrepareTabs();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: Column(
        children: [
          if (tabs.isNotEmpty)
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
              onDeleteSelected: onDeleteSelected,
              onCancel: () => cancelSelection(),
              isAllSelected: selectedImages.length == currentImages.length,
            )
                : SortingAppBar(
              screenTitle: screenTitle,
              imagesCount: currentImages.length,
              sortType: sortType,
              deviceWidth: deviceWidth,
              onSelectMode: () => setState(() => isSelecting = true),
              onSortRecommend: () {},
              onSortTime: () {},
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : currentImages.isEmpty
                ? const Center(
              child: Text(
                '선택된 카메라/렌즈의 이미지가 없습니다.',
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
