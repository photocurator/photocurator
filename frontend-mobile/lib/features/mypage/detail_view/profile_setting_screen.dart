import 'package:flutter/material.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/widgets/next_row_item.dart';
import 'package:photocurator/common/widgets/info_row_item.dart';
import 'package:photocurator/features/mypage/detail_view/withdraw_screen.dart';
import 'package:photocurator/features/mypage/service/user_service.dart';

class ProfileSettingScreen extends StatefulWidget {
  @override
  State<ProfileSettingScreen> createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {
  late Future<UserStatistics> _statsFuture;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _statsFuture = _userService.fetchMyStatistics();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final double itemHeight = deviceWidth * (50 / 375);

    return Scaffold(
      backgroundColor: AppColors.wh1,
      appBar: DetailAppBar(title: "프로필 설정", rightWidget: null),
      body: FutureBuilder<UserStatistics>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final nickname = snapshot.data?.nickname ?? "닉네임";
          final userId = snapshot.data?.email ?? "email@example.com";
          final createdAt = snapshot.data?.createdAt;
          final createdAtText = createdAt != null
              ? "${createdAt.year.toString().padLeft(4, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')}"
              : "-";

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Container(height: 10, color: AppColors.lgE9ECEF),
              Container(
                height: itemHeight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  "기본 정보",
                  style: TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: itemHeight * (16 / 50),
                    color: AppColors.dg1C1F23,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              InfoRowItem(titleText: "닉네임", infoText: nickname),
              InfoRowItem(titleText: "아이디", infoText: userId),
              InfoRowItem(titleText: "가입일자", infoText: createdAtText),
              const SizedBox(height: 20),
              Container(height: 10, color: AppColors.lgE9ECEF),
              Container(
                height: itemHeight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  "계정 관리",
                  style: TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: itemHeight * (16 / 50),
                    color: AppColors.dg1C1F23,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _signOut(context),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "로그아웃",
                      style: TextStyle(
                        fontFamily: 'NotoSansMedium',
                        fontSize: 14,
                        color: AppColors.dg1C1F23,
                        letterSpacing: 0,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
              NextRowItem(
                titleText: '회원 탈퇴',
                baseFontSize: 14,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WithdrawScreen()),
                  );
                },
              ),
              Expanded(child: Container()),
            ],
          );
        },
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final client = FlutterBetterAuth.client;
      await client.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃에 실패했습니다: $e')),
      );
      return;
    }
    if (!context.mounted) return;
    context.go('/onboarding');
  }
}
