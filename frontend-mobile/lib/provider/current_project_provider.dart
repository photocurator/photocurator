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


