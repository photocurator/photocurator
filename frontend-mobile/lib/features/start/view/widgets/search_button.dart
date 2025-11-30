import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchButton extends StatelessWidget {
  final VoidCallback? onTap;

  const SearchButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(
          'assets/icons/button/search_button_box.svg',
          width: 32,
          height: 32,
          placeholderBuilder: (context) => const Icon(Icons.search, size: 32),
        ),
      ),
    );
  }
}