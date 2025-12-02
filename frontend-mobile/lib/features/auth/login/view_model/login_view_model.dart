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

  /// 로그인 요청
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      // [수정] .when() 제거
      // 이 함수는 성공하면 User/Session 객체를 반환하고,
      // 실패하면(비밀번호 틀림, 404, 500 등) Exception을 던집니다.
      await FlutterBetterAuth.client.signIn.email(
        email: email,
        password: password,
      );

      // 에러가 발생하지 않고 여기까지 코드가 도달했다면 '성공'입니다.
      return null;

    } catch (e) {
      // 실패 시 여기서 잡힙니다.
      // e.toString() 대신 더 구체적인 에러 처리를 할 수도 있습니다.
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
