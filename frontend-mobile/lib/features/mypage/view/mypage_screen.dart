import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photocurator/common/bar/view/app_bar.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/widgets/back_icon.dart';
import 'package:photocurator/common/widgets/next_row_item.dart';
import 'package:photocurator/features/mypage/detail_view/alarm_screen.dart';
import 'package:photocurator/features/mypage/detail_view/profile_setting_screen.dart';
import 'package:photocurator/features/mypage/service/user_service.dart';

class MypageScreen extends StatefulWidget {
  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  late Future<UserStatistics> _statsFuture;
  final UserService _userService = UserService();
  bool _calculateTriggered = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _userService.fetchMyStatistics();
    _triggerCalculateOnce();
  }

  Future<void> _triggerCalculateOnce() async {
    if (_calculateTriggered) return;
    _calculateTriggered = true;
    try {
      await _userService.calculateStatistics();
    } catch (e) {
      debugPrint('Failed to calculate statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final double itemHeight = deviceWidth * (50 / 375);

    return Scaffold(
      backgroundColor: AppColors.wh1,
      appBar: MyPageAppBar(),
      body: FutureBuilder<UserStatistics>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final nickname = snapshot.data?.nickname ?? '';
          final userId = snapshot.data?.email ?? '';

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProfileSettingScreen()),
                  );
                },
                child: Container(
                  height: itemHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/icons/button/user_setting.svg',
                        width: itemHeight * (32 / 50),
                        height: itemHeight * (32 / 50),
                        colorFilter: const ColorFilter.mode(
                            AppColors.lgADB5BD, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nickname.isEmpty ? ' ' : nickname,
                            style: TextStyle(
                              fontFamily: 'NotoSansMedium',
                              fontSize: itemHeight * (14 / 50),
                              color: AppColors.dg1C1F23,
                              letterSpacing: 0,
                            ),
                          ),
                          Text(
                            userId.isEmpty ? ' ' : userId,
                            style: TextStyle(
                              fontFamily: 'NotoSansMedium',
                              fontSize: itemHeight * (10 / 50),
                              color: AppColors.lgADB5BD,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ChevronIcon(barHeight: itemHeight),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 10, color: AppColors.lgE9ECEF),
              Container(
                height: itemHeight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  "알림",
                  style: TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: itemHeight * (12 / 50),
                    color: AppColors.lgADB5BD,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              NextRowItem(
                titleText: '알림 확인',
                textColor: AppColors.secondary,
                baseFontSize: 14,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AlarmScreen()),
                  );
                },
              ),
              Expanded(
                child: Container(),
              ),
            ],
          );
        },
      ),
    );
  }
}
