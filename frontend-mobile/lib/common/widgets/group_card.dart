import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:provider/provider.dart';
import '../../../provider/current_project_provider.dart';

class GroupCard extends StatelessWidget {
  final List<GroupItem> groups;
  final void Function(GroupItem)? onTap;

  const GroupCard({
    super.key,
    required this.groups,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final crossAxisSpacing = 16.0;
    final mainAxisSpacing = 16.0;
    final crossAxisCount = 2;

    // 카드 너비 계산
    final itemWidth =
        (deviceWidth - (crossAxisCount + 1) * crossAxisSpacing) / crossAxisCount;
    final itemHeight = itemWidth; // 1:1 비율

    if (groups.isEmpty) {
      return const Center(child: Text("그룹이 없습니다."));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: groups.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: itemWidth / itemHeight, // 1:1
        ),
        itemBuilder: (context, index) {
          final group = groups[index];

          return GestureDetector(
            onTap: () {
              if (onTap != null) onTap!(group);
              debugPrint('그룹 클릭: ${group.id}');
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lgE9ECEF,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // 배경 이미지
                    if (group.imageBytes != null)
                      Image.memory(
                        group.imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    else
                      Container(
                        color: AppColors.lgE9ECEF,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: AppColors.lgCBD1D6, // 원하는 색
                          ),
                        ),
                      ),

                    // Content Overlay
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                      // Title
                      Text(
                      group.groupType =="similar"? "유사 \n ${group.memberCount}" : "위치 \n ${group.memberCount}",
                          style: const TextStyle(
                          fontFamily: 'NotoSansMedium',
                      fontSize: 15,
                      color: AppColors.wh1, // White text
                      shadows: [
                      Shadow(
                      offset: Offset(0, 0),
                      blurRadius: 4,
                      color: Color.fromRGBO(28, 31, 40, 0.3),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Date
              Text(
                _formatDate(group.timeRangeStart, group.timeRangeEnd),
                style: const TextStyle(
                  fontFamily: 'NotoSansRegular',
                  fontSize: 10,
                  color: AppColors.wh1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              ],
            ),
          ),
          ],
          ),
          ),
          ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? start, DateTime? end) {
    DateTime? pickDate = end ?? start;
    if (pickDate == null) return '';
    return "${pickDate.year}.${pickDate.month.toString().padLeft(2, '0')}.${pickDate.day.toString().padLeft(2, '0')}";
  }
}
