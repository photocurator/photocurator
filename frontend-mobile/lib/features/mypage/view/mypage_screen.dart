import 'package:flutter/material.dart';
import 'package:photocurator/common/bar/view/app_bar.dart';

class MypageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyPageAppBar(),
      body: Center(child: Text('Mypage Screen')),
    );
  }
}