import 'package:flutter/material.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/current_project_provider.dart';
import 'package:photocurator/common/widgets/photo_item.dart';

class SelectableBar extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final void Function(int index) onItemSelected;
  final double height;
  final Color backgroundColor;
  final Color selectedTextColor;
  final TextStyle? unselectedTextStyle;

  const SelectableBar({
    Key? key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.height,
    this.backgroundColor = AppColors.wh1,
    this.selectedTextColor = AppColors.dg1C1F23,
    this.unselectedTextStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Container(
      height: height,
      color: AppColors.lgE9ECEF,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onItemSelected(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Align(
                alignment: Alignment.center, // 세로 중앙 정렬
                child: Container(
                  height: height*(32/44), // 선택 박스 고정
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.lgE9ECEF,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    items[index],
                    style: TextStyle(
                      fontFamily: 'NotoSansRegular',
                      fontSize: MediaQuery.of(context).size.width * (14 / 375),
                      color: isSelected ? AppColors.dg1C1F23 : AppColors.lgADB5BD,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

  }
}
/*

class DateTabPageSection extends StatefulWidget {
  final List<ImageItem> images;
  final Widget Function(List<ImageItem> filteredImages) pageBuilder;

  const DateTabPageSection({
    Key? key,
    required this.images,
    required this.pageBuilder,
  }) : super(key: key);

  @override
  _DateTabPageSectionState createState() => _DateTabPageSectionState();
}

class _DateTabPageSectionState extends State<DateTabPageSection> {
  late List<String> dateLabels;
  late Map<String, List<ImageItem>> imagesByDate;
  int selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _prepareDateMapping();
  }

  void _prepareDateMapping() {
    imagesByDate = {"전체": widget.images};

    for (var img in widget.images) {
      final date = img.captureDatetime ?? img.createdAt;
      final label = "${date.month}월 ${date.day}일";
      imagesByDate.putIfAbsent(label, () => []).add(img);
    }

    final otherDates = imagesByDate.keys.where((k) => k != "전체").toList()
      ..sort((a, b) {
        final aParts = a.split(RegExp(r"[월일 ]")).where((e) => e.isNotEmpty).toList();
        final bParts = b.split(RegExp(r"[월일 ]")).where((e) => e.isNotEmpty).toList();
        return DateTime(DateTime.now().year, int.parse(aParts[0]), int.parse(aParts[1]))
            .compareTo(DateTime(DateTime.now().year, int.parse(bParts[0]), int.parse(bParts[1])));
      });
    dateLabels = ["전체", ...otherDates];
  }

  void _onTabSelected(int index) {
    setState(() => selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) => setState(() => selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SelectableBar(
          items: dateLabels,
          selectedIndex: selectedIndex,
          onItemSelected: _onTabSelected,
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: dateLabels.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final imagesForPage = imagesByDate[dateLabels[index]]!;
              return widget.pageBuilder(imagesForPage);
            },
          ),
        ),
      ],
    );
  }
}
*/