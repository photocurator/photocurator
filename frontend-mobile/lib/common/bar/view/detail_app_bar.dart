import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/widgets/back_icon.dart';

//상세 페이지(하위 페이지) 상단 바 ui
class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? rightWidget;
  final VoidCallback? onTap;

  const DetailAppBar({
    super.key,
    this.title,
    this.rightWidget,
    this.onTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  // ↑ 여긴 무시됨. 실제 높이는 build에서 계산됨.
  // 구조상 required라 아무 값 넣는 것.

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = width * (50 / 375); // 반응형으로 세로 길이 설정

    return SafeArea(
      //상태바 겹침 방지
      top: true, // 상단 노치 영역 포함
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        color: AppColors.wh1,
        child: Row(
          children: [
            // 왼쪽: 뒤로가기
            SizedBox(
              width: height,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    Container(
                      width: height * (10 / 50),
                      height: height * (20 / 50),
                      alignment: Alignment.center,
                      child: BackIcon(barHeight: height),
                    ),
                    const Spacer(), // 정렬 맞추는 용도
                  ],
                ),
              ),
            ),

            // 중앙: 제목
            Expanded(
              child: Center(
                child: Text(
                  title ?? '', // 사진 상세는 중앙 비어 있음
                  style: TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: height * (21 / 50),
                    color: AppColors.dg1C1F23,
                    letterSpacing: 0, // 자간 0으로 설정
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // 오른쪽 버튼(텍스트 버튼 or 더보기 버튼 or null)
            SizedBox(
              width: height, // 중앙 정렬을 위해 왼쪽과 동일하게
              child: GestureDetector(
                onTap: () => onTap,
                child: Row(
                  children: [
                    const Spacer(), // 정렬 맞추는 용도
                    rightWidget ?? const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
