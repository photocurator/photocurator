// setting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_better_auth/core/flutter_better_auth.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/photo_screen_widget.dart';
import 'package:photocurator/common/bar/view/selection_bar.dart';
import 'package:photocurator/common/bar/view/selectable_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../provider/current_project_provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {

  bool isLoading = true;
  int selectedTabIndex = 0;

  List<String> tabs = [];
  Map<String, List<ImageItem>> tabImages = {};

  late Dio _dio;
  bool _initialized = false; // ← 중복 호출 방지용

  @override
  void initState() {
    super.initState();
    _initDio();
  }

  void _initDio() {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null) throw Exception("API_BASE_URL missing");

    _dio = FlutterBetterAuth.dioClient;
    _dio.options.baseUrl = baseUrl;
  }

  Future<Map<String, dynamic>?> _fetchImageDetail(String id) async {
    try {
      final res = await _dio.get("/images/$id/details");
      return res.data;
    } catch (e) {
      debugPrint("Error fetching detail for $id: $e");
      return null;
    }
  }

  Future<void> _prepareSubjectLabels() async {
    setState(() => isLoading = true);

    try {
      final imageProvider = context.read<CurrentProjectImagesProvider>();
      final allImages = imageProvider.allImages;

      final detailFutures = allImages.map((img) async {
        final detail = await _fetchImageDetail(img.id);
        if (detail == null) return null;

        final exif = detail['exif'] ?? {};
        final camera = exif['cameraModel'] ?? "Unknown Camera";
        final lens = exif['lensModel'] ?? "Unknown Lens";

        final key = "$camera & $lens";

        return {'key': key, 'image': img};
      });

      final results = await Future.wait(detailFutures);

      Map<String, List<ImageItem>> grouped = {};

      for (var result in results) {
        if (result == null) continue;

        final key = result['key'] as String;
        final img = result['image'] as ImageItem;

        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(img);
      }

      setState(() {
        tabImages = grouped;
        tabs = grouped.keys.toList()..sort();
        selectedTabIndex = 0;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load tabs: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final provider = context.watch<CurrentProjectImagesProvider>();

    if (!provider.isLoading) {
      _prepareSubjectLabels();
    }
  }

  List<ImageItem> get currentImages {
    if (tabs.isEmpty) return [];
    return tabImages[tabs[selectedTabIndex]] ?? [];
  }

  void _onTabSelected(int index) {
    setState(() => selectedTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: Column(
        children: [
          if (tabs.isNotEmpty)
            SelectableBar(
              items: tabs,
              selectedIndex: selectedTabIndex,
              onItemSelected: _onTabSelected,
              height: deviceWidth * (44 / 375),
            ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SettingScreenContent(images: currentImages),
          )
        ],
      ),
    );
  }
}


class SettingScreenContent extends StatefulWidget {
  final List<ImageItem> images;

  const SettingScreenContent({
    Key? key,
    required this.images,
  }) : super(key: key);

  @override
  _SettingScreenContentState createState() => _SettingScreenContentState();
}

class _SettingScreenContentState extends BasePhotoContent<SettingScreenContent> {
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
