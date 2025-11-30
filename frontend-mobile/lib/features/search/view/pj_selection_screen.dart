import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/features/search/widgets/selectable_project_card.dart';
import 'package:photocurator/features/search/widgets/selectable_project_list_item.dart';
import 'package:photocurator/features/start/service/project_service.dart';
import 'package:photocurator/features/start/view/widgets/empty_project_view.dart';
import 'package:photocurator/features/start/view_model/start_view_model.dart';
import 'package:provider/provider.dart';

class PjSelectionScreen extends StatefulWidget {
  const PjSelectionScreen({super.key});

  @override
  State<PjSelectionScreen> createState() => _PjSelectionScreenState();
}

class _PjSelectionScreenState extends State<PjSelectionScreen> {
  String? _selectedProjectId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StartViewModel()..fetchProjects(),
      child: Scaffold(
        backgroundColor: AppColors.wh1,
        appBar: AppBar(
          backgroundColor: AppColors.wh1,
          elevation: 0,
          title: const Text(
            '프로젝트 선택',
            style: TextStyle(
                fontFamily: 'NotoSansMedium',
                fontSize: 20,
                color: AppColors.dg1C1F23),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: SvgPicture.asset('assets/icons/button/back.svg'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedProjectId);
              },
              child: const Text(
                '완료',
                style: TextStyle(
                  fontFamily: 'NotoSansMedium',
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: AppColors.lgE9ECEF,
              height: 1.0,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Consumer<StartViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                children: [
                  if (!viewModel.isLoading && viewModel.hasProjects) ...[
                    const SizedBox(height: 20),
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
                          ),
                        ),

                        // 정렬 토글 버튼 (이름순/시간순)
                        GestureDetector(
                          onTap: viewModel.toggleSort,
                          child: Row(
                            children: [
                              Text(
                                viewModel.currentSort == SortType.name
                                    ? '이름순'
                                    : '시간순',
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
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Expanded(
                    child: viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : viewModel.displayProjects.isEmpty
                            ? EmptyProjectView(
                                onCreateTap: () {}, isSearchResult: false)
                            : viewModel.isGridView
                                ? _buildProjectGrid(
                                    viewModel.displayProjects)
                                : _buildProjectList(
                                    viewModel.displayProjects),
                  ),
                ],
              );
            },
          ),
        ),
      ),
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
        final project = projects[index];
        return SelectableProjectCard(
          project: project,
          isSelected: _selectedProjectId == project.id,
          onTap: () {
            setState(() {
              if (_selectedProjectId == project.id) {
                _selectedProjectId = null;
              } else {
                _selectedProjectId = project.id;
              }
            });
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
        final project = projects[index];
        return SelectableProjectListItem(
          project: project,
          isSelected: _selectedProjectId == project.id,
          onTap: () {
            setState(() {
              if (_selectedProjectId == project.id) {
                _selectedProjectId = null;
              } else {
                _selectedProjectId = project.id;
              }
            });
          },
        );
      },
    );
  }
}
