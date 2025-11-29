
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/widgets/photo_grid_item.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoSelectionScreen extends StatefulWidget {
  const PhotoSelectionScreen({super.key});

  @override
  State<PhotoSelectionScreen> createState() => _PhotoSelectionScreenState();
}

class _PhotoSelectionScreenState extends State<PhotoSelectionScreen> {
  List<AssetEntity> _assets = [];
  List<AssetEntity> _selectedAssets = [];

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
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.wh1,
      appBar: AppBar(
        backgroundColor: AppColors.wh1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dg1C1F23),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: _toggleSelectAll,
          child: Row(
            children: [
              SvgPicture.asset(
                _selectedAssets.length == _assets.length
                    ? 'assets/icons/button/selected_button.svg'
                    : 'assets/icons/button/unselected_button.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedAssets.isEmpty
                    ? '전체선택'
                    : '${_selectedAssets.length}개 선택됨',
                style: const TextStyle(
                  fontFamily: 'NotoSansMedium',
                  fontSize: 20,
                  color: AppColors.dg1C1F23,
                ),
              ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.lgE9ECEF,
            height: 1.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Handle cancel action
              Navigator.of(context).pop();
            },
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: 'NotoSansRegular',
                fontSize: 14,
                color: AppColors.dg495057,
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
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
                onPressed: () {
                  // Handle Skip
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
                onPressed: () {
                  // Handle Done
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
