import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';

// 드롭다운 아이템 클래스
class DropdownItem {
  final String text;
  final Color color;
  final VoidCallback onTap;

  DropdownItem({
    required this.text,
    this.color = AppColors.dg1C1F23,
    required this.onTap,
  });
}

// 더보기 드롭다운 창 ui
// 직접 사용 x
class _MoreDropdown extends StatelessWidget {
  final List<DropdownItem> items;

  const _MoreDropdown({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: deviceWidth * (160/375),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.wh1,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.dg1C1F23.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(items.length, (index) {
            final item = items[index];
            return GestureDetector(
              onTap: item.onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 32),
                child: Column(
                  children: [
                    Text(
                      item.text,
                      style: TextStyle(
                        fontSize: deviceWidth * (14/375),
                        color: item.color,
                      ),
                    ),
                  ],
                )
              ),
            );
          }),
        ),
      ),
    );
  }
}

// 핸들러 함수
// == 호출 할 것
void showMoreDropdown({
  required BuildContext context,
  required RenderBox buttonRenderBox, // 버튼 위치 계산용
  required List<DropdownItem> items,
}) {
  final overlay = Overlay.of(context);
  OverlayEntry? entry;

  // _MoreDropdown의 onTap이 실행될 때 overlay 제거하도록 wrapping
  final wrappedItems = items.map((item) {
    return DropdownItem(
      text: item.text,
      color: item.color,
      onTap: () {
        item.onTap();   // 기존 메뉴 동작 먼저 실행
        entry?.remove(); // 드롭다운 닫기
      },
    );
  }).toList();

  entry = OverlayEntry(
    builder: (context) {
      final buttonPosition = buttonRenderBox.localToGlobal(Offset.zero);
      final buttonSize = buttonRenderBox.size;

      return Stack(
        children: [
          // 배경 터치 시 닫기
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry?.remove(),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: buttonPosition.dy + buttonSize.height * 0.2,
            right: MediaQuery.of(context).size.width - buttonPosition.dx - buttonSize.width * 1.2,
            child: _MoreDropdown(items: wrappedItems),
          ),
        ],
      );
    },
  );

  overlay.insert(entry);
}
