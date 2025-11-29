import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';

class CreateProjectDialog extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const CreateProjectDialog({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '새 프로젝트',
              style: TextStyle(
                fontFamily: 'NotoSansBold',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dg1C1F23,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: AppColors.dg1C1F23),
              decoration: InputDecoration(
                hintText: '프로젝트 이름 입력 (20자 이내 / 특수문자 불가)',
                hintStyle: const TextStyle(
                  fontFamily: 'NotoSansRegular',
                  fontSize: 12,
                  color: AppColors.lgADB5BD,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    const BorderSide(color: AppColors.primary, width: 1)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppColors.dg495057,
                    ),
                    child: const Text('취소',
                        style: TextStyle(
                            fontFamily: 'NotoSansMedium', fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: onConfirm,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('다음',
                        style: TextStyle(
                            fontFamily: 'NotoSansMedium',
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}