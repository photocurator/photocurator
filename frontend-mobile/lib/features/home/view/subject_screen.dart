// subject_screen.dart
import 'package:flutter/material.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/bar/view/selectable_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:provider/provider.dart';

import '../../../provider/current_project_provider.dart';

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({Key? key}) : super(key: key);

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {

  int selectedTabIndex = 0;
  List<String> subjectLabels = []; // objectTags에서 추출
  Map<String, List<ImageItem>> tabImages = {};
  bool isLoading = true;

  //기본적인 매핑 테이블
  final Map<String, String> tagNameMap = {
    'person': '사람',
    'man': '남자',
    'woman': '여자',
    'child': '아이',
    'dog': '강아지',
    'cat': '고양이',
    'car': '자동차',
    'bicycle': '자전거',
    'motorcycle': '오토바이',
    'boat': '보트', // 추가
    'tree': '나무',
    'flower': '꽃',
    'building': '건물',
    'sky': '하늘',
    'road': '도로',
    'food': '음식',
    'table': '테이블',
    'chair': '의자',
    'phone': '휴대폰',
    'laptop': '노트북',
    'book': '책',
    'cup': '컵',
    'glass': '유리컵',
    'shoe': '신발',
    'bag': '가방',
    'watch': '시계',
    'hat': '모자',
    'bottle': '병',
    'ball': '공',
    'plant': '식물',
    'window': '창문',
    'door': '문',
    'computer': '컴퓨터',
    'keyboard': '키보드',
    'mouse': '마우스',
    'tv': 'TV',
    'bed': '침대',
    'sofa': '소파',
    'dog_food': '강아지 사료',
    'cat_food': '고양이 사료',
    // 필요하면 계속 추가 가능
  };

  String translateTagName(String tag) {
    return tagNameMap[tag.toLowerCase()] ?? tag; // 매핑 없으면 영어 그대로
  }


  /// 이미지에서 태그별 라벨과 매핑 준비
  void _prepareSubjectLabels() {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final images = imageProvider.allImages;

    subjectLabels = [];
    tabImages = {};

    for (var img in images) {
      // objectTags의 tagName을 한국어로 변환, 빈 값 제외, 중복 제거
      final tags = img.objectTags
          .map((t) => translateTagName(t.tagName)) // 영어 → 한국어
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();

      for (var tag in tags) {
        if (!subjectLabels.contains(tag)) subjectLabels.add(tag);
        tabImages.putIfAbsent(tag, () => []);
        tabImages[tag]!.add(img);
      }
    }

    subjectLabels.sort();
  }


  /// 현재 선택된 탭의 이미지
  List<ImageItem> get currentImages {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final images = imageProvider.allImages;

    final index = selectedTabIndex;
    if (index < 0 || index >= subjectLabels.length) return [];

    final label = subjectLabels[index];
    return tabImages[label] ?? [];
  }

  void _onTabSelected(int index) {
    setState(() => selectedTabIndex = index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final imageProvider = context.watch<CurrentProjectImagesProvider>();
    if (!imageProvider.isLoading) {
      _prepareSubjectLabels();
      if (selectedTabIndex >= subjectLabels.length + 1) selectedTabIndex = 0;
      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    final tabs = subjectLabels;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: Column(
        children: [
          // 날짜/주제 선택 탭
          SelectableBar(
            items: tabs,
            selectedIndex: selectedTabIndex,
            onItemSelected: _onTabSelected,
            height: deviceWidth * (44 / 375),
          ),

          Expanded(
            child: SubjectScreenContent(images: currentImages),
          )
        ],
      ),
    );
  }
}

class SubjectScreenContent extends StatefulWidget {
  final List<ImageItem> images;

  const SubjectScreenContent({
    Key? key,
    required this.images,
  }) : super(key: key);

  @override
  _SubjectScreenContentState createState() => _SubjectScreenContentState();
}

class _SubjectScreenContentState extends BasePhotoContent<SubjectScreenContent> {
  @override
  String get viewType => 'ALL';

  @override
  String get screenTitle => '날짜별 사진';

  // 그룹핑 필요 없으므로 null 반환
  @override
  String? get groupBy => null;

  // StatefulWidget의 images를 참조하려면 widget.images 사용
  @override
  List<ImageItem> get imageItems => widget.images;
}
