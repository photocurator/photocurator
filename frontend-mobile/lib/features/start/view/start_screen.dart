import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/features/start/model/project_model.dart';
import 'package:photocurator/features/start/service/project_service.dart';
import 'package:photocurator/features/start/view/project_card.dart';
import 'package:photocurator/features/start/view/project_list_item.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final ProjectService _projectService = ProjectService();
  late Future<List<Project>> _projectsFuture;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _projectsFuture = _projectService.getProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FutureBuilder<List<Project>>(
            future: _projectsFuture,
            builder: (context, snapshot) {
              final projects = snapshot.data ?? [];
              final projectCount = projects.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Header Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Project Count
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$projectCount',
                            style: const TextStyle(
                              fontFamily: 'NotoSansRegular',
                              fontSize: 60,
                              height: 1.0,
                              color: AppColors.dg1C1F23,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '프로젝트',
                            style: TextStyle(
                              fontFamily: 'NotoSansRegular',
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // New Project Button
                      const _NewProjectButton(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lgE9ECEF),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/button/search.svg',
                          width: 15,
                          height: 15,
                          colorFilter: const ColorFilter.mode(
                            AppColors.lgADB5BD, 
                            BlendMode.srcIn
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Filter / View Options
                  if (snapshot.hasData && projects.isNotEmpty) ...[
                     const SizedBox(height: 14),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         // View Toggle Icon
                         GestureDetector(
                           onTap: () {
                             setState(() {
                               _isGridView = !_isGridView;
                             });
                           },
                           child: SvgPicture.asset(
                             _isGridView 
                               ? 'assets/icons/button/grid_btn.svg'
                               : 'assets/icons/button/list_btn.svg',
                             width: 24,
                             height: 24,
                           ),
                         ),
                         // Sort Dropdown
                         Row(
                           children: [
                             const Text(
                               '시간순',
                               style: TextStyle(
                                 fontFamily: 'NotoSansMedium',
                                 fontSize: 12,
                                 color: AppColors.dg495057,
                               ),
                             ),
                             const SizedBox(width: 4),
                             SvgPicture.asset(
                               'assets/icons/button/arrow_collapse_down_gray.svg', 
                               width: 6, 
                               height: 6, 
                             ),
                           ],
                         )
                       ],
                     ),
                     const SizedBox(height: 10),
                  ],

                  // Content Area
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : projects.isEmpty
                        ? _buildEmptyState()
                        : _isGridView 
                            ? _buildProjectGrid(projects)
                            : _buildProjectList(projects),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/button/image_auto_adjust.svg',
          width: 100, 
          height: 100,
        ),
        const SizedBox(height: 20),
        const Text(
          '생성된 프로젝트가 없습니다',
          style: TextStyle(
            fontFamily: 'NotoSansMedium',
            fontSize: 16,
            color: AppColors.dg1C1F23,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
             print("Create Project Tapped");
          },
          child: Column(
            children: const [
              Text(
                '생성하기',
                style: TextStyle(
                  fontFamily: 'NotoSansRegular',
                  fontSize: 12,
                  color: AppColors.dg495057,
                ),
              ),
              SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectGrid(List<Project> projects) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 157 / 199,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return ProjectCard(
          project: projects[index],
          isRecent: index == 0,
          onTap: () {
            print("Project ${projects[index].name} tapped");
            context.go('/home');
          },
        );
      },
    );
  }

  Widget _buildProjectList(List<Project> projects) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 20),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return ProjectListItem(
          project: projects[index],
          onTap: () {
            print("Project ${projects[index].name} tapped");
            context.go('/home');
          },
        );
      },
    );
  }
}

class _NewProjectButton extends StatelessWidget {
  const _NewProjectButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lgE9ECEF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/button/new_project_button_gray.svg',
            width: 30,
            height: 30,
          ),
          const SizedBox(height: 8),
          const Text(
            '새 프로젝트',
            style: TextStyle(
              fontFamily: 'NotoSansRegular',
              fontSize: 10,
              color: AppColors.dg495057,
            ),
          ),
        ],
      ),
    );
  }
}
