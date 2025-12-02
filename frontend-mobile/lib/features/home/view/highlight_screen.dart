import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_better_auth/core/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photocurator/common/bar/view_model/home_tab_section.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/widgets/group_card.dart';
import 'package:provider/provider.dart';

import '../../../provider/current_project_provider.dart';
import './grade_screen.dart';
import '../detail_view/group_detail.dart';
import '../detail_view/hide_screen.dart';

class HighlightScreen extends StatefulWidget {
  final VoidCallback onMoveToGrade;

  const HighlightScreen({super.key, required this.onMoveToGrade});

  @override
  State<HighlightScreen> createState() => _HighlightScreenState();
}

class _HighlightScreenState extends State<HighlightScreen> {
  late PageController _pageController;
  int pageIndex = 0;

  Future<Uint8List?> _fetchImageBytes(String imageId) async {
    try {
      final dio = FlutterBetterAuth.dioClient;
      final response = await dio.get(
        '${dotenv.env['API_BASE_URL']}/images/$imageId/file',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      debugPrint('Failed to fetch image bytes: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final bannerWidth = deviceWidth - 30;
    final bannerHeight = bannerWidth * 4 / 3;

    // 다음 카드 20px 보이게
    final viewportFraction = bannerWidth / (bannerWidth + 20);
    _pageController = PageController(viewportFraction: viewportFraction);

    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final bestShotImages = imageProvider.bestShotImages;

    final provider = context.read<CurrentProjectImagesProvider>();
    final groups = provider.projectGroups;

    final bannerImages = [...bestShotImages]..sort((a, b) =>
        (b.qualityScore?.musiq ?? 0).compareTo(a.qualityScore?.musiq ?? 0));

    final topImages = bannerImages.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // 배너
            SizedBox(
              height: bannerHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: topImages.length,
                onPageChanged: (i) => setState(() => pageIndex = i),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final img = topImages[index];
                  final isCurrent = index == pageIndex;
                  final isNext = index == pageIndex + 1;

                  BorderRadius radius;
                  if (isCurrent) {
                    radius = const BorderRadius.all(Radius.circular(16));
                  } else if (isNext) {
                    radius = const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    );
                  } else {
                    radius = BorderRadius.zero;
                  }

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: bannerWidth,
                      height: bannerHeight,
                      decoration: BoxDecoration(
                        color: AppColors.lgE9ECEF,
                        borderRadius: radius,
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: FutureBuilder<Uint8List?>(
                        future: _fetchImageBytes(img.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              width: bannerWidth,
                              height: bannerHeight,
                            );
                          }
                          // 로딩 시: 배경색만 표시
                          return const SizedBox.expand();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 36),

            // 🔽 기존 UI 그대로
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "더 많은 AI 추천과\n함께해 보세요",
                      style: TextStyle(
                        fontFamily: 'NotoSansRegular',
                        fontSize: deviceWidth * (18 / 375),
                        color: AppColors.dg1C1F23,
                        letterSpacing: 0,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onMoveToGrade,
                    child: Container(
                      width: deviceWidth * (150 / 375),
                      height: deviceWidth * (50 / 375),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: const Color(0xFFADB5BD),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 왼쪽 원형 + 그림자 + 플러스 아이콘
                          Container(
                            width: deviceWidth * (50 / 375),
                            height: deviceWidth * (50 / 375),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.wh1,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  offset: const Offset(4, 0),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                size: deviceWidth * (24 / 375),
                                color: AppColors.dg1C1F23,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                "베스트 샷",
                                style: TextStyle(
                                  fontFamily: 'NotoSansRegular',
                                  fontSize: deviceWidth * (12 / 375),
                                  color: AppColors.dg1C1F23,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 200),

            SizedBox(
              height: 160, // 원하는 높이
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand, // Stack이 부모 전체를 차지하도록
                  children: [
                    // 배경 컬러
                    Container(
                      color: const Color(0xFFE0E4F6),
                    ),
                    // 흐림 효과
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                    // 실제 컨텐츠
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "그룹",
                            style: TextStyle(
                              fontFamily: 'NotoSansMedium',
                              fontSize: deviceWidth * (18 / 375),
                              color: AppColors.dg1C1F23,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "AI 자동 그룹핑을 경험해보세요!",
                            style: TextStyle(
                              fontFamily: 'NotoSansRegular',
                              fontSize: deviceWidth * (15 / 375),
                              color: AppColors.dg1C1F23,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GroupCard(
              groups: groups,
              onTap: (group) {
                debugPrint('그룹 클릭: ${group.id}');

                // 상세 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailScreen(group: group),
                  ),
                );
              },
            ),
            const SizedBox(height: 200),
            Container(
              height: deviceWidth * (50 / 375), // 요청한 높이
              alignment: Alignment.center,
              child: Text(
                "숨긴 사진",
                style: TextStyle(
                  fontFamily: 'NotoSansMedium',        // 노토산스미디움
                  fontSize: deviceWidth * (18 / 375),  // 폰트 크기
                  color: AppColors.dg1C1F23,                 // 원하는 색상으로 변경 가능
                ),
              ),
            ),
            const SizedBox(height: 10),
            const ShimmerPlaceholderRow(),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HideScreen(), // 숨긴 사진 화면
                    ),
                  );
                },
                child: Text(
                  "자세히 보기",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'NotoSansRegular',
                    decoration: TextDecoration.underline,
                    color: AppColors.lgADB5BD,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),



          ],
        ),
      ),
    );
  }
}

//숨긴 사진
class ShimmerPlaceholderRow extends StatefulWidget {
  const ShimmerPlaceholderRow({super.key});

  @override
  State<ShimmerPlaceholderRow> createState() => _ShimmerPlaceholderRowState();
}

class _ShimmerPlaceholderRowState extends State<ShimmerPlaceholderRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final crossAxisSpacing = 4.0;
    final paddingHorizontal = 20.0;
    final itemWidth = (deviceWidth - paddingHorizontal * 2 - crossAxisSpacing * 2) / 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: crossAxisSpacing,
        childAspectRatio: 1, // 1:1 정사각형
      ),
      itemCount: 3, // 3열 1행
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment(-1 + _controller.value * 2, -1),
                  end: Alignment(1 + _controller.value * 2, 1),
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade200,
                    Colors.grey.shade300,
                  ],
                  stops: const [0.1, 0.5, 0.9],
                ),
              ),
            );
          },
        );
      },
    );
  }
}