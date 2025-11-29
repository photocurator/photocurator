import 'package:flutter/material.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';

enum JoinPageState {
  initial,
  error,
  success,
}

JoinPageState joinPageStateFromParam(String? value) {
  switch (value) {
    case 'error':
      return JoinPageState.error;
    case 'success':
      return JoinPageState.success;
    default:
      return JoinPageState.initial;
  }
}

class JoinViewModel extends ChangeNotifier {
  JoinViewModel({JoinPageState? initialState})
      : _joinState = initialState ?? JoinPageState.initial;

  // --- State ---
  bool _isLoading = false;
  JoinPageState _joinState;

  // --- Getters ---
  bool get isLoading => _isLoading;
  JoinPageState get joinState => _joinState;
  bool get isSuccess => _joinState == JoinPageState.success;

  // --- Actions ---

  void checkEmail(String email) {
    if (email.isNotEmpty) {
      _joinState = JoinPageState.success;
      notifyListeners();
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String passwordConfirm,
    required String nickname,
  }) async {
    if (password != passwordConfirm) {
      return '비밀번호가 일치하지 않습니다.';
    }

    _setLoading(true);

    try {
      final client = FlutterBetterAuth.client;

      // [수정] .when() 제거 및 try-catch 처리
      await client.signUp.email(
        email: email,
        password: password,
        name: nickname,
      );

      // 에러 없이 여기까지 오면 성공
      return null;

    } catch (e) {
      // 에러 발생 시
      return '회원가입 실패: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}