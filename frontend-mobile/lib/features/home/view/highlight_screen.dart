import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';

class HighlightScreen extends StatelessWidget {
  const HighlightScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: const Center(
        child: Text("내용 영역"),
      ),
    );
  }
}