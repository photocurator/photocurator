import 'package:flutter/material.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/theme/colors.dart';

// 회원 탈퇴 화면
class WithdrawScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wh1,
        appBar: DetailAppBar(
          title: "회원 탈퇴",
          rightWidget: null,
        ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ▼▼▼ 구분선 추가 ▼▼▼
          Container(
            height: 10,
            color: AppColors.lgE9ECEF,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 147),
                  Image.asset(
                    'assets/icons/image/withdraw_logo.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 25),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'NotoSansRegular',
                        fontSize: 14,
                        color: AppColors.dg495057,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(text: "지금까지 "),
                        TextSpan(
                          text: "포토큐레이터",
                          style: TextStyle(
                              fontFamily: 'NotoSansMedium',
                              color: AppColors.primary),
                        ),
                        TextSpan(text: "를\n이용해 주셔서 감사합니다"),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildPrimaryButton(
                    context: context,
                    label: "탈퇴하기",
                    filled: false,
                    onTap: () => _showConfirmDialog(context),
                  ),
                  const SizedBox(height: 10),
                  _buildPrimaryButton(
                    context: context,
                    label: "탈퇴 그만두기",
                    filled: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required BuildContext context,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: filled ? Colors.white : AppColors.lgADB5BD,
          backgroundColor: filled ? AppColors.dg1C1F23 : Colors.transparent,
          side: filled
              ? const BorderSide(color: AppColors.dg1C1F23)
              : const BorderSide(color: AppColors.lgE9ECEF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansMedium',
            fontSize: 14,
            color: filled ? Colors.white : AppColors.lgADB5BD,
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    final rootContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "정말 탈퇴하시겠습니까?",
            style: TextStyle(
              fontFamily: 'NotoSansMedium',
              fontSize: 15,
              color: AppColors.dg1C1F23,
            ),
          ),
          content: const Text(
            "계정을 복구할 수 없습니다",
            style: TextStyle(
              fontFamily: 'NotoSansRegular',
              fontSize: 12,
              color: AppColors.lgADB5BD,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "취소",
                style: TextStyle(
                  fontFamily: 'NotoSansRegular',
                  fontSize: 14,
                  color: AppColors.dg495057,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _handleWithdraw(rootContext, context),
              child: const Text(
                "탈퇴",
                style: TextStyle(
                  fontFamily: 'NotoSansMedium',
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }

  Future<void> _handleWithdraw(
      BuildContext rootContext, BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop(); // close dialog
    try {
      final client = FlutterBetterAuth.client;
      await client.signOut();
    } catch (e) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(content: Text('탈퇴 처리 중 오류가 발생했습니다: $e')),
      );
      return;
    }
    if (!rootContext.mounted) return;
    rootContext.go('/onboarding');
  }
}
