import 'package:flutter/material.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';

class LoginViewModel extends ChangeNotifier {
  // --- State ---
  bool _isLoading = false;
  bool _obscurePassword = true;

  // --- Getters ---
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;

  // --- Actions ---

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// 로그인 로직
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final client = FlutterBetterAuth.client;

      // [수정] .when() 제거
      // 이 함수는 성공하면 User 객체를 반환하고, 실패하면 Exception을 던집니다.
      await client.signIn.email(
        email: email,
        password: password,
      );

      // 여기까지 코드가 도달했다면 '성공'입니다.
      return null;

    } catch (e) {
      // 실패 시 여기서 잡힙니다.
      return '로그인 실패: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}