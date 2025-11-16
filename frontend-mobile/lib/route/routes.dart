import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photocurator/features/home/view/home_screen.dart';
import 'package:photocurator/features/search/view/search_screen.dart';
import 'package:photocurator/features/mypage/view/mypage_screen.dart';
import 'package:photocurator/common/navigator/view/bottom_navigation_bar.dart';

final AppRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNestedNavigation(
          navigationShell: navigationShell, // 명시적 캐스팅
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: SearchScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: HomeScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mypage',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: MypageScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);