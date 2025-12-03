import 'package:flutter/material.dart';
import 'package:flutter_better_auth/core/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/group_card.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/features/start/service/project_service.dart'; // ImageItem import 필요
import 'package:photocurator/common/theme/colors.dart';
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
