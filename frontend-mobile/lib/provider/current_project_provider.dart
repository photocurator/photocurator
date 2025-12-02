import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_better_auth/core/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photocurator/features/start/service/project_service.dart'; // Project 클래스 import
import 'package:photocurator/common/widgets/photo_item.dart';

class CurrentProjectProvider extends ChangeNotifier {
  Project? _currentProject;

  Project? get currentProject => _currentProject;

  // 프로젝트 설정
  void setProject(Project project) {
    _currentProject = project;
    notifyListeners(); // 변경되면 구독 중인 위젯 rebuild
  }

  // 프로젝트 초기화 (선택 취소)
  void clearProject() {
    _currentProject = null;
    notifyListeners();
  }
}

class CurrentProjectImagesProvider extends ChangeNotifier {
  // 이미지
  List<ImageItem> allImages = [];
  List<ImageItem> hiddenImages = [];
  List<ImageItem> trashImages = [];
  List<ImageItem> bestShotImages = [];
  List<ImageItem> pickedImages = [];

  // 그룹
  List<GroupItem> projectGroups = [];

  bool isLoading = false;

  /// 프로젝트에 해당하는 모든 이미지 및 그룹 로드
  Future<void> loadAllImages(String projectId) async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. All 이미지 조회
      final all = await ApiService().fetchProjectImages(
        projectId: projectId,
        viewType: 'ALL',
      );

      // 2. Trash 이미지 조회
      final trash = await ApiService().fetchProjectImages(
        projectId: projectId,
        viewType: 'TRASH',
      );

      // 3. 숨긴 사진만 따로 저장
      hiddenImages = all.where((img) => img.isRejected).toList();

      // 4. All 이미지에서 숨긴 사진 + 휴지통 제거
      final trashIds = trash.map((e) => e.id).toList();
      allImages =
          all.where((img) => !img.isRejected && !trashIds.contains(img.id))
              .toList();

      // 5. Trash, BestShot, Picked 리스트
      trashImages = trash;
      bestShotImages = await ApiService().fetchProjectImages(
        projectId: projectId,
        viewType: 'BEST_SHOTS',
      );
      pickedImages = await ApiService().fetchProjectImages(
        projectId: projectId,
        viewType: 'PICKED',
      );

      // 6. 그룹 정보 및 대표 이미지 미리 다운로드
      await loadProjectGroupsWithImages(projectId);
    } catch (e) {
      debugPrint('이미지 또는 그룹 로드 실패: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  /// 특정 프로젝트 이미지/그룹 초기화
  void clear() {
    allImages = [];
    hiddenImages = [];
    trashImages = [];
    bestShotImages = [];
    pickedImages = [];
    projectGroups = [];
    notifyListeners();
  }

  void updatePickStatus(String imageId, bool isPicked) {
    ImageItem mapper(ImageItem img) =>
        img.id == imageId ? img.copyWith(isPicked: isPicked) : img;

    allImages = allImages.map(mapper).toList();
    hiddenImages = hiddenImages.map(mapper).toList();
    trashImages = trashImages.map(mapper).toList();
    bestShotImages = bestShotImages.map(mapper).toList();
    pickedImages = allImages.where((img) => img.isPicked).toList();
    notifyListeners();
  }


  /// 그룹별 데이터만 따로 로드 가능 (대표 이미지 미리 다운로드 포함)
// [수정 1] 괄호 위치 수정: 이 메서드가 클래스 안으로 들어와야 합니다.
  /// 그룹별 데이터만 따로 로드 가능 (대표 이미지 병렬 다운로드 적용)
  Future<void> loadProjectGroupsWithImages(String projectId) async {
    try {
      // (이미 상위에서 isLoading을 켰다면 중복 호출 주의)
      // isLoading = true;
      // notifyListeners();

      projectGroups =
      await GroupApiService().fetchProjectGroups(projectId: projectId);

      final dio = FlutterBetterAuth.dioClient;
      final baseUrl = dotenv.env['API_BASE_URL'];

      // [수정 2] Future.wait를 사용하여 병렬 다운로드 (속도 개선)
      await Future.wait(projectGroups.map((group) async {
        try {
          if (group.representativeImageId.isNotEmpty) {
            final res = await dio.get(
              '$baseUrl/images/${group.representativeImageId}/file',
              options: Options(responseType: ResponseType.bytes),
            );
            group.imageBytes = res.data;
          }
        } catch (e) {
          debugPrint('그룹 이미지(${group.id}) 다운로드 실패: $e');
          group.imageBytes = null;
        }
      }));
    } catch (e) {
      debugPrint('그룹 로드 실패: $e');
      projectGroups = [];
    } finally {
      // isLoading = false;
      notifyListeners(); // 데이터 변경 알림
    }
  }
}




class GroupItem {
  final String id;
  final String projectId;
  final String groupType;
  final String representativeImageId;
  final DateTime timeRangeStart;
  final DateTime timeRangeEnd;
  final String? similarityScore;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Uint8List? imageBytes; // 여기 추가

  GroupItem({
    required this.id,
    required this.projectId,
    required this.groupType,
    required this.representativeImageId,
    required this.timeRangeStart,
    required this.timeRangeEnd,
    this.similarityScore,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
    this.imageBytes,
  });

  factory GroupItem.fromJson(Map<String, dynamic> json) {
    return GroupItem(
      id: json['id'],
      projectId: json['projectId'],
      groupType: json['groupType'],
      representativeImageId: json['representativeImageId'],
      timeRangeStart: DateTime.parse(json['timeRangeStart']),
      timeRangeEnd: DateTime.parse(json['timeRangeEnd']),
      similarityScore: json['similarityScore'],
      memberCount: json['memberCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}


class GroupApiService {
  late final Dio _dio;

  GroupApiService() {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('API_BASE_URL not found in .env file');
    }

    _dio = FlutterBetterAuth.dioClient;
    _dio.options.baseUrl = baseUrl;
  }

  /// 프로젝트 그룹 리스트 가져오기
  Future<List<GroupItem>> fetchProjectGroups({required String projectId}) async {
    try {
      final res = await _dio.get('/projects/$projectId/groups');

      final data = res.data['data'] as List<dynamic>;

      return data
          .map((e) => GroupItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error fetching project groups: $e');
      return [];
    }
  }
}
