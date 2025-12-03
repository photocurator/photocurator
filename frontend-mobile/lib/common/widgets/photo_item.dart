// photo_item.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:photocurator/features/home/detail_view/photo_screen.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';

class QualityScore {
  final double? brisque;
  final double? tenegrad;
  final double? musiq;

  QualityScore({this.brisque, this.tenegrad, this.musiq});

  factory QualityScore.fromJson(Map<String, dynamic>? json) {
    if (json == null) return QualityScore();

    double? parseScore(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
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
  bool isPicked;
  final int rating;
  final double? score;
  final DateTime createdAt;
  final QualityScore qualityScore;
  final List<ObjectTag> objectTags;

  ImageItem({
    required this.id,
    this.isRejected = false,
    this.isPicked = false,
    this.rating = 0,
    this.score,
    required this.createdAt,
    this.objectTags = const [],
    QualityScore? qualityScore,
  }) : qualityScore = qualityScore ?? QualityScore();

  ImageItem copyWith({
    bool? isRejected,
    bool? isPicked,
    int? rating,
    double? score,
    DateTime? createdAt,
    QualityScore? qualityScore,
    List<ObjectTag>? objectTags,
  }) {
    return ImageItem(
      id: id,
      isRejected: isRejected ?? this.isRejected,
      isPicked: isPicked ?? this.isPicked,
      rating: rating ?? this.rating,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      objectTags: objectTags ?? this.objectTags,
      qualityScore: qualityScore ?? this.qualityScore,
    );
  }

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    // 안전하게 Map<String, dynamic>으로 변환
    final map = Map<String, dynamic>.from(json);

    DateTime? parseDate(String? str) {
      if (str == null) return null;
      try {
        return DateTime.parse(str);
      } catch (_) {
        return null;
      }
    }

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

    final qualityJson = Map<String, dynamic>.from(map['qualityScore'] ?? {});
    final musiqScoreRaw = qualityJson['musiqScore'];

    double? parseScore(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int parseRating(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ImageItem(
      id: json['image']?['id'] ?? '',
      isRejected: json['imageSelection']?['isRejected'] ?? false,
      isPicked: json['imageSelection']?['isPicked'] ?? false,
      rating: json['imageSelection']?['rating'] ?? 0,
      score: parseScore(musiqScoreRaw),
      createdAt: parseDate(json['image']?['createdAt']) ?? DateTime.now(),
      objectTags: parseTags(json['objectTags']),
      qualityScore: QualityScore.fromJson(qualityJson),
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
  late final Dio _dio;

  ApiService() {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('API_BASE_URL not found in .env file');
    }

    _dio = FlutterBetterAuth.dioClient;
    _dio.options.baseUrl = baseUrl;
  }

  Future<List<ImageItem>> fetchProjectImages({
    required String projectId,
    String? viewType,
    String? sortType,
    String? groupBy,
  }) async {
    try {
      final res = await _dio.get(
        '/projects/$projectId/images',
        queryParameters: {
          if (viewType != null) 'viewType': viewType,
          if (sortType != null) 'sort': sortType,
          if (groupBy != null) 'groupBy': groupBy,
        },
      );

      final data = res.data['data'] as List<dynamic>;
      return data.map((e) => ImageItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      print('Error fetching project images: $e');
      return [];
    }
  }

  Future<bool> updateImageSelection({
    required String imageId,
    required bool isPicked,
    int rating = 0,
  }) async {
    try {
      final res = await _dio.put(
        '/images/$imageId/selection',
        data: {
          'isPicked': isPicked,
          'rating': rating,
        },
      );
      return res.statusCode != null && res.statusCode! < 300;
    } catch (e) {
      debugPrint('Error updating selection: $e');
      return false;
    }
  }

  Future<bool> batchRejectImages({
    required List<String> imageIds,
    String reasonCode = 'BLURRY',
    String reasonText = '',
  }) async {
    try {
      final res = await _dio.post(
        '/images/batch-reject',
        data: {
          'imageIds': imageIds,
          'reasonCode': reasonCode,
          'reasonText': reasonText,
        },
      );
      return res.statusCode != null && res.statusCode! < 300;
    } catch (e) {
      debugPrint('Error batch rejecting images: $e');
      return false;
    }
  }
}

// image_item_widget.dart
class ImageItemWidget extends StatelessWidget {
  static final Map<String, Future<Uint8List?>> _imageCache = {};
  final ImageItem item;
  final List<ImageItem> images; // 전체 이미지 리스트
  final int index;               // 현재 인덱스
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onLongPress;
  final void Function(bool newValue)? onTogglePick;
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
    this.onTogglePick,
    required this.size,
  });

  Future<Uint8List?> _fetchImageBytes(String imageId) async {
    return _imageCache.putIfAbsent(imageId, () async {
      try {
        final dio = FlutterBetterAuth.dioClient; // 인증 적용된 dio
        final response = await dio.get(
          '${dotenv.env['API_BASE_URL']}/images/$imageId/file',
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
            FutureBuilder<Uint8List?>(
              future: _fetchImageBytes(item.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData &&
                    snapshot.data != null) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                  );
                } else if (snapshot.hasError) {
                  return Container(
                    width: size,
                    height: size,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),

            if (isSelecting)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: SvgPicture.asset(
                    isSelected
                        ? 'assets/icons/button/select_button_blue.svg'
                        : 'assets/icons/button/select_button0.svg',
                    width: 14,
                    height: 14,
                  ),
                ),
              ),
            if (!isSelecting)
              Positioned(
                right: 6,
                bottom: 6,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTogglePick?.call(!item.isPicked),
                  child: SvgPicture.asset(
                    item.isPicked
                        ? 'assets/icons/button/filled_heart.svg'
                        : 'assets/icons/button/empty_heart_gray.svg',
                    width: 20,
                    height: 20,
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
  final void Function(ImageItem item, bool newValue)? onTogglePick;

  const PhotoGrid({
    super.key,
    required this.images,
    this.isSelecting = false,
    this.selectedImages = const [],
    required this.onSelectToggle,
    this.onLongPressItem,
    this.onTogglePick,
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
            onTogglePick: onTogglePick == null
                ? null
                : (newValue) => onTogglePick!(item, newValue),
            size: itemSize,
          ),
        );
      },
    );
  }
}


class ShimmerPlaceholderRow extends StatefulWidget {
  const ShimmerPlaceholderRow({super.key});

  @override
  State<ShimmerPlaceholderRow> createState() => _ShimmerPlaceholderRowState();
}

class _ShimmerPlaceholderRowState extends State<ShimmerPlaceholderRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final crossAxisSpacing = 4.0;
    final paddingHorizontal = 20.0;
    final itemWidth = (deviceWidth - paddingHorizontal * 2 - crossAxisSpacing * 2) / 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: crossAxisSpacing,
        childAspectRatio: 1, // 1:1 정사각형
      ),
      itemCount: 3, // 3열 1행
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment(-1 + _controller.value * 2, -1),
                  end: Alignment(1 + _controller.value * 2, 1),
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade200,
                    Colors.grey.shade300,
                  ],
                  stops: const [0.1, 0.5, 0.9],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
