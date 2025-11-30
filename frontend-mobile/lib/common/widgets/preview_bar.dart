import 'package:flutter/material.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/theme/colors.dart';

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
              child: Image.network(
                img.thumbnailUrl,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
