import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/widgets/info_row_item.dart';
import 'package:provider/provider.dart';

import '../../../provider/current_project_provider.dart';

//추후 데이터 교체 요망
//프로젝트 설정 화면
class PjSettingScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final double itemHeight = deviceWidth * (50 / 375);

    final currentProjectProvider = context.watch<CurrentProjectProvider>();
    final String pjname = currentProjectProvider.currentProject?.projectName ?? "project name";

    final String createdAt = currentProjectProvider.currentProject?.createdAt?.toString() ?? "-"; // 추후 데이터 교체


    return Scaffold(
      backgroundColor: AppColors.wh1,

      appBar: DetailAppBar(
        title: "프로젝트 설정",
        rightWidget: null
        /*
        GestureDetector(
          onTap: () {
            print("우측 버튼 클릭");
          },
          child: Text(
            "삭제",
            style: TextStyle(
                fontSize: deviceWidth * (50 / 375) * (14 / 50),
                color: AppColors.lgADB5BD
            ),
          ),
        ),
        */
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.start, // start, center, end, spaceBetween, spaceAround, spaceEvenly 중 선택
          crossAxisAlignment: CrossAxisAlignment.center, // start, center, end, stretch, baseline 중 선택
          mainAxisSize: MainAxisSize.max, // max (최대), min (자식 크기에 맞게 최소) 중 선택
          // 내용
          children: <Widget>[
            // 1. 회색 구분 영역
            Container(height: 10, color: AppColors.lgE9ECEF),
            // 2. 콘텐츠 부제목 - 기본 정보
            Container(
              height: itemHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0), // 좌우 패딩 20
                child: Align(
                  alignment: Alignment.centerLeft, // 왼쪽 정렬 및 세로 중앙 정렬
                  child: Text(
                    "기본 정보",
                    style: TextStyle(
                      fontFamily: 'NotoSansMedium', //fontFamily: 'NotoSansRegular',
                      fontSize:  itemHeight * (16 / 50),
                      color: AppColors.dg1C1F23,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),
            // 3. 프로젝트 이름
            //임시 구현
            InfoRowItem(titleText: "프로젝트 이름", infoText: pjname),
            // 4. 생성 일자
            InfoRowItem(titleText: "생성 일자", infoText: createdAt),
            // 5. 간격
            const SizedBox(height: 20),
            /*
            // 6. 회색 구분 영역
            Container(height: 10, color: AppColors.lgE9ECEF),
            // 7. 콘텐츠 부제목 - 태그 관리
            Container(
              height: itemHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0), // 좌우 패딩 20
                child: Align(
                  alignment: Alignment.centerLeft, // 왼쪽 정렬 및 세로 중앙 정렬
                  child: Text(
                    "태그 관리",
                    style: TextStyle(
                      fontFamily: 'NotoSansMedium', //fontFamily: 'NotoSansRegular',
                      fontSize:  itemHeight * (16 / 50),
                      color: AppColors.dg1C1F23,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),
             */
            // 남은 공간 채우기
            Expanded(
              child: Container(), //정렬 고정용
            ),
          ],
      ),
    );
  }
}