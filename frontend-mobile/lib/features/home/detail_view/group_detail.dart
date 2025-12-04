// hide_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_better_auth/core/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:provider/provider.dart';

import '../../../provider/current_project_provider.dart';


class GroupDetailScreen extends StatefulWidget {
  final GroupItem group;

  const GroupDetailScreen({Key? key, required this.group}) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends BasePhotoScreen<GroupDetailScreen> {
  final ApiService _api = ApiService();

  List<ImageItem> groupImages = [];
  bool isLoading = true;

  @override
  String get screenTitle => "그룹 사진";

  @override
  String get viewType => "GROUP";

  @override
  void initState() {
    super.initState();
    _loadGroupImages();
  }

  Future<void> _loadGroupImages() async {
    setState(() => isLoading = true);

    try {
      final imgs = await _api.fetchGroupImages(
        projectId: widget.group.projectId,
        groupId: widget.group.id,
      );

      setState(() {
        groupImages = imgs;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("그룹 이미지 로드 실패: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Future<void> onRefresh() async {
    await _loadGroupImages();
  }

  @override
  List<ImageItem> get imageItems => groupImages;
}

class ApiService {
  late final Dio _dio;

  ApiService() {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('API_BASE_URL not found in .env file');
    }

    _dio = FlutterBetterAuth.dioClient;
    _dio.options.baseUrl = baseUrl;
  }

  /// 프로젝트 내 특정 그룹 사진들 불러오기
  Future<List<ImageItem>> fetchGroupImages({
    required String projectId,
    required String groupId,
  }) async {
    try {
      final res = await _dio.get(
        '/images',
        queryParameters: {
          //'projectId': projectId,
          'groupId': groupId,
          //'isRejected': 'false',
          //'sort': 'createdAt',
          //'order': 'desc',
        },
      );

      final list = res.data['data'] as List<dynamic>;

      return list
          .map((e) => ImageItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

    } catch (e) {
      debugPrint("fetchGroupImages error: $e");
      return [];
    }
  }
}




/*
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_better_auth/core/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/group_card.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/features/start/service/project_service.dart'; // ImageItem import 필요
import 'package:photocurator/common/theme/colors.dart';
import 'package:provider/provider.dart';
import '../../../provider/current_project_provider.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupItem group;

  const GroupDetailScreen({Key? key, required this.group}) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List<ImageItem> groupImages = [];
  bool isLoading = true;
  bool isSelecting = false;
  List<ImageItem> selectedImages = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadGroupImages();
  }

  Future<void> _loadGroupImages() async {
    setState(() => isLoading = true);
    try {
      final dio = FlutterBetterAuth.dioClient;

      // 쿼리 파라미터 설정
      final response = await dio.get(
        '${dotenv.env['API_BASE_URL']}/images',
        queryParameters: {
          'projectId': widget.group.projectId,
          'groupId': widget.group.id,
          'isRejected': 'false',
          'page': 1,
          'limit': 100, // 필요에 따라 조절
          'sort': 'createdAt',
          'order': 'desc',
        },
      );

      final data = response.data['data'] as List<dynamic>;

      final images = data.map((json) => ImageItem.fromJson(json)).toList();

      setState(() {
        groupImages = images;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('그룹 이미지 로드 실패: $e');
      setState(() => isLoading = false);
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

  void selectAll() => setState(() => selectedImages = List.from(groupImages));
  void cancelSelection() => setState(() {
    isSelecting = false;
    selectedImages.clear();
  });

  Future<void> _refresh() async {
    await _loadGroupImages();
  }

  Future<void> _togglePick(ImageItem item, bool newValue) async {
    final success = await _apiService.updateImageSelection(
      imageId: item.id,
      isPicked: newValue,
      rating: item.rating,
    );
    if (!mounted) return;
    if (success) {
      setState(() {
        groupImages = groupImages
            .map((img) => img.id == item.id ? img.copyWith(isPicked: newValue) : img)
            .toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아요 변경에 실패했습니다.')),
      );
    }
  }

  Future<void> _deleteSelected() async {
    if (selectedImages.isEmpty) {
      cancelSelection();
      return;
    }
    final ids = selectedImages.map((e) => e.id).toList();
    final success = await _apiService.batchRejectImages(imageIds: ids);
    if (!mounted) return;
    if (success) {
      setState(() {
        groupImages = groupImages.where((img) => !ids.contains(img.id)).toList();
        cancelSelection();
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

  Future<void> _addToCompare() async {
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 이미지가 없습니다.')),
      );
      return;
    }
    final ids = selectedImages.map((e) => e.id).toList();
    final success = await _apiService.batchUpdateCompare(
      imageIds: ids,
      compareViewSelected: true,
    );
    if (!mounted) return;
    if (success) {
      context
          .read<CurrentProjectImagesProvider>()
          .updateCompareSelection(selectedImages, true);
      setState(() {
        groupImages = groupImages
            .map((img) => ids.contains(img.id)
                ? img.copyWith(compareViewSelected: true)
                : img)
            .toList();
        cancelSelection();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비교뷰에 담았습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비교뷰 담기에 실패했습니다.')),
      );
    }
  }

  Future<void> _downloadSelected() async {
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('다운로드할 이미지를 선택해주세요.')),
      );
      return;
    }

    final PermissionState permissionState = await PhotoManager.requestPermissionExtend();
    if (!permissionState.isAuth) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장을 위해 갤러리 접근 권한이 필요합니다.')),
      );
      return;
    }

    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API_BASE_URL이 설정되지 않았습니다.')),
      );
      return;
    }

    final dio = FlutterBetterAuth.dioClient;
    dio.options.baseUrl = baseUrl;

    for (final image in selectedImages) {
      try {
        final response = await dio.get(
          '/images/${image.id}/file',
          options: Options(responseType: ResponseType.bytes),
        );
        final data = response.data;
        final bytes = data is Uint8List
            ? data
            : data is List<int>
                ? Uint8List.fromList(data)
                : null;
        if (bytes == null) continue;

        await PhotoManager.editor.saveImage(
          bytes,
          filename: 'photo_${image.id}',
        );
      } catch (e) {
        debugPrint('Failed to download image ${image.id}: $e');
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('선택한 이미지를 저장했습니다.')),
    );
  }

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
          if (selectedImages.length == groupImages.length) {
            selectedImages.clear();
          } else {
            selectedImages = List.from(groupImages);
          }
          setState(() {});
        },
        onAddToCompare: _addToCompare,
        onDownloadSelected: _downloadSelected,
        onDeleteSelected: _deleteSelected,
        onCancel: cancelSelection,
        isAllSelected: selectedImages.length == groupImages.length,
      )
          : DetailAppBar(
        title: "그룹 상세",
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
          : groupImages.isEmpty
          ? const Center(child: Text("이미지가 없습니다."))
          : RefreshIndicator(
        onRefresh: _refresh,
        child: PhotoGrid(
          images: groupImages,
          isSelecting: isSelecting,
          selectedImages: selectedImages,
          onSelectToggle: toggleSelection,
          onLongPressItem: () => setState(() => isSelecting = true),
          onTogglePick: _togglePick,
        ),
      ),
    );
  }
}
*/