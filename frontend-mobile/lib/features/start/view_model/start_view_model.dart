import 'package:flutter/material.dart';
import 'package:photocurator/features/start/view_model/project_model.dart';
import 'package:photocurator/features/start/service/project_service.dart';

enum SortType {
  name,
  time,
}

class StartViewModel extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();

  // --- State Variables ---
  List<Project> _allProjects = []; // 원본 데이터
  List<Project> _displayProjects = []; // 화면 표시용 (필터/정렬 적용됨)

  bool _isLoading = false;
  bool _isGridView = true;
  bool _isSearching = false;
  SortType _currentSort = SortType.name;
  String _searchQuery = '';

  // --- Getters ---
  List<Project> get displayProjects => _displayProjects;
  int get projectCount => _displayProjects.length;
  bool get hasProjects => _allProjects.isNotEmpty; // 전체 프로젝트 존재 여부
  bool get isLoading => _isLoading;
  bool get isGridView => _isGridView;
  bool get isSearching => _isSearching;
  SortType get currentSort => _currentSort;
  String get searchQuery => _searchQuery;

  // --- Actions ---

  /// 초기 데이터 로드
  Future<void> fetchProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allProjects = await _projectService.getProjects();
      _applyFilterAndSort(); // 데이터 로드 후 필터/정렬 적용
    } catch (e) {
      debugPrint('Error fetching projects: $e');
      _allProjects = [];
      _displayProjects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 검색어 업데이트
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _applyFilterAndSort();
    notifyListeners();
  }

  /// 뷰 모드 토글 (그리드 <-> 리스트)
  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  /// 검색 모드 토글
  void toggleSearchMode({bool clearQuery = false}) {
    _isSearching = !_isSearching;
    if (!_isSearching || clearQuery) {
      _searchQuery = '';
      _applyFilterAndSort();
    }
    notifyListeners();
  }

  /// 정렬 모드 토글 (이름순 <-> 시간순)
  void toggleSort() {
    _currentSort = _currentSort == SortType.name ? SortType.time : SortType.name;
    _applyFilterAndSort();
    notifyListeners();
  }

  /// 프로젝트 생성 (API 연동 시 구현)
  Future<void> createProject(String name) async {
    // TODO: _projectService.createProject(name);
    // await fetchProjects(); // 생성 후 목록 갱신
    debugPrint('Creating project: $name');
  }

  // --- Private Helpers ---

  /// 필터링 및 정렬 로직 일괄 처리
  void _applyFilterAndSort() {
    // 1. 검색 필터링
    List<Project> temp = _searchQuery.isEmpty
        ? List.from(_allProjects)
        : _allProjects
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    // 2. 정렬 적용
    if (_currentSort == SortType.name) {
      temp.sort((a, b) => a.name.compareTo(b.name));
    } else {
      // 시간순 정렬 (모델에 날짜가 없다면 기본 순서 혹은 반대 순서)
      // temp.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    _displayProjects = temp;
  }
}