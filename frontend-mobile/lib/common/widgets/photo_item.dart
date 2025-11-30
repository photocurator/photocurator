// photo_item.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:photocurator/features/home/detail_view/photo_screen.dart';
import 'package:photocurator/common/theme/colors.dart';

class QualityScore {
  final double? brisque;
  final double? tenegrad;
  final double? musiq;

  QualityScore({this.brisque, this.tenegrad, this.musiq});

  factory QualityScore.fromJson(Map<String, dynamic>? json) {
    if (json == null) return QualityScore();
    double? parseScore(dynamic value) {
      if (value == null) return null;
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    }

    return QualityScore(
      brisque: parseScore(json['brisqueScore']),
      tenegrad: parseScore(json['tenegradScore']),
      musiq: parseScore(json['musiqScore']),
    );
  }
}

class ImageItem {
  final String id;
  final bool isRejected;
  final double? score;
  final DateTime? captureDatetime;
  final DateTime createdAt;
  final QualityScore qualityScore;

  String get thumbnailUrl => "https://rx.r1c.cc/api/images/$id/file";

  // 주제 화면용 objectTags
  final List<ObjectTag> objectTags;

  ImageItem({
    required this.id,
    this.isRejected = false,
    this.score,
    this.captureDatetime,
    required this.createdAt,
    this.objectTags = const [],
    QualityScore? qualityScore,
  }) : qualityScore = qualityScore ?? QualityScore();

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? str) {
      if (str == null) return null;
      try {
        return DateTime.parse(str);
      } catch (_) {
        return null;
      }
    }

    // objectTags 처리
    List<ObjectTag> parseTags(List<dynamic>? tags) {
      if (tags == null) return [];
      return tags.map((t) {
        return ObjectTag(
          id: t['id'] ?? '',
          imageId: t['imageId'] ?? '',
          tagName: t['tagName'] ?? '',
          tagCategory: t['tagCategory'] ?? '',
          confidence: t['confidence'],
        );
      }).toList();
    }

    return ImageItem(
      id: json['image']?['id'] ?? '',
      isRejected: json['imageSelection']?['isRejected'] ?? false,
      score: json['qualityScore']?['musiqScore']?.toDouble(),
      captureDatetime: parseDate(json['image']?['captureDatetime']),
      createdAt: parseDate(json['image']?['createdAt']) ?? DateTime.now(),
      objectTags: parseTags(json['objectTags']),
      qualityScore: QualityScore.fromJson(json['qualityScore']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ImageItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class ObjectTag {
  final String id;
  final String imageId;
  final String tagName;
  final String tagCategory;
  final String? confidence;

  ObjectTag({
    required this.id,
    required this.imageId,
    required this.tagName,
    required this.tagCategory,
    this.confidence,
  });
}

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://rx.r1c.cc/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<List<ImageItem>> fetchProjectImages({
    required String projectId,
    String? viewType,
    String? sortType,
    String? groupBy,
  }) async {
    final res = await _dio.get(
      '/projects/$projectId/images',
      queryParameters: {
        if (viewType != null) 'viewType': viewType,
        if (sortType != null) 'sort': sortType,
        if (groupBy != null) 'groupBy': groupBy,
      },
    );

    final data = res.data['data'] as List;
    return data.map((e) => ImageItem.fromJson(e)).toList();
  }
}

// image_item_widget.dart
class ImageItemWidget extends StatelessWidget {
  final ImageItem item;
  final List<ImageItem> images; // 전체 이미지 리스트
  final int index;               // 현재 인덱스
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onLongPress;
  final double size;

  const ImageItemWidget({
    super.key,
    required this.item,
    required this.images,
    required this.index,
    this.isSelecting = false,
    this.isSelected = false,
    this.onSelectToggle,
    this.onLongPress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelecting
          ? onSelectToggle
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhotoScreen(
              images: images,
              initialIndex: index,
            ),
          ),
        );
      },
      onLongPress: onLongPress,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: item.thumbnailUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Container(
                width: size,
                height: size,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              ),
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

// photo_grid.dart

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
    final deviceWidth = MediaQuery.of(context).size.width;
    final itemSize = (deviceWidth - 48) / 3;

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
            images: images,  // 전체 리스트 전달
            index: index,    // 현재 인덱스 전달
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
