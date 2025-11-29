import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/features/start/service/project_service.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  final bool isRecent;
  final VoidCallback? onTap;

  const ProjectCard({
    super.key,
    required this.project,
    this.isRecent = false,
    this.onTap,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  late final ProjectService _projectService;
  Future<Uint8List?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _projectService = ProjectService();
    if (widget.project.coverImageUrl != null && widget.project.coverImageUrl!.isNotEmpty) {
      _imageFuture = _projectService.getImage(widget.project.coverImageUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lgE9ECEF, // Placeholder color from design
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Background Image
              if (_imageFuture != null)
                FutureBuilder<Uint8List?>(
                  future: _imageFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data != null) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      );
                    } else if (snapshot.hasError) {
                      debugPrint(
                          'Error loading image for ${widget.project.projectName}: ${snapshot.error}');
                      return Container(
                        color: AppColors.lgE9ECEF, // Fallback color
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image,
                            color: AppColors.lgADB5BD),
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),

              // Content Overlay
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      widget.project.projectName,
                      style: const TextStyle(
                        fontFamily: 'NotoSansMedium',
                        fontSize: 16,
                        color: AppColors.wh1, // White text
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 4,
                            color: Color.fromRGBO(28, 31, 35, 0.1),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Date
                    Text(
                      "${widget.project.createdAt.year}.${widget.project.createdAt.month.toString().padLeft(2, '0')}.${widget.project.createdAt.day.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontFamily: 'NotoSansRegular',
                        fontSize: 10,
                        color: AppColors.wh1,
                      ),
                    ),
                  ],
                ),
              ),

              // Recent Badge
              if (widget.isRecent)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.wh1,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border.all(
                        color: const Color.fromRGBO(28, 31, 35, 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/button/history_light_gray.svg',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '최근 열람',
                          style: TextStyle(
                            fontFamily: 'NotoSansRegular',
                            fontSize: 8,
                            color: AppColors.lgADB5BD,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}