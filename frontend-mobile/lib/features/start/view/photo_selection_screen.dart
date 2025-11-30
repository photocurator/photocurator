
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/widgets/photo_grid_item.dart';
import 'package:photocurator/features/start/service/project_service.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoSelectionScreen extends StatefulWidget {
  final String projectName;
  const PhotoSelectionScreen({super.key, required this.projectName});

  @override
  State<PhotoSelectionScreen> createState() => _PhotoSelectionScreenState();
}

class _PhotoSelectionScreenState extends State<PhotoSelectionScreen> {
  List<AssetEntity> _assets = [];
  List<AssetEntity> _selectedAssets = [];
  final ProjectService _projectService = ProjectService();

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );
      if (albums.isNotEmpty) {
        final List<AssetEntity> assets = await albums.first.getAssetListPaged(
          page: 0,
          size: 1000, // Fetch a large number of assets
        );
        setState(() {
          _assets = assets;
        });
      }
    } else {
      // Handle permission denial
      // You might want to show a dialog or a message to the user
      print("Photo access permission denied.");
    }
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        _selectedAssets.add(asset);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedAssets.length == _assets.length) {
        _selectedAssets.clear();
      } else {
        _selectedAssets = List.from(_assets);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // isSelected 판단 로직
    final bool isAllSelected = _assets.isNotEmpty && _selectedAssets.length == _assets.length;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      appBar: AppBar(
        backgroundColor: AppColors.wh1,
        elevation: 0,
        automaticallyImplyLeading: false, // 기본 뒤로가기 버튼 제거 (디자인에 맞춤)
        titleSpacing: 0, // 타이틀 패딩 직접 제어

        // [왼쪽] 전체 선택 버튼 영역
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: GestureDetector(
            onTap: _toggleSelectAll,
            behavior: HitTestBehavior.translucent, // 텍스트만 눌러도 반응하도록
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  isAllSelected
                      ? 'assets/icons/button/selected_button.svg'
                      : 'assets/icons/button/unselected_button.svg',
                  width: 14,
                  height: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedAssets.isEmpty
                      ? '전체 선택'
                      : '${_selectedAssets.length}개 선택됨',
                  style: const TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: 16,
                    color: AppColors.dg1C1F23,
                  ),
                ),
              ],
            ),
          ),
        ),

        // [오른쪽] 취소 버튼 영역
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: TextButton(
              onPressed: () {
                context.go('/start');
              },
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'NotoSansRegular',
                  fontSize: 14,
                  color: AppColors.dg495057,
                ),
              ),
            ),
          ),
        ],

        // [중요] 상단바 아래 구분선 (SizedBox 대신 AppBar의 bottom 속성 사용)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.lgE9ECEF,
            height: 1.0,
          ),
        ),
      ),

      // 사진 그리드
      body: GridView.builder(
        padding: EdgeInsets.zero, // 상단 여백 제거 (구분선과 붙도록)
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 1, // 간격 1px (디자인에 따라 조정)
          crossAxisSpacing: 1,
        ),
        itemCount: _assets.length,
        itemBuilder: (context, index) {
          final asset = _assets[index];
          return PhotoGridItem(
            asset: asset,
            isSelected: _selectedAssets.contains(asset),
            onTap: () => _toggleSelection(asset),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: _selectedAssets.isEmpty
            ? OutlinedButton(
                onPressed: () async {
                  final createdProject = await _projectService.createProject(widget.projectName);
                  if (createdProject != null) {
                    // Navigate to home or another screen
                    context.go('/start');
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  textStyle: const TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('건너뛰기'),
              )
            : ElevatedButton(
                onPressed: () async {
                  List<String> photoPaths = [];
                  for (var asset in _selectedAssets) {
                    final file = await asset.file;
                    if (file != null) {
                      photoPaths.add(file.path);
                    }
                  }
                  
                  final createdProject = await _projectService.createProject(widget.projectName);

                  if (createdProject != null) {
                    if (photoPaths.isNotEmpty) {
                      final message = await _projectService.uploadImages(createdProject.id, photoPaths);
                      if (message != null) {
                        print(message);
                      }
                    }
                    context.go('/start');
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.wh1,
                  textStyle: const TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('완료'),
              ),
      ),
    );
  }
}
