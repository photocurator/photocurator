// photo_item.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';


// -----------------------------
// ImageItem 모델
// -----------------------------
class ImageItem {
  final String id;
  final String thumbnailUrl;
  final bool isRejected; // 숨긴 사진 필터

  // 추가 필드
  final double? score; // AI 추천 점수
  final DateTime? captureDatetime; // EXIF 촬영 날짜
  final DateTime createdAt; // DB에 올라온 날짜

  ImageItem({
    required this.id,
    required this.thumbnailUrl,
    this.isRejected = false,
    this.score,
    this.captureDatetime,
    required this.createdAt,
  });

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? str) {
      if (str == null) return null;
      try {
        return DateTime.parse(str);
      } catch (_) {
        return null;
      }
    }

    return ImageItem(
      id: json['imageId'],
      thumbnailUrl: json['urls']['thumbnail'],
      isRejected: json['userFeedback']?['isRejected'] ?? false,
      score: json['analysis']?['qualityScore']?['musiqScore']?.toDouble(),
      captureDatetime: parseDate(json['exif']?['captureDatetime']),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }
}


// -----------------------------
// ImageItemWidget
// -----------------------------
class ImageItemWidget extends StatelessWidget {
  final ImageItem item;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onLongPress;
  final double size; // 이미지 정사각형 크기

  const ImageItemWidget({
    super.key,
    required this.item,
    this.isSelecting = false,
    this.isSelected = false,
    this.onSelectToggle,
    this.onLongPress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelecting ? onSelectToggle : null,
      onLongPress: onLongPress,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Image.network(
              item.thumbnailUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: size,
                  height: size,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
            if (isSelecting)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  color: Colors.white,
                  child: SvgPicture.asset(
                    isSelected
                        ? 'assets/icons/button/select_button_blue.svg'
                        : 'assets/icons/button/select_button0.svg',
                    width: 14,
                    height: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



// -----------------------------
// API 호출 포함
// -----------------------------
class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.photocurator.com/v1',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<List<ImageItem>> fetchProjectImages(
      String projectId, {
        String? viewType,
      }) async {
    final res = await _dio.get(
      '/projects/$projectId/images',
      queryParameters: {
        if (viewType != null) 'viewType': viewType,
      },
    );

    final data = res.data['data'] as List;
    return data.map((e) => ImageItem.fromJson(e)).toList();
  }


}

// -----------------------------
// PhotoGrid
// -----------------------------
class PhotoGrid extends StatelessWidget {
  final List<ImageItem> images;
  final bool isSelecting;
  final List<ImageItem> selectedImages;
  final void Function(ImageItem) onSelectToggle;
  final void Function()? onLongPressItem;

  const PhotoGrid({
    super.key,
    required this.images,
    this.isSelecting = false,
    this.selectedImages = const [],
    required this.onSelectToggle,
    this.onLongPressItem,
  });

  @override
  Widget build(BuildContext context) {
    final itemSize = (MediaQuery.of(context).size.width - 48) / 3; // 1대1 정사각형

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final item = images[index];
        return SizedBox(
          width: itemSize,
          height: itemSize,
          child: ImageItemWidget(
            item: item,
            isSelecting: isSelecting,
            isSelected: selectedImages.contains(item),
            onSelectToggle: () => onSelectToggle(item),
            onLongPress: onLongPressItem,
            size: itemSize,
          ),
        );
      },
    );
  }
}
