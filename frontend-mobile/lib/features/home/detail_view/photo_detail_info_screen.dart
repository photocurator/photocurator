import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'image_detail_service.dart';

class PhotoDetailInfoData {
  final String fileName;
  final String modelScore1;
  final String modelScore2;
  final String modelScore3;
  final String fileSizeBytes;
  final int widthPx;
  final int heightPx;
  final String createdAt;
  final String cameraModel;
  final String lensModel;
  final List<String> tags;

  const PhotoDetailInfoData({
    required this.fileName,
    required this.modelScore1,
    required this.modelScore2,
    required this.modelScore3,
    required this.fileSizeBytes,
    required this.widthPx,
    required this.heightPx,
    required this.createdAt,
    required this.cameraModel,
    required this.lensModel,
    required this.tags,
  });

  factory PhotoDetailInfoData.fromApi(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>? ?? {};
    final quality = json['qualityScore'] as Map<String, dynamic>? ?? {};
    final exif = json['exif'] as Map<String, dynamic>? ?? {};
    final tags = (json['objectTags'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['tagName']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    return PhotoDetailInfoData(
      fileName: image['originalFilename']?.toString() ?? '-',
      modelScore1: quality['brisqueScore']?.toString() ?? '-',
      modelScore2: quality['tenegradScore']?.toString() ?? '-',
      modelScore3: quality['musiqScore']?.toString() ?? '-',
      fileSizeBytes: image['fileSizeBytes']?.toString() ?? '-',
      widthPx: image['widthPx'] is int ? image['widthPx'] as int : int.tryParse('${image['widthPx']}') ?? 0,
      heightPx: image['heightPx'] is int ? image['heightPx'] as int : int.tryParse('${image['heightPx']}') ?? 0,
      createdAt: image['captureDatetime']?.toString() ?? '-',
      cameraModel: exif['cameraModel']?.toString() ?? '-',
      lensModel: exif['lensModel']?.toString() ?? '-',
      tags: tags,
    );
  }
}

class PhotoDetailInfoScreen extends StatefulWidget {
  final String imageId;

  const PhotoDetailInfoScreen({
    super.key,
    required this.imageId,
  });

  @override
  State<PhotoDetailInfoScreen> createState() => _PhotoDetailInfoScreenState();
}

class _PhotoDetailInfoScreenState extends State<PhotoDetailInfoScreen> {
  late Future<PhotoDetailInfoData> _detailFuture;
  final ImageDetailService _service = ImageDetailService();

  @override
  void initState() {
    super.initState();
    _detailFuture = _service.fetchDetails(widget.imageId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.dg1C1F23, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          '이미지 상세정보',
          style: TextStyle(
            fontFamily: 'NotoSansMedium',
            fontSize: 16,
            color: AppColors.dg1C1F23,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '',
                style: TextStyle(
                  fontFamily: 'NotoSansRegular',
                  fontSize: 14,
                  color: AppColors.lgADB5BD,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<PhotoDetailInfoData>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                '정보를 불러오지 못했습니다',
                style: const TextStyle(
                  fontFamily: 'NotoSansRegular',
                  fontSize: 14,
                  color: AppColors.dg495057,
                ),
              ),
            );
          }
          final detail = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('파일 이름', detail.fileName),
                _infoRow('모델 1', detail.modelScore1, isLinkLike: true),
                _infoRow('모델 2', detail.modelScore2, isLinkLike: true),
                _infoRow('모델 3', detail.modelScore3, isLinkLike: true),
                _infoRow('용량', detail.fileSizeBytes),
                _infoRow('사이즈', '(${detail.widthPx}px) x (${detail.heightPx}px)'),
                _infoRow('생성 일자', detail.createdAt),
                _infoRow('카메라 모델', detail.cameraModel),
                _infoRow('렌즈 모델', detail.lensModel),
                const SizedBox(height: 16),
                _tagSection(detail.tags),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLinkLike = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'NotoSansRegular',
                fontSize: 13,
                color: AppColors.dg495057,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'NotoSansRegular',
                fontSize: 13,
                color: isLinkLike ? AppColors.primary : AppColors.dg1C1F23,
                decoration: isLinkLike ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagSection(List<String> tags) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        _tagChip('태그 정보', highlight: true),
        ...tags.map((t) => _tagChip('# $t')),
      ],
    );
  }

  Widget _tagChip(String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlight ? AppColors.primary : AppColors.lgE9ECEF),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: highlight ? 'NotoSansMedium' : 'NotoSansRegular',
          fontSize: 12,
          color: highlight ? AppColors.primary : AppColors.dg495057,
        ),
      ),
    );
  }
}
