import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:photocurator/common/theme/colors.dart';
import './photo_item.dart';

class ActionBottomBar extends StatefulWidget {
  final List<ImageItem> selectedImages;

  const ActionBottomBar({
    super.key,
    required this.selectedImages,
  });

  @override
  State<ActionBottomBar> createState() => _ActionBottomBarState();
}

class _ActionBottomBarState extends State<ActionBottomBar> {
  late Dio _dio;
  late String _baseUrl;

  @override
  void initState() {
    super.initState();

    _baseUrl = dotenv.env['API_BASE_URL'] ?? "";
    if (_baseUrl.isEmpty) {
      throw Exception("API_BASE_URL missing in .env");
    }

    _dio = FlutterBetterAuth.dioClient;
    _dio.options.baseUrl = _baseUrl;
  }

  // ------------------------------------------------
  // 1) 좋아요 / 선택 API
  // ------------------------------------------------
  Future<void> _likeImages() async {
    for (final img in widget.selectedImages) {
      try {
        await _dio.put(
          "/api/images/${img.id}/selection",
          data: {
            "isPicked": !img.isPicked,
            "rating": 5,
          },
          options: Options(headers: {"Content-Type": "application/json"}),
        );

        img.isPicked = !img.isPicked;
      } catch (e) {
        print("좋아요 실패: $e");
      }
    }

    setState(() {});
  }

  // ------------------------------------------------
  // 2) 복사 (임시)
  // ------------------------------------------------
  void _copyImages() {
    print("복사 기능 (구현 예정)");
  }

  // ------------------------------------------------
  // 3) 비교 뷰 (임시)
  // ------------------------------------------------
  void _compareImages() {
    print("비교 뷰 이동 (구현 예정)");
  }

  // ------------------------------------------------
  // 4) 다운로드 (gallery_saver 사용)
  // ------------------------------------------------
  Future<void> _downloadImages() async {
    if (widget.selectedImages.isEmpty) return;

    // photo_manager 전용 권한 요청
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) return;

    for (final img in widget.selectedImages) {
      try {
        final response = await _dio.get(
          "/api/images/${img.id}/file",
          options: Options(responseType: ResponseType.bytes),
        );

        final bytes = Uint8List.fromList(response.data);

        // 갤러리에 저장
        await PhotoManager.editor.saveImage(
          bytes,
          filename: "photo_${img.id}",
        );

      } catch (e) {
        print("다운로드 실패: $e");
      }
    }
  }



  // ------------------------------------------------
  // 5) 삭제 → 제외 / 휴지통
  // ------------------------------------------------
  Future<void> _rejectImages() async {
    for (final img in widget.selectedImages) {
      try {
        await _dio.post(
          "/api/images/${img.id}/reject",
          data: {
            "reasonCode": "BLURRY",
            "reasonText": "User rejected this image",
          },
          options: Options(headers: {"Content-Type": "application/json"}),
        );
      } catch (e) {
        print("제외 실패: $e");
      }
    }
    print("제외 완료");
  }

  Future<void> _trashImages() async {
    print("휴지통 API 엔드포인트 알려주면 연결해줄게");
  }

  void _deleteImages() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("제외하기"),
                onTap: () async {
                  Navigator.pop(context);
                  await _rejectImages();
                },
              ),
              ListTile(
                title: const Text("휴지통으로 보내기"),
                onTap: () async {
                  Navigator.pop(context);
                  await _trashImages();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------
  // 좋아요 상태 판단
  // ------------------------------------------------
  bool get _isAnyPicked =>
      widget.selectedImages.any((img) => img.isPicked == true);

  // ------------------------------------------------
  // UI
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.wh1,
        border: Border(top: BorderSide(color: AppColors.lgE9ECEF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            label: '좋아요',
            iconPath: _isAnyPicked
                ? 'assets/icons/button/filled_heart.svg'
                : 'assets/icons/button/empty_heart_gray.svg',
            onTap: _likeImages,
          ),
          _buildActionButton(
            label: '복사',
            iconPath: 'assets/icons/button/duplicate_gray.svg',
            onTap: _copyImages,
          ),
          _buildActionButton(
            label: '비교 뷰',
            iconPath: 'assets/icons/button/full_screen_gray.svg',
            onTap: _compareImages,
          ),
          _buildActionButton(
            label: '다운로드',
            iconPath: 'assets/icons/button/arrow_collapse_down_gray.svg',
            onTap: _downloadImages,
          ),
          _buildActionButton(
            label: '삭제',
            iconPath: 'assets/icons/button/empty_bin_gray.svg',
            onTap: _deleteImages,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(iconPath, width: 20, height: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.dg495057),
          ),
        ],
      ),
    );
  }
}
