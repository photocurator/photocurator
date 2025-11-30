import 'package:flutter/material.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideInitialRoute();
  }

  Future<void> _decideInitialRoute() async {
    // 스플래시 화면을 잠깐 보여주기 위해 딜레이를 줄 수도 있음 (선택사항)
    // await Future.delayed(const Duration(seconds: 1));

    try {
      final client = FlutterBetterAuth.client;

      // [수정] .when() 제거
      // getSession()은 성공하면 데이터를 반환하고, 실패하면(세션 없음 등) 에러를 던집니다.
      final data = await client.getSession();

      // 여기까지 오면 세션 정보가 있다는 뜻이므로 유효성 검사
      final hasValidSession = data.data!.session.token.isNotEmpty &&
          data.data!.session.expiresAt.isAfter(DateTime.now());

      if (!mounted) return;

      if (hasValidSession) {
        context.go('/start');
      } else {
        context.go('/onboarding');
      }
    } catch (_) {
      // [수정] 에러(세션 없음, 네트워크 오류 등)가 나면 온보딩으로 이동
      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}