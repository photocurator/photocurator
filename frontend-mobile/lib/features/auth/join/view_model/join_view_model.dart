import 'package:flutter/material.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';

// 상태 Enum
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
  // 생성자: 초기 상태 주입 가능
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

  /// 이메일 중복 확인 (더미 로직 유지)
  void checkEmail(String email) {
    if (email.isNotEmpty) {
      _joinState = JoinPageState.success;
      notifyListeners();
    }
  }

  /// 회원가입 로직
  /// 성공 시 null 반환, 실패 시 에러 메시지 String 반환
  Future<String?> signUp({
    required String email,
    required String password,
    required String passwordConfirm,
    required String nickname,
  }) async {
    // 1. 비밀번호 일치 확인
    if (password != passwordConfirm) {
      return '비밀번호가 일치하지 않습니다.';
    }

    _setLoading(true);

    try {
      final client = FlutterBetterAuth.client;
      final result = await client.signUp.email(
        email: email,
        password: password,
        name: nickname,
      );

      String? errorMessage;

      // BetterAuth 결과 처리
      (result as dynamic).when(
        ok: (_) {
          errorMessage = null; // 성공
        },
        err: (error) {
          errorMessage = '회원가입 실패: ${error.message}';
        },
      );

      return errorMessage;

    } catch (e) {
      return '회원가입 실패: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 내부 로딩 상태 변경 함수
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}