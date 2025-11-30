import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/features/start/service/project_service.dart';
import 'package:photocurator/features/start/view/project_card.dart';

class SelectableProjectCard extends StatelessWidget {
  final Project project;
  final bool isSelected;
  final VoidCallback? onTap;

  const SelectableProjectCard({
    super.key,
    required this.project,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ProjectCard(
          project: project,
          isRecent: false, // Or pass this in if needed
        ),
      ),
    );
  }
}
