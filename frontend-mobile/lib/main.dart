import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:provider/provider.dart';
import 'common/navigator/view_model/bottom_navigation_bar_view_model.dart';
import 'package:photocurator/route/routes.dart';
import 'package:photocurator/provider/current_project_provider.dart';

void main() {
  // 앱 실행 전에 상태 표시줄 스타일을 강제로 설정
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.wh1, // 배경색
    statusBarIconBrightness: Brightness.light, // 아이콘을 밝게 (배경이 어두울 경우)
    statusBarBrightness: Brightness.dark,      // iOS 설정
  ));
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CurrentProjectProvider()),
      ChangeNotifierProvider.value(
          value: BottomNavigationViewModel(AppRouter)),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter,
    );
  }
}