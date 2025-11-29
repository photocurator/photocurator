import 'package:photocurator/features/start/view_model/project_model.dart';

class ProjectService {
  // Mock data to simulate API response
  Future<List<Project>> getProjects() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    return [
      Project(
        projectId: '1',
        name: 'Project name',
        createdAt: DateTime(2024, 7, 10),
        coverImageId: null, 
      ),
      Project(
        projectId: '2',
        name: '영국 여행',
        createdAt: DateTime(2024, 7, 10),
        coverImageId: null,
      ),
      Project(
        projectId: '3',
        name: '7월 부산',
        createdAt: DateTime(2024, 7, 10),
        coverImageId: null,
      ),
      Project(
        projectId: '4',
        name: 'Project name',
        createdAt: DateTime(2024, 7, 10),
        coverImageId: null,
      ),
      Project(
        projectId: '5',
        name: 'Project name',
        createdAt: DateTime(2024, 7, 10),
        coverImageId: null,
      ),
       Project(
        projectId: '6',
        name: 'Project name',
        createdAt: DateTime(2024, 7, 10),
        coverImageId: null,
      ),
    ];
  }
}

