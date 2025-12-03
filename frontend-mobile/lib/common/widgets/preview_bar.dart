import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_better_auth/core/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'dart:typed_data';

// Cache thumbnail futures to avoid refetching on each rebuild
final Map<String, Future<Uint8List?>> _thumbCache = {};

class PreviewBar extends StatelessWidget {
  final List<ImageItem> images;
  final ImageItem currentImage;
  final void Function(ImageItem) onImageSelected;
  final double deviceWidth;

  const PreviewBar({
    Key? key,
    required this.images,
    required this.currentImage,
    required this.onImageSelected,
    required this.deviceWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final barHeight = deviceWidth * (40 / 375);
    final imageSize = deviceWidth * (30 / 375);

    return SizedBox(
      height: barHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        padding: EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final img = images[index];
          final isSelected = img.id == currentImage.id;

          return GestureDetector(
            onTap: () => onImageSelected(img),
            child: Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: FutureBuilder<Uint8List?>(
                future: _thumbCache.putIfAbsent(
                  img.id,
                  () => _fetchImageBytes(img.id),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData &&
                      snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      width: imageSize,
                      height: imageSize,
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      width: imageSize,
                      height: imageSize,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper 함수
Future<Uint8List?> _fetchImageBytes(String imageId) async {
  try {
    final dio = FlutterBetterAuth.dioClient; // 인증된 Dio
    final response = await dio.get(
      '${dotenv.env['API_BASE_URL']}/images/$imageId/thumbnail',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  } catch (e) {
    debugPrint('Failed to fetch image bytes: $e');
    return null;
  }
}
