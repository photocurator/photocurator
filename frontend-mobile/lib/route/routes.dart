import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photocurator/common/navigator/view/bottom_navigation_bar.dart';
import 'package:photocurator/features/auth/join/view/join_screen.dart';
import 'package:photocurator/features/auth/login/view/login_screen.dart';
import 'package:photocurator/features/start/view/start_screen.dart';
import 'package:photocurator/features/mypage/view/mypage_screen.dart';
import 'package:photocurator/features/onboarding/view/onboarding_second_screen.dart';
import 'package:photocurator/features/search/view/search_screen.dart';
import 'package:photocurator/features/start/view/photo_selection_screen.dart';
import 'package:photocurator/features/auth/join/view_model/join_view_model.dart';


final AppRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/project/add-photos',
      pageBuilder: (context, state) {
        final projectName = state.extra as String; // Extract the project name
        return MaterialPage(
          key: state.pageKey,
          child: PhotoSelectionScreen(projectName: projectName),
        );
      },
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const OnboardingSecondScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/join',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: JoinScreen(
          state: joinPageStateFromParam(state.uri.queryParameters['state']),
        ),
      ),
    ),
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
              path: '/start',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: StartScreen(),
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
