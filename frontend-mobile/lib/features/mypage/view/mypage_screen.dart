import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/app_bar.dart';
import 'package:photocurator/common/widgets/next_row_item.dart';
import 'package:photocurator/features/mypage/detail_view/profile_setting_screen.dart';
import 'package:photocurator/features/mypage/detail_view/alarm_screen.dart';
import 'package:photocurator/common/widgets/back_icon.dart';
import 'package:flutter_svg/flutter_svg.dart';

//추후 데이터 교체 요망
class MypageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final double itemHeight = deviceWidth * (50 / 375);

    final String nickname = "닉네임"; // 추후 데이터 교체
    final String userId = "id:lkjlk@gmail.com"; // 추후 데이터 교체

    return Scaffold(
      backgroundColor: AppColors.wh1,

      appBar: MyPageAppBar(),
      body: Column(
        // 메인 축(수직) 정렬: 세로 방향으로 자식들을 어떻게 배치할지 결정합니다.
        mainAxisAlignment: MainAxisAlignment.start, // start, center, end, spaceBetween, spaceAround, spaceEvenly 중 선택

        // 교차 축(수평) 정렬: 가로 방향으로 자식들을 어떻게 배치하거나 늘릴지 결정합니다.
        crossAxisAlignment: CrossAxisAlignment.center, // start, center, end, stretch, baseline 중 선택

        // **크기 (필수적으로 고려)**
        // 메인 축(수직) 크기: Column이 세로 방향으로 얼마나 공간을 차지할지 결정합니다.
        mainAxisSize: MainAxisSize.max, // max (최대), min (자식 크기에 맞게 최소) 중 선택

        // 내용
        children: <Widget>[
          // 1. 간격
          const SizedBox(height: 20),
          // 2. 아이템 - 프로필 설정
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileSettingScreen()),
              );
            },
            child: Container(
              height: itemHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0), // 좌우 패딩
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/icons/button/user_setting.svg',
                        width: itemHeight * (32 / 50),
                        height: itemHeight * (32 / 50),
                        colorFilter: ColorFilter.mode(
                            AppColors.lgADB5BD, BlendMode.srcIn),
                      ),
                      SizedBox(width: 12),
                      // 닉네임 + 이메일
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nickname,
                            style: TextStyle(
                              fontFamily: 'NotoSansMedium',
                              fontSize: itemHeight * (14 / 50),
                              color: AppColors.dg1C1F23,
                              letterSpacing: 0,
                            ),
                          ),
                          Text(
                            userId,
                            style: TextStyle(
                              fontFamily: 'NotoSansMedium',
                              fontSize: itemHeight * (10 / 50),
                              color: AppColors.lgADB5BD,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      ChevronIcon(barHeight: itemHeight),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 3. 간격
          const SizedBox(height: 20),
          // 4. 회색 구분 영역
          Container(height: 10, color: AppColors.lgE9ECEF),
          // 5. 콘텐츠 부제목 - 알림
          Container(
            height: itemHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), // 좌우 패딩 20
              child: Align(
                alignment: Alignment.centerLeft, // 왼쪽 정렬 및 세로 중앙 정렬
                child: Text(
                  "알림",
                  style: TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize:  itemHeight * (12 / 50),
                    color: AppColors.lgADB5BD,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
          // 6. NextRowItem - 알림 확인
          NextRowItem(
            titleText: '알림 확인',
            textColor: AppColors.secondary,
            baseFontSize: 14, //NextRowItem build 시 반응형으로 사이즈 조정됨
            onTap: () {
              // 알림 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlarmScreen()),
              );
            },
          ),

          // 후순위: [일반 설정 - 화면 디자인 (라이트 모드 / 다크 모드)]

          // 남은 공간 채우기
          Expanded(
            child: Container(), //정렬 고정용
          ),
        ],
      ),
    );
  }
}