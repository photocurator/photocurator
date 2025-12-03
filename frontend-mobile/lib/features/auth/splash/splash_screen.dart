import 'package:flutter/material.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:photocurator/common/theme/colors.dart';

Route _fadeRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        _fadeRoute(NextScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        width: deviceWidth,
        height: deviceHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFd5cae9), // 왼쪽 상단 연보라
              Color(0xFFa2c2ff), // 중간 푸른빛
              Color(0xFF8bb6ff), // 하단 블루
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -20),
              child: Stack(
                children: [
                  // 그림자(안쪽 그림자처럼 보이게 만들기)
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: SvgPicture.asset(
                      "assets/icons/button/logo_one_color.svg",
                      width: 64,
                      height: 64,
                      colorFilter: ColorFilter.mode(Color(0xFF8A8EBA), BlendMode.srcIn),
                    ),
                  ),

                  SvgPicture.asset(
                    "assets/icons/button/logo_one_color.svg",
                    width: 64,
                    height: 64,
                    colorFilter: ColorFilter.mode(AppColors.wh1, BlendMode.srcIn),
                  ),
                ],
              )
            )
          ],
        ),
      ),
    );
  }
}

class NextScreen extends StatefulWidget {
  @override
  _NextScreenState createState() => _NextScreenState();
}

class _NextScreenState extends State<NextScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        _fadeRoute(LastScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        width: deviceWidth,
        height: deviceHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB7BBEE), // 왼쪽 상단 연보라
              Color(0xFF5B9AE7), // 중간 푸른빛
              Color(0xFF508EE8), // 하단 블루
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -20),
              child: Stack(
                children: [
                  // 그림자(안쪽 그림자처럼 보이게 만들기)
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      "Photocurator",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Labrada',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8A8EBA), // 그림자 색
                        height: 1.3,
                      ),
                    ),
                  ),

                  // 원본 텍스트
                  Text(
                    "Photocurator",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Labrada',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.wh1,
                      height: 1.3,
                    ),
                  ),
                ],
              )
            )
          ],
        ),
      ),
    );
  }
}

class LastScreen extends StatefulWidget {
  @override
  _LastScreenState createState() => _LastScreenState();
}

class _LastScreenState extends State<LastScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {});
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
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        width: deviceWidth,
        height: deviceHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3A7EE6), // 왼쪽 상단 연보라
              Color(0xFF3A7EE6), // 중간 푸른빛
              Color(0xFF3A7EE6), // 하단 블루
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -20),
              child: Text(
                "포토큐레이터에 \n오신 것을 환영합니다",
                textAlign: TextAlign.center, // ← 중앙 정렬
                style: TextStyle(
                  fontFamily: 'NotoSansMedium',
                  // 노토산스미디움
                  fontSize: 26,
                  // 폰트 크기
                  color: AppColors.wh1,
                  letterSpacing: 0,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
