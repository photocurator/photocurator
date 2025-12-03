import 'package:flutter/material.dart';
import 'package:photocurator/common/bar/view/session_bar.dart';

// 각 세션-화면 매핑
class HomeTabSection extends StatefulWidget {
  final List<Widget> pages;

  const HomeTabSection({
    Key? key,
    required this.pages,
  }) : super(key: key);

  @override
  HomeTabSectionState createState() => HomeTabSectionState();
}

class HomeTabSectionState extends State<HomeTabSection> {
  final PageController _pageController = PageController();
  int selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // 외부에서 탭 이동시키고 싶을 때 호출할 메서드
  void jumpToTab(int index) {
    setState(() => selectedIndex = index);
    _pageController.jumpToPage(index);
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SessionBar(
          selectedIndex: selectedIndex,
          onTabSelected: _onTabSelected,
        ),

        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            children: widget.pages,
          ),
        ),
      ],
    );
  }
}
