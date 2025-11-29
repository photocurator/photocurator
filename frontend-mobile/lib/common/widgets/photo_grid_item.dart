
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PhotoGridItem extends StatelessWidget {
  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onTap;

  const PhotoGridItem({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          AssetEntityImage(
            asset,
            isOriginal: false,
            fit: BoxFit.cover,
            thumbnailSize: const ThumbnailSize.square(250),
             loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
          // Selection indicator
          Positioned(
            top: 8,
            left: 8,
            child: SvgPicture.asset(
              isSelected
                  ? 'assets/icons/button/selected_button.svg'
                  : 'assets/icons/button/unselected_button.svg',
              width: 14,
              height: 14,
            ),
          ),
        ],
      ),
    );
  }
}
