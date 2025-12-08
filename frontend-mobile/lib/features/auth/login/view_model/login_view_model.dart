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

      // 실제 세션/유저가 존재하는지 한 번 더 확인 (엣지 케이스 방지)
      final sessionRes = await FlutterBetterAuth.client.getSession();
      final session = sessionRes.data?.session;
      final user = sessionRes.data?.user;
      final hasValidSession = session != null &&
          session.token.isNotEmpty &&
          session.expiresAt.isAfter(DateTime.now()) &&
          user != null;
      if (hasValidSession) {
        return null;
      }
      // 세션이 없으면 강제로 실패 처리
      await FlutterBetterAuth.client.signOut();
      return '로그인 실패';

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
