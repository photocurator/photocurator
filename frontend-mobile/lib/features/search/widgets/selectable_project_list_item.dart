import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/features/start/service/project_service.dart';
import 'package:photocurator/features/start/view/project_list_item.dart';

class SelectableProjectListItem extends StatelessWidget {
  final Project project;
  final bool isSelected;
  final VoidCallback? onTap;

  const SelectableProjectListItem({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          borderRadius: isSelected ? BorderRadius.circular(8) : null,
          color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
        ),
        child: ProjectListItem(
          project: project,
        ),
      ),
    );
  }
}
