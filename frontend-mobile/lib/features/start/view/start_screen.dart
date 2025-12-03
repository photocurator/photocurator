import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Provider import
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/features/start/view/project_card.dart';
import 'package:photocurator/features/start/view/project_list_item.dart';
import 'package:photocurator/features/start/view_model/start_view_model.dart';
import 'package:photocurator/provider/current_project_provider.dart';

// 분리한 위젯들 import
import '../service/project_service.dart';
import 'widgets/new_project_card.dart';
import 'widgets/search_button.dart';
import 'widgets/empty_project_view.dart';
import 'widgets/create_project_dialog.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  // UI 입력 컨트롤러는 View의 생명주기와 묶여있으므로 여기서 관리합니다.
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _projectNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. ViewModel 주입 및 초기 데이터 로드 (fetchProjects)
    return ChangeNotifierProvider(
      create: (_) => StartViewModel()..fetchProjects(),
      child: Scaffold(
        backgroundColor: AppColors.wh1,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            // 2. Consumer를 통해 ViewModel의 상태 변화를 구독하여 화면 갱신
            child: Consumer<StartViewModel>(
              builder: (context, viewModel, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                    // --- 헤더 영역 (검색바 / 검색버튼) ---
                    SizedBox(
                      height: 44,
                      child: viewModel.isSearching
                          ? _buildSearchBar(viewModel)
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SearchButton(onTap: () {
                            viewModel.toggleSearchMode();
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // --- 대시보드 영역 (프로젝트 개수 / 새 프로젝트 버튼) ---
                    SizedBox(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${viewModel.projectCount}',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansRegular',
                                    fontSize: 60,
                                    height: 1.0,
                                    color: AppColors.dg1C1F23,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '프로젝트',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansRegular',
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 다이얼로그 띄우기 (ViewModel과 Context 전달)
                          NewProjectCard(
                            onTap: () => _showCreateProjectDialog(context, viewModel),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- 뷰 옵션 & 정렬 (로딩 끝났고, 데이터가 있을 때만 표시) ---
                    if (!viewModel.isLoading && viewModel.hasProjects) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 그리드/리스트 토글 버튼
                          GestureDetector(
                            onTap: viewModel.toggleViewMode,
                            child: SvgPicture.asset(
                              viewModel.isGridView
                                  ? 'assets/icons/button/grid_btn.svg'
                                  : 'assets/icons/button/list_btn.svg',
                              width: 24,
                              height: 24,
                              // SVG 에러 시 대체 아이콘
                              placeholderBuilder: (context) => Icon(
                                viewModel.isGridView ? Icons.grid_view : Icons.list,
                                color: AppColors.lgADB5BD,
                              ),
                            ),
                          ),

                          // 정렬 토글 버튼 (이름순/시간순)
                          GestureDetector(
                            onTap: viewModel.toggleSort,
                            child: Row(
                              children: [
                                Text(
                                  viewModel.currentSort == SortType.name ? '이름순' : '시간순',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansRegular',
                                    fontSize: 13,
                                    color: AppColors.dg1C1F23,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                SvgPicture.asset(
                                  'assets/icons/button/down_arrow.svg',
                                  width: 8,
                                  height: 8,
                                  placeholderBuilder: (context) =>
                                  const Icon(Icons.keyboard_arrow_down, size: 16),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // --- 컨텐츠 리스트 영역 ---
                    Expanded(
                      child: viewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : viewModel.displayProjects.isEmpty
                      // 표시할 프로젝트가 없을 때 (검색 결과 없음 or 전체 없음)
                          ? EmptyProjectView(
                        onCreateTap: () => _showCreateProjectDialog(context, viewModel),
                        // 전체 프로젝트는 있는데 검색 결과만 없는 경우인지 확인
                        isSearchResult: viewModel.hasProjects,
                      )
                          : viewModel.isGridView
                          ? _buildProjectGrid(viewModel.displayProjects)
                          : _buildProjectList(viewModel.displayProjects),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- Sub Widgets (View 내부에서만 쓰는 위젯) ---

  // 검색바: TextField 입력 이벤트를 ViewModel로 전달
  Widget _buildSearchBar(StartViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textAlignVertical: TextAlignVertical.center,
              // [중요] 입력값이 변할 때마다 ViewModel에 알림
              onChanged: viewModel.updateSearchQuery,
              style: const TextStyle(
                fontFamily: 'NotoSansRegular',
                fontSize: 14,
                color: AppColors.dg1C1F23,
              ),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'project',
                hintStyle: TextStyle(
                    fontFamily: 'NotoSansRegular', color: AppColors.lgADB5BD),
                prefixIcon:
                Icon(Icons.search, color: AppColors.lgADB5BD, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            // 취소 버튼 누르면: 검색어 초기화 -> ViewModel 검색 모드 종료 -> 키보드 닫기
            _searchController.clear();
            viewModel.toggleSearchMode(clearQuery: true);
            FocusScope.of(context).unfocus();
          },
          child: const Text(
            '취소',
            style: TextStyle(
              fontFamily: 'NotoSansRegular',
              fontSize: 14,
              color: AppColors.dg1C1F23,
            ),
          ),
        ),
      ],
    );
  }

  // 그리드 뷰 빌더
  Widget _buildProjectGrid(List<Project> projects) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.75,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return ProjectCard(
          key: ValueKey(projects[index].id),
          project: projects[index],
          isRecent: false,
          onTap: () async {
            // Provider에 현재 프로젝트 세팅
            final currentProjectProvider = context.read<CurrentProjectProvider>();
            currentProjectProvider.setProject(projects[index]);

            // 2) 이전 프로젝트 이미지 초기화
            final imagesProvider = context.read<CurrentProjectImagesProvider>();
            imagesProvider.clear();

            // 3) 새 프로젝트 이미지 로드
            await imagesProvider.loadAllImages(projects[index].id);

            // 화면 이동
            context.go('/start/home/${projects[index].id}');
          },
        );
      },
    );
  }

  // 리스트 뷰 빌더
  Widget _buildProjectList(List<Project> projects) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return ProjectListItem(
          key: ValueKey(projects[index].id),
          project: projects[index],
          onTap: () async {
            // Provider에 현재 프로젝트 세팅
            final currentProjectProvider = context.read<CurrentProjectProvider>();
            currentProjectProvider.setProject(projects[index]);

            // 2) 이전 프로젝트 이미지 초기화
            final imagesProvider = context.read<CurrentProjectImagesProvider>();
            imagesProvider.clear();

            // 3) 새 프로젝트 이미지 로드
            await imagesProvider.loadAllImages(projects[index].id);

            // 화면 이동
            context.go('/start/home/${projects[index].id}');
          },
        );
      },
    );
  }

  // 프로젝트 생성 다이얼로그 호출
  Future<void> _showCreateProjectDialog(BuildContext context, StartViewModel viewModel) {
    _projectNameController.clear();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return CreateProjectDialog(
          controller: _projectNameController,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onConfirm: () {
            // First, pop the dialog
            Navigator.of(dialogContext).pop();
            // Then, navigate to the photo selection screen
            context.go(
              '/project/add-photos',
              extra: _projectNameController.text,
            );
          },
        );
      },
    );
  }
}
