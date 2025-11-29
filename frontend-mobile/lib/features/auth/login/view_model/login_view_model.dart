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

  /// 비밀번호 보이기/숨기기 토글
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// 로그인 로직
  /// 성공 시 null 반환, 실패 시 에러 메시지(String) 반환
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final client = FlutterBetterAuth.client;
      final result = await client.signIn.email(
        email: email,
        password: password,
      );

      String? errorMessage;

      // BetterAuth 결과 처리
      (result as dynamic).when(
        ok: (_) {
          errorMessage = null; // 성공
        },
        err: (error) {
          errorMessage = '로그인 실패: ${error.message}';
        },
      );

      return errorMessage;

    } catch (e) {
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