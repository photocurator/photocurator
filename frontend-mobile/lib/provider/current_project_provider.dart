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
  List<ImageItem> allImages = [];
  List<ImageItem> hiddenImages = [];
  List<ImageItem> trashImages = [];
  List<ImageItem> bestShotImages = [];
  List<ImageItem> pickedImages = [];

  bool isLoading = false;

  /// 프로젝트에 해당하는 모든 이미지 로드
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
      allImages = all.where((img) => !img.isRejected && !trashIds.contains(img.id)).toList();

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

    } catch (e) {
      print('이미지 로드 실패: $e');
      // 필요하면 error 상태 처리 가능
    }

    isLoading = false;
    notifyListeners();
  }

  /// 특정 프로젝트 이미지 초기화
  void clear() {
    allImages = [];
    hiddenImages = [];
    trashImages = [];
    bestShotImages = [];
    pickedImages = [];
    notifyListeners();
  }
}









class ProjectImagesController extends ChangeNotifier {
  final CurrentProjectProvider currentProjectProvider;
  final ApiService apiService;

  ProjectImagesController(this.currentProjectProvider, this.apiService) {
    currentProjectProvider.addListener(_onProjectChanged);
  }

  List<ImageItem> _images = [];
  bool isLoading = false;

  List<ImageItem> get images => _images;

  void _onProjectChanged() {
    final project = currentProjectProvider.currentProject;
    if (project != null) {
      loadImages(project.id);
    } else {
      _images = [];
      notifyListeners();
    }
  }

  Future<void> loadImages(String projectId) async {
    isLoading = true;
    notifyListeners();

    try {
      final fetchedImages = await apiService.fetchProjectImages(projectId: projectId);
      _images = fetchedImages;
    } catch (e) {
      print("이미지 불러오기 실패: $e");
      _images = [];
    }

    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    currentProjectProvider.removeListener(_onProjectChanged);
    super.dispose();
  }
}


