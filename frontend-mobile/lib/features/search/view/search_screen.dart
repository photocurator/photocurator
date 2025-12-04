import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/features/search/service/search_service.dart';
import 'package:photocurator/features/start/service/project_service.dart';
import 'package:photocurator/features/home/detail_view/photo_screen.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';

class SearchScreen extends StatefulWidget {
  final String? initialProjectId;

  const SearchScreen({Key? key, this.initialProjectId}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ProjectService _projectService = ProjectService();
  final SearchService _searchService = SearchService();
  int _page = 1;
  final int _limit = 100;
  final Map<String, Future<Uint8List?>> _imageBytesFutures = {};
  int _searchToken = 0;

  // [상태 변수]
  List<String> _searchTags = [];
  bool _isSelectionMode = false;
  final Set<int> _selectedItemIndices = {};
  String? _selectedProjectId;
  String _selectedProjectName = '모든 프로젝트';
  List<SearchResultImage> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProjectId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initProjectFromOutside(widget.initialProjectId!);
      });
    }
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final int currentToken = ++_searchToken;
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _searchService.searchImages(
        projectId: _selectedProjectId,
        detectedObjects: _searchTags,
        page: _page,
        limit: _limit,
      );
      if (!mounted) return;
      if (currentToken != _searchToken) return;
      setState(() {
        _imageBytesFutures.clear();
        _searchResults = results;
        _selectedItemIndices.clear();
        if (_isSelectionMode && results.isEmpty) {
          _isSelectionMode = false;
        }
      });
    } catch (e) {
      print('Search failed: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- 검색 메서드 ---
  void _onSearchSubmitted(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _searchTags = [];
        _isSelectionMode = false;
        _searchController.clear();
        _selectedItemIndices.clear();
        _page = 1;
      });
      _performSearch();
      return;
    }

    final newTags = value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      _searchTags = newTags.toSet().toList();
      _isSelectionMode = false;
      _selectedItemIndices.clear();
      _searchController.clear();
      _page = 1;
    });
    _performSearch();
  }

  void _removeTag(String tag) {
    setState(() {
      _searchTags.remove(tag);
      _selectedItemIndices.clear();
      _page = 1;
    });
    _performSearch();
  }

  void _clearAllTags() {
    setState(() {
      _searchTags.clear();
      _isSelectionMode = false;
      _selectedItemIndices.clear();
      _page = 1;
    });
    _performSearch();
  }

  // 더보기 검색 버튼 이동 시
  Future<void> _initProjectFromOutside(String projectId) async {
    String newProjectName = '모든 프로젝트';

    final projects = await _projectService.getProjects();
    try {
      final selectedProject = projects.firstWhere((p) => p.id == projectId);
      newProjectName = selectedProject.projectName;
    } catch (e) {
      print('Error finding project by ID: $e');
    }

    setState(() {
      _selectedProjectId = projectId;
      _selectedProjectName = newProjectName;
    });

    _performSearch();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedItemIndices.clear();
    });
  }

  void _prjSelectionMode() async {
    final selectedId = await context.push<String>('/project-selection');

    String newProjectName = '모든 프로젝트';
    if (selectedId != null) {
      final projects = await _projectService.getProjects();
      try {
        final selectedProject = projects.firstWhere((p) => p.id == selectedId);
        newProjectName = selectedProject.projectName;
      } catch (e) {
        print('Error finding project by ID: $e');
      }
    }

    setState(() {
      _selectedProjectId = selectedId;
      _selectedProjectName = newProjectName;
    });
    _performSearch();
  }

  void _toggleItemSelection(int index) {
    setState(() {
      if (_selectedItemIndices.contains(index)) {
        _selectedItemIndices.remove(index);
      } else {
        _selectedItemIndices.add(index);
      }
    });
  }

  Future<void> _togglePick(int index) async {
    final item = _searchResults[index];
    final newValue = !item.isPicked;
    final updated = await _searchService.updateImageSelection(
      imageId: item.id,
      isPicked: newValue,
      rating: item.rating,
    );
    if (!mounted) return;
    if (updated) {
      setState(() {
        _searchResults[index] = SearchResultImage(
          id: item.id,
          url: item.url,
          thumbnailUrl: item.thumbnailUrl,
          qualityScore: item.qualityScore,
          createdAt: item.createdAt,
          isPicked: newValue,
          rating: item.rating,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아요 상태를 변경하지 못했습니다.')),
      );
    }
  }

  void _openDetail(int index) {
    final images = _searchResults
        .map(
          (result) => ImageItem(
            id: result.id,
            createdAt: result.createdAt ?? DateTime.now(),
            qualityScore: result.qualityScore,
            isPicked: result.isPicked,
            rating: result.rating,
          ),
        )
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoScreen(
          images: images,
          initialIndex: index,
        ),
      ),
    );
  }

  void _toggleSelectAllItems() {
    setState(() {
      if (_selectedItemIndices.length == _searchResults.length) {
        _selectedItemIndices.clear();
      } else {
        _selectedItemIndices.addAll(List.generate(_searchResults.length, (i) => i));
      }
    });
  }

  List<SearchResultImage> get _selectedImages =>
      _selectedItemIndices.map((index) => _searchResults[index]).toList();

  Future<void> _likeSelected() async {
    if (_selectedItemIndices.isEmpty) return;

    final shouldPick = _selectedImages.any((img) => !img.isPicked);
    for (final index in _selectedItemIndices) {
      final item = _searchResults[index];
      final updated = await _searchService.updateImageSelection(
        imageId: item.id,
        isPicked: shouldPick,
        rating: item.rating,
      );
      if (updated) {
        setState(() {
          _searchResults[index] = SearchResultImage(
            id: item.id,
            url: item.url,
            thumbnailUrl: item.thumbnailUrl,
            qualityScore: item.qualityScore,
            createdAt: item.createdAt,
            isPicked: shouldPick,
            rating: item.rating,
          );
        });
      }
    }
  }

  Future<void> _downloadSelected() async {
    if (_selectedItemIndices.isEmpty) return;

    final PermissionState permissionState = await PhotoManager.requestPermissionExtend();
    if (!permissionState.isAuth) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장을 위해 갤러리 접근 권한이 필요합니다.')),
      );
      return;
    }

    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API_BASE_URL이 설정되지 않았습니다.')),
      );
      return;
    }

    final dio = FlutterBetterAuth.dioClient;
    dio.options.baseUrl = baseUrl;

    for (final image in _selectedImages) {
      try {
        final response = await dio.get(
          '/images/${image.id}/file',
          options: Options(responseType: ResponseType.bytes),
        );
        final data = response.data;
        final bytes = data is Uint8List
            ? data
            : data is List<int>
                ? Uint8List.fromList(data)
                : null;
        if (bytes == null) continue;

        await PhotoManager.editor.saveImage(
          bytes,
          filename: 'photo_${image.id}',
        );
      } catch (e) {
        debugPrint('Failed to download image ${image.id}: $e');
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('선택한 이미지를 저장했습니다.')),
    );
  }

  Future<void> _deleteSelected() async {
    if (_selectedItemIndices.isEmpty) return;
    final ids = _selectedImages.map((e) => e.id).toList();
    final success = await ApiService().batchRejectImages(imageIds: ids);
    if (!mounted) return;
    if (success) {
      setState(() {
        _searchResults = List.from(_searchResults)
          ..removeWhere((img) => ids.contains(img.id));
        _selectedItemIndices.clear();
        if (_searchResults.isEmpty) {
          _isSelectionMode = false;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 이미지를 삭제했습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopHeader(),
            _buildSearchBar(),
            if (_searchTags.isNotEmpty) _buildTagList(),
            _buildResultInfoBar(),
            Expanded(child: _buildResultGrid()),
          ],
        ),
      ),
      bottomNavigationBar: _isSelectionMode ? _buildBottomActionBar() : null,
    );
  }

  // --- 위젯 빌더 ---
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 15, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('스마트 검색',
              style: TextStyle(
                  fontFamily: 'NotoSansMedium',
                  fontSize: 20,
                  color: AppColors.dg1C1F23)),
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lgE9ECEF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                    _selectedProjectName.length > 10
                        ? _selectedProjectName.substring(0, 10) + "..."
                        : _selectedProjectName,
                    style: const TextStyle(
                        fontFamily: 'NotoSansMedium',
                        fontSize: 12,
                        color: AppColors.dg495057)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _prjSelectionMode,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.lgE9ECEF,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Text('선택',
                      style: TextStyle(
                          fontFamily: 'NotoSansMedium',
                          fontSize: 12,
                          color: AppColors.dg495057)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.5, right: 20.5, top: 15, bottom: 10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFFF1F3F5),
          image: const DecorationImage(
              image: AssetImage('assets/icons/image/search_box.png'),
              fit: BoxFit.fill),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: _onSearchSubmitted,
          style: const TextStyle(
              fontFamily: 'NotoSansRegular',
              fontSize: 14,
              color: AppColors.dg1C1F23),
          decoration: InputDecoration(
            isDense: true,
            hintText: '원하는 객체를 검색해보세요!   예) 강아지, 비행기',
            hintStyle: const TextStyle(
                fontFamily: 'NotoSansRegular',
                fontSize: 13,
                color: AppColors.lgADB5BD),
            suffixIcon: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/button/search_bar_btn.svg',
                width: 17,
                height: 17,
                colorFilter: const ColorFilter.mode(
                    AppColors.lgADB5BD, BlendMode.srcIn),
              ),
              onPressed: () => _onSearchSubmitted(_searchController.text),
            ),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.only(left: 20, top: 12, bottom: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTagList() {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 8), // 태그가 있을 때만 아래 여백 추가
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          GestureDetector(
            onTap: _clearAllTags,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              decoration: BoxDecoration(
                  color: AppColors.wh1,
                  border: Border.all(color: AppColors.lgE9ECEF),
                  borderRadius: BorderRadius.circular(6)),
              child: Row(children: const [
                Text('전체 취소',
                    style: TextStyle(
                        fontFamily: 'NotoSansMedium',
                        fontSize: 12,
                        color: AppColors.dg495057)),
                SizedBox(width: 4),
                Icon(Icons.close, size: 14, color: AppColors.lgADB5BD)
              ]),
            ),
          ),
          ..._searchTags.map((tag) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                Text(tag,
                    style: const TextStyle(
                        fontFamily: 'NotoSansRegular',
                        fontSize: 12,
                        color: AppColors.dg1C1F23)),
                const SizedBox(width: 6),
                GestureDetector(
                    onTap: () => _removeTag(tag),
                    child: const Icon(Icons.close,
                        size: 14, color: AppColors.lgADB5BD))
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultInfoBar() {
    if (_searchResults.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _isSelectionMode
              ? GestureDetector(
              onTap: _toggleSelectAllItems,
              child: Row(children: [
                SvgPicture.asset(
                  _selectedItemIndices.length == _searchResults.length
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
                        color: AppColors.dg1C1F23))
              ]))
              : Text('이미지 ${_searchResults.length}',
              style: const TextStyle(
                  fontFamily: 'NotoSansRegular',
                  fontSize: 13,
                  color: AppColors.lgADB5BD)),
          _isSelectionMode
              ? GestureDetector(
              onTap: _toggleSelectionMode,
              child: const Text('취소',
                  style: TextStyle(
                      fontFamily: 'NotoSansRegular',
                      fontSize: 14,
                      color: AppColors.dg1C1F23)))
              : Row(children: [
            const Text('시간순',
                style: TextStyle(
                    fontFamily: 'NotoSansRegular',
                    fontSize: 12,
                    color: AppColors.dg1C1F23)),
            const SizedBox(width: 8),
            Container(
                width: 1, height: 10, color: AppColors.lgE9ECEF),
            const SizedBox(width: 8),
            GestureDetector(
                onTap: _toggleSelectionMode,
                child: const Text('선택',
                    style: TextStyle(
                        fontFamily: 'NotoSansRegular',
                        fontSize: 12,
                        color: AppColors.dg1C1F23)))
          ])
        ],
      ),
    );
  }

  Widget _buildResultGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(
          child: Text('검색 결과가 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.lgADB5BD, fontSize: 14)));
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedItemIndices.contains(index);
        final imageUrl = _searchResults[index].thumbnailUrl;

        return GestureDetector(
          onTap: () {
            if (_isSelectionMode) {
              _toggleItemSelection(index);
            } else {
              _openDetail(index);
            }
          },
          child: FutureBuilder<Uint8List?>(
            future: _imageBytesFutures.putIfAbsent(
                imageUrl, () => _searchService.fetchImageBytes(imageUrl)),
            builder: (context, snapshot) {
              final bytes = snapshot.data;

              return Stack(fit: StackFit.expand, children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (bytes != null)
                  Image.memory(bytes, fit: BoxFit.cover)
                else
                  const Icon(Icons.error),
                if (_isSelectionMode) ...[
                  if (isSelected)
                    Container(color: Colors.black.withOpacity(0.1)),
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
                  )
                ],
                if (!_isSelectionMode)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _togglePick(index),
                      child: SvgPicture.asset(
                        _searchResults[index].isPicked
                            ? 'assets/icons/button/filled_heart.svg'
                            : 'assets/icons/button/empty_heart_gray.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
              ]);
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
          color: AppColors.wh1,
          border: Border(top: BorderSide(color: AppColors.lgE9ECEF))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _buildActionButton(
            '좋아요', 'assets/icons/button/empty_heart_gray.svg', _likeSelected),
        _buildActionButton(
            '다운로드', 'assets/icons/button/download_gray.svg', _downloadSelected),
        _buildActionButton(
            '삭제', 'assets/icons/button/trash_bin_gray.svg', _deleteSelected),
      ]),
    );
  }

  Widget _buildActionButton(String label, String iconPath, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(iconPath,
              width: 20,
              height: 20,
              placeholderBuilder: (context) =>
              const Icon(Icons.circle, size: 24, color: AppColors.dg495057)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.dg495057))
        ],
      ),
    );
  }
}
