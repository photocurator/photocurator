import 'package:flutter/material.dart';

class AppColors {
  // 브랜드 컬러
  static const Color primary = Color(0xFFE963A8);
  static const Color secondary = Color(0xFF3A7EE6);

  // 그라디언트
  static const Gradient mainGradient = LinearGradient(
    colors: [
      Color(0xFFFB52B2),
      Color(0xFF6C8BFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 텍스트 컬러
  static const Color dg1C1F23 = Color(0xFF1C1F23);
  static const Color dg495057 = Color(0xFF495057);
  static const Color lgADB5BD = Color(0xFFADB5BD);
  static const Color lgCBD1D6 = Color(0xFFCBD1D6);
  static const Color lgE9ECEF = Color(0xFFE9ECEF);

  // 배경
  static const Color wh1 = Color(0xFFF8F9FA);

  // 바텀바 테두리
  static const Color bottomBorder = Color(0xFFF1E8F1);
}
