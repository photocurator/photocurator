import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:photocurator/common/theme/colors.dart';

import 'package:photocurator/features/start/service/project_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ProjectService _projectService = ProjectService();

  // [상태 변수]
  List<String> _searchTags = []; // 현재 활성화된 검색 태그들 ("강아지", "비행기" 등)
  bool _isSelectionMode = false; // 그리드 선택 모드 활성화 여부
  final Set<int> _selectedItemIndices = {}; // 선택된 결과 아이템 인덱스
  String? _selectedProjectId;
  String _selectedProjectName = '모든 프로젝트';

  // 더미 데이터 (검색 결과 예시)
  final int _dummyResultCount = 120;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // --- 액션 메서드 ---

  // 1. 검색어 제출 (쉼표로 분리하여 태그 추가)
  void _onSearchSubmitted(String value) {
    if (value.trim().isEmpty) return;

    final newTags = value.split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      // 중복 제거 후 추가 (원하시면 중복 허용 가능)
      for (var tag in newTags) {
        if (!_searchTags.contains(tag)) {
          _searchTags.add(tag);
        }
      }
      _searchController.clear();
      _isSelectionMode = false; // 검색 시 선택 모드 해제
    });
    // 검색 후에도 포커스 유지하려면: _searchFocusNode.requestFocus();
  }

  // 2. 태그 삭제
  void _removeTag(String tag) {
    setState(() {
      _searchTags.remove(tag);
    });
  }

  // 3. 전체 태그 삭제
  void _clearAllTags() {
    setState(() {
      _searchTags.clear();
      _isSelectionMode = false;
    });
  }

  // 4. 선택 모드 토글
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedItemIndices.clear(); // 모드 변경 시 선택 초기화
    });
  }

  // 4.5 선택 모드 토글 (프로젝트 선택)
  void _prjSelectionMode() async {
    // Navigate and get the selected project ID
    final selectedId = await context.push<String>('/project-selection');

    String newProjectName = '모든 프로젝트';
    if (selectedId != null) {
      // This is inefficient. A dedicated `getProjectById` would be better.
      final projects = await _projectService.getProjects();
      try {
        final selectedProject =
            projects.firstWhere((p) => p.id == selectedId);
        newProjectName = selectedProject.projectName;
      } catch (e) {
        // Handle case where project ID is invalid or not found
        print('Error finding project by ID: $e');
        _selectedProjectId = null;
      }
    }

    setState(() {
      _selectedProjectId = selectedId;
      _selectedProjectName = newProjectName;
    });
  }

  // 5. 그리드 아이템 선택/해제
  void _toggleItemSelection(int index) {
    setState(() {
      if (_selectedItemIndices.contains(index)) {
        _selectedItemIndices.remove(index);
      } else {
        _selectedItemIndices.add(index);
      }
    });
  }

  // 6. 전체 아이템 선택
  void _toggleSelectAllItems() {
    setState(() {
      if (_selectedItemIndices.length == _dummyResultCount) {
        _selectedItemIndices.clear();
      } else {
        _selectedItemIndices.addAll(List.generate(_dummyResultCount, (i) => i));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // [헤더 영역] 타이틀 + 버튼들
            _buildTopHeader(),

            // [검색바 영역]
            _buildSearchBar(),

            // [태그 리스트 영역] (태그가 있을 때만 표시)
            if (_searchTags.isNotEmpty) _buildTagList(),

            // [결과 정보 영역] (개수, 정렬, 선택옵션)
            _buildResultInfoBar(),

            // [결과 그리드 영역]
            Expanded(
              child: _buildResultGrid(),
            ),
          ],
        ),
      ),
      // 선택 모드일 때 하단 액션바 (다운로드, 삭제 등 - 시안 image_cb619f.png 참고)
      bottomNavigationBar: _isSelectionMode ? _buildBottomActionBar() : null,
    );
  }

  // --- 위젯 빌더 ---

  // 1. 상단 헤더 (스마트 검색 타이틀, 프로젝트 필터, 선택 버튼)
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 15, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '스마트 검색',
            style: TextStyle(
              fontFamily: 'NotoSansMedium',
              fontSize: 20,
              color: AppColors.dg1C1F23,
            ),
          ),
          Row(
            children: [
              // 모든 프로젝트 필터 버튼
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lgE9ECEF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _selectedProjectName,
                  style: const TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: 12,
                    color: AppColors.dg495057,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 선택 버튼
              GestureDetector(
                onTap: _prjSelectionMode,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lgE9ECEF,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '선택',
                    style: TextStyle(
                      fontFamily: 'NotoSansMedium',
                      fontSize: 12,
                      color: AppColors.dg495057,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. 검색 바
  // [수정됨] 검색바
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.5, vertical: 15),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // 1. 이미지가 없을 때를 대비한 기본 배경색
          color: const Color(0xFFF1F3F5),
          // 2. 그라데이션 이미지 배경
          image: const DecorationImage(
            image: AssetImage('assets/icons/image/search_box.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: _onSearchSubmitted,
          style: const TextStyle(
            fontFamily: 'NotoSansRegular',
            fontSize: 14,
            color: AppColors.dg1C1F23,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: '원하는 객체를 검색해보세요!   예) 강아지, 비행기',
            hintStyle: const TextStyle(
              fontFamily: 'NotoSansRegular',
              fontSize: 13,
              color: AppColors.lgADB5BD,
            ),
            // 3. 왼쪽 아이콘(Prefix) 제거 -> 텍스트 패딩 추가
            // 4. 오른쪽 아이콘(Suffix)을 검색(돋보기) 버튼으로 변경
            suffixIcon: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/button/search_bar_btn.svg',
                width: 17,
                height: 17,
                // 색상을 회색으로 통일 (필요시 제거)
                colorFilter: const ColorFilter.mode(AppColors.lgADB5BD, BlendMode.srcIn),
              ),
              onPressed: () => _onSearchSubmitted(_searchController.text),
            ),
            border: InputBorder.none,
            // 5. 왼쪽 여백 추가 (아이콘이 없으므로)
            contentPadding: const EdgeInsets.only(left: 20, top: 12, bottom: 12),
          ),
        ),
      ),
    );
  }


  // 3. 태그 리스트 (가로 스크롤)
  Widget _buildTagList() {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // 전체 취소 버튼
          GestureDetector(
            onTap: _clearAllTags,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.wh1,
                border: Border.all(color: AppColors.lgE9ECEF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: const [
                  Text(
                    '전체 취소',
                    style: TextStyle(
                      fontFamily: 'NotoSansMedium',
                      fontSize: 12,
                      color: AppColors.dg495057,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.close, size: 14, color: AppColors.lgADB5BD),
                ],
              ),
            ),
          ),
          // 개별 태그들
          ..._searchTags.map((tag) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5), // 태그 배경색
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text(
                    tag,
                    style: const TextStyle(
                      fontFamily: 'NotoSansRegular',
                      fontSize: 12,
                      color: AppColors.dg1C1F23,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _removeTag(tag),
                    child: const Icon(Icons.close, size: 14, color: AppColors.lgADB5BD),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 4. 결과 정보 바 (개수, 정렬, 전체선택)
  Widget _buildResultInfoBar() {
    // 태그가 없으면 숨기거나 다른 텍스트 표시
    if (_searchTags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 결과 개수 or 선택 개수
          _isSelectionMode
              ? GestureDetector(
            onTap: _toggleSelectAllItems,
            child: Row(
              children: [
                SvgPicture.asset(
                  _selectedItemIndices.length == _dummyResultCount
                      ? 'assets/icons/button/selected_button.svg'
                      : 'assets/icons/button/unselected_button.svg',
                  width: 14,
                  height: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _selectedItemIndices.isEmpty
                      ? '전체 선택'
                      : '${_selectedItemIndices.length}개 선택됨',
                  style: const TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: 14,
                    color: AppColors.dg1C1F23,
                  ),
                ),
              ],
            ),
          )
              : Text(
            '이미지 $_dummyResultCount', // 실제 데이터 개수 연동 필요
            style: const TextStyle(
              fontFamily: 'NotoSansRegular',
              fontSize: 13,
              color: AppColors.lgADB5BD,
            ),
          ),

          // 정렬 옵션 or 취소 버튼
          _isSelectionMode
              ? GestureDetector(
            onTap: _toggleSelectionMode,
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: 'NotoSansRegular',
                fontSize: 14,
                color: AppColors.dg1C1F23,
              ),
            ),
          )
              : Row(
            children: [
              const Text(
                '시간순',
                style: TextStyle(
                  fontFamily: 'NotoSansRegular',
                  fontSize: 12,
                  color: AppColors.dg1C1F23,
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 10, color: AppColors.lgE9ECEF),
              const SizedBox(width: 8),
              // 여기서 '선택'을 누르면 선택 모드 진입
              GestureDetector(
                onTap: _toggleSelectionMode,
                child: const Text(
                  '선택',
                  style: TextStyle(
                    fontFamily: 'NotoSansRegular',
                    fontSize: 12,
                    color: AppColors.dg1C1F23,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. 결과 그리드
  Widget _buildResultGrid() {
    if (_searchTags.isEmpty) {
      return const Center(
        child: Text(
          '검색어를 입력하여\n원하는 사진을 찾아보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.lgADB5BD,
            fontSize: 14,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _dummyResultCount, // 더미 개수
      itemBuilder: (context, index) {
        final isSelected = _selectedItemIndices.contains(index);

        return GestureDetector(
          onTap: () {
            if (_isSelectionMode) {
              _toggleItemSelection(index);
            } else {
              // TODO: 이미지 상세 보기
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 이미지 (더미 컬러 박스)
              Container(
                color: AppColors.lgE9ECEF,
                // 실제 이미지 연동 시:
                // child: Image.network(url, fit: BoxFit.cover),
              ),

              // 선택 모드일 때 체크박스 오버레이
              if (_isSelectionMode) ...[
                // 선택 시 어두운 배경
                if (isSelected)
                  Container(color: Colors.black.withOpacity(0.1)),

                // 체크 아이콘
                Positioned(
                  top: 8,
                  left: 8,
                  child: SvgPicture.asset(
                    isSelected
                        ? 'assets/icons/button/select_button_blue.svg'
                        : 'assets/icons/button/select_button0.svg',
                    width: 14,
                    height: 14,
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  // 6. 하단 액션 바 (선택 모드용)
  Widget _buildBottomActionBar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.wh1,
        border: Border(top: BorderSide(color: AppColors.lgE9ECEF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton('좋아요', 'assets/icons/button/empty_heart_gray.svg'), // 아이콘 에셋 필요
          _buildActionButton('복사', 'assets/icons/button/duplicate_gray.svg'),
          _buildActionButton('다운로드', 'assets/icons/button/arrow_collapse_down_gray.svg'),
          _buildActionButton('삭제', 'assets/icons/button/empty_bin_gray.svg'),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, String iconPath) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 아이콘 (에셋이 없으면 기본 아이콘 대체)
        SvgPicture.asset(
          iconPath,
          width: 20,
          height: 20,
          placeholderBuilder: (context) => const Icon(Icons.circle, size: 24, color: AppColors.dg495057),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.dg495057,
          ),
        ),
      ],
    );
  }
}