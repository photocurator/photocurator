import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/provider/current_project_provider.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:dio/dio.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final Map<String, Future<Uint8List?>> _imageCache = {};
  // Viewport controllers
  final TransformationController _topController = TransformationController();
  final TransformationController _bottomController = TransformationController();

  // Selected indices
  int _topIndex = 0;
  int _bottomIndex = 1;

  // Sync state
  bool _isSyncOn = false;

  // Internal flag to prevent infinite loops during sync
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _topController.addListener(_onTopChanged);
    _bottomController.addListener(_onBottomChanged);

    // Ensure we have valid initial indices if list is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CurrentProjectImagesProvider>();
      if (provider.compareImages.length > 1) {
        setState(() {
          _topIndex = 0;
          _bottomIndex = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _topController.removeListener(_onTopChanged);
    _bottomController.removeListener(_onBottomChanged);
    _topController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  void _onTopChanged() {
    if (!_isSyncOn || _isUpdating) return;
    _isUpdating = true;
    _bottomController.value = _topController.value;
    _isUpdating = false;
  }

  void _onBottomChanged() {
    if (!_isSyncOn || _isUpdating) return;
    _isUpdating = true;
    _topController.value = _bottomController.value;
    _isUpdating = false;
  }

  void _toggleSync() {
    setState(() {
      _isSyncOn = !_isSyncOn;
      if (_isSyncOn) {
        // Reset scale/position when enabling sync for consistency?
        // Or just sync bottom to top.
        _topController.value = Matrix4.identity();
        _bottomController.value = Matrix4.identity();
      }
    });
  }

  void _handleLike(ImageItem item) async {
    final newStatus = !item.isPicked;
    // Optimistic update
    context.read<CurrentProjectImagesProvider>().updateCompareImageLike(item.id, newStatus);

    try {
      await ApiService().updateImageSelection(isPicked: newStatus, imageId: item.id);
    } catch (e) {
      // Revert if failed
      if (mounted) {
        context.read<CurrentProjectImagesProvider>().updateCompareImageLike(item.id, !newStatus);
        Fluttertoast.showToast(msg: "Failed to update like status");
      }
    }
  }

  void _handleRemove(ImageItem item) async {
    // Optimistic update
    context.read<CurrentProjectImagesProvider>().removeCompareImage(item.id);

    // Adjust indices if needed
    setState(() {
       // Simple bounds check
       final count = context.read<CurrentProjectImagesProvider>().compareImages.length;
       if (_topIndex >= count) _topIndex = count > 0 ? count - 1 : 0;
       if (_bottomIndex >= count) _bottomIndex = count > 0 ? count - 1 : 0;
    });

    // Show Toast
    // Custom Toast or Fluttertoast
    _showCustomToast(context);

    try {
      await ApiService().updateImageCompareStatus(item.id, false);
    } catch (e) {
      // Revert logic is complex for removal (need to re-add at specific index).
      // For now, assume success or reload.
      // If critical, we should reload the list.
    }
  }

  void _showCustomToast(BuildContext context) {
    FToast fToast = FToast();
    fToast.init(context);

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: AppColors.wh1,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
             padding: EdgeInsets.all(4),
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               border: Border.all(color: AppColors.secondary, width: 1.5, style: BorderStyle.solid), // Dashed border hard to do simply, solid for now or custom painter
             ),
             child: Icon(Icons.close, color: AppColors.secondary, size: 14),
          ),
          const SizedBox(width: 12.0),
          const Text("비교 뷰에서 제거 완료", style: TextStyle(color: Colors.black87)),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.CENTER,
      toastDuration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CurrentProjectImagesProvider>();
    final images = provider.compareImages;
    final deviceWidth = MediaQuery.of(context).size.width;

    // Drop cached entries for images that were removed so UI updates cleanly after delete
    final currentIds = images.map((e) => e.id).toSet();
    _imageCache.keys
        .where((id) => !currentIds.contains(id))
        .toList()
        .forEach(_imageCache.remove);

    // Safety check
    if (images.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.wh1,
        appBar: DetailAppBar(
          title: "비교 뷰",
          rightWidget: _buildDoneButton(context, deviceWidth),
        ),
        body: Center(child: Text("비교할 이미지가 없습니다.")),
      );
    }

    // Ensure indices are valid
    if (_topIndex >= images.length) _topIndex = 0;
    if (_bottomIndex >= images.length) _bottomIndex = images.length > 1 ? 1 : 0;

    final topImage = images[_topIndex];
    final bottomImage = images[_bottomIndex];

    return Scaffold(
      backgroundColor: AppColors.wh1,
      appBar: DetailAppBar(
        title: "비교 뷰",
        rightWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             _buildDoneButton(context, deviceWidth),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Thumbnail Strip
          _buildThumbnailStrip(images, _topIndex, (idx) {
            setState(() => _topIndex = idx);
             _resetZoom();
          }),

          // Top Viewport
          Expanded(
            child: _buildViewport(
              context,
              topImage,
              _topController,
              _isSyncOn,
              isTop: true,
              onSwipe: (direction) {
                 if (direction == 1 && _topIndex < images.length - 1) {
                   setState(() => _topIndex++);
                 } else if (direction == -1 && _topIndex > 0) {
                   setState(() => _topIndex--);
                 }
                 _resetZoom();
              }
            ),
          ),

          Container(height: 1, color: Colors.grey[300]),

          // Bottom Viewport
          Expanded(
            child: _buildViewport(
              context,
              bottomImage,
              _bottomController,
              _isSyncOn,
              isTop: false,
              onSwipe: (direction) {
                 if (direction == 1 && _bottomIndex < images.length - 1) {
                   setState(() => _bottomIndex++);
                 } else if (direction == -1 && _bottomIndex > 0) {
                   setState(() => _bottomIndex--);
                 }
                 _resetZoom();
              }
            ),
          ),

          // Bottom Thumbnail Strip
          _buildThumbnailStrip(images, _bottomIndex, (idx) {
            setState(() => _bottomIndex = idx);
            _resetZoom();
          }),
        ],
      ),
    );
  }

  void _resetZoom() {
      // Optionally reset zoom when image changes
      // _topController.value = Matrix4.identity();
      // _bottomController.value = Matrix4.identity();
      // Spec says: "Normally reset (Fit to Screen) is natural"
      // But also: "Sync ON -> keep zoom recommended"
      if (!_isSyncOn) {
         _topController.value = Matrix4.identity();
         _bottomController.value = Matrix4.identity();
      }
  }

  Widget _buildDoneButton(BuildContext context, double deviceWidth) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Text(
        "완료",
        style: TextStyle(
            fontSize: deviceWidth * (50 / 375) * (14 / 50),
            color: AppColors.lgADB5BD
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip(List<ImageItem> images, int selectedIndex, Function(int) onSelect) {
    return Container(
      height: 60,
      color: AppColors.wh1,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: isSelected ? Border.all(color: AppColors.secondary, width: 2) : null,
              ),
              width: 44,
              height: 44,
              child: _buildNetworkImage(images[index].id),
            ),
          );
        },
      ),
    );
  }

  Future<Uint8List?> _fetchImageBytes(String imageId) async {
    return _imageCache.putIfAbsent(imageId, () async {
      try {
        final dio = FlutterBetterAuth.dioClient;
        final response = await dio.get(
          '${dotenv.env['API_BASE_URL']}/images/$imageId/thumbnail',
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = response.data;
        if (bytes is Uint8List) return bytes;
        if (bytes is List<int>) return Uint8List.fromList(bytes);
        return null;
      } catch (e) {
        debugPrint('Failed to fetch image bytes: $e');
        return null;
      }
    });
  }

  Widget _buildNetworkImage(String imageId) {
     return FutureBuilder<Uint8List?>(
       future: _fetchImageBytes(imageId),
       builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
           return Container(color: Colors.grey[200]);
         }
         if (snapshot.hasError || snapshot.data == null) {
           return const Icon(Icons.error);
         }
         return Image.memory(
           snapshot.data!,
           fit: BoxFit.cover,
         );
       },
     );
  }

  Widget _buildViewport(
      BuildContext context,
      ImageItem item,
      TransformationController controller,
      bool isSyncOn,
      {required bool isTop, required Function(int) onSwipe}
  ) {
    return Stack(
      children: [
        Listener(
          onPointerSignal: (event) {
             // Handle mouse wheel etc if needed
          },
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
               // Only swipe if zoom is roughly 1.0
               if (controller.value.getMaxScaleOnAxis() < 1.1) {
                  if (details.primaryVelocity! < 0) {
                     // Swipe Left -> Next
                     onSwipe(1);
                  } else if (details.primaryVelocity! > 0) {
                     // Swipe Right -> Prev
                     onSwipe(-1);
                  }
               }
            },
            child: ValueListenableBuilder<Matrix4>(
               valueListenable: controller,
               builder: (context, matrix, child) {
                  final scale = matrix.getMaxScaleOnAxis();
                  // Disable panning when at min scale to allow swipe
                  final panEnabled = scale > 1.05;
                  return InteractiveViewer(
                    transformationController: controller,
                    minScale: 1.0,
                    maxScale: 5.0,
                    panEnabled: panEnabled,
                    child: Center(
                      child: _buildNetworkImage(item.id),
                    ),
                  );
               }
            ),
          ),
        ),

        // Overlay Controls
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: () => _handleLike(item),
            child: Icon(
              item.isPicked ? Icons.favorite : Icons.favorite_border,
              color: item.isPicked ? AppColors.secondary : Colors.white,
              size: 30,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ),

        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: () => _handleRemove(item),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary, style: BorderStyle.solid), // Dashed hard in basic container
              ),
              child: Icon(Icons.close, color: AppColors.secondary, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
