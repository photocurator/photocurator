// hide_screen.dart
import 'package:flutter/material.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/common/widgets/photo_item.dart';


class HideScreen extends StatefulWidget {
  const HideScreen({Key? key}) : super(key: key);

  @override
  State<HideScreen> createState() => _HideScreenState();
}

class _HideScreenState extends BasePhotoScreen<HideScreen> {
  @override
  String get screenTitle => "숨긴 사진";

  @override
  String get viewType => "ALL"; // 전체 이미지를 가져오고 아래에서 필터링

  @override
  String? get sortType => "time"; // 기본 정렬
  @override
  String? get groupBy => null; // 그룹화 없음

  @override
  Future<void> _loadImages() async {
    if (projectId == null) return;

    setState(() => isLoading = true);

    final api = ApiService();
    try {
      final fetchedImages = await api.fetchProjectImages(
        projectId: projectId!, // ← named parameter로 반드시 지정
        viewType: viewType,
      );

      // 숨긴 사진만 필터링
      final hiddenImages = fetchedImages.where((img) => img.isRejected).toList();

      setState(() {
        images = hiddenImages;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("이미지 불러오기 실패: $e");
    }
  }
}
