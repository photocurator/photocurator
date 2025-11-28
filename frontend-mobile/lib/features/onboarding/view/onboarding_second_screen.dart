import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:photocurator/common/theme/colors.dart';

class OnboardingSecondScreen extends StatelessWidget {
  const OnboardingSecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            const _LogoBadge(),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '1분',
                      style: const TextStyle(
                        fontFamily: 'NotoSansMedium',
                        fontSize: 24,
                        color: AppColors.primary,
                      ),
                      children: const [
                        TextSpan(
                          text: ' 이면 회원가입이 가능해요!',
                          style: TextStyle(
                            fontFamily: 'NotoSansMedium',
                            fontSize: 24,
                            color: AppColors.dg1C1F23,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '서비스 이용을 위해 계정을 생성해주세요.',
                    style: TextStyle(
                      fontFamily: 'NotoSansRegular',
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/join'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        textStyle: const TextStyle(
                          fontFamily: 'NotoSansMedium',
                          fontSize: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('회원가입하기'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(
                          color: AppColors.lgE9ECEF,
                          height: 1,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '또는',
                          style: TextStyle(
                            fontFamily: 'NotoSansRegular',
                            fontSize: 12,
                            color: AppColors.lgADB5BD,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.lgE9ECEF,
                          height: 1,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.wh1,
                        textStyle: const TextStyle(
                          fontFamily: 'NotoSansMedium',
                          fontSize: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('로그인하기'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.wh1,
            boxShadow: [
              BoxShadow(
                color: Color(0x66BE9BAD),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.wh1,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/button/logo.svg',
                width: 36,
                height: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
