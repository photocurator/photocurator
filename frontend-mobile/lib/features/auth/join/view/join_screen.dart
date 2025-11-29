import 'package:flutter/material.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photocurator/common/theme/colors.dart';

enum JoinPageState {
  initial,
  error,
  success,
}

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key, required this.state});

  final JoinPageState state;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _passwordConfirmController;
  bool _isLoading = false;

  late JoinPageState _localState;

  bool get _isSuccess => _localState == JoinPageState.success;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _passwordConfirmController = TextEditingController();
    _localState = widget.state;
  }

  Future<void> _handleJoin() async {
    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = FlutterBetterAuth.client;
      final result = await client.signUp.email(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nicknameController.text,
      );

      if (!mounted) return;

      (result as dynamic).when(
        ok: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입이 완료되었습니다.')),
          );
          context.go('/login');
        },
        err: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원가입 실패: ${error.message}')),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _checkEmail() {
    if (_emailController.text.isNotEmpty) {
      setState(() {
        _localState = JoinPageState.success;
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'NotoSansRegular',
        fontSize: 12, // 폰트 사이즈 살짝 키움 (가독성)
        color: AppColors.lgADB5BD,
      ),
      filled: true,
      fillColor: AppColors.wh1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0), // 수직 패딩 0으로 하고 높이로 제어
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6), // 둥글기 약간 줄임 (시안 반영)
        borderSide: const BorderSide(color: AppColors.lgE9ECEF),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.dg1C1F23), // 포커스 시 검은색 계열
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, {
        required String hint,
        bool obscureText = false,
      }) {
    return SizedBox(
      height: 44, // 높이를 40 -> 44로 살짝 여유 있게 변경 (터치 영역 확보)
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontFamily: 'NotoSansRegular',
          fontSize: 14,
          color: AppColors.dg1C1F23,
        ),
        textAlignVertical: TextAlignVertical.center, // 텍스트 수직 중앙 정렬
        decoration: _inputDecoration(hint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String emailHelper = switch (_localState) {
      JoinPageState.error => '*사용 불가능한 이메일입니다',
      JoinPageState.success => '사용 가능',
      JoinPageState.initial => '*이메일 중복을 확인해주세요',
    };

    final Color emailHelperColor = switch (_localState) {
      JoinPageState.error => AppColors.secondary,
      JoinPageState.success => AppColors.primary,
      JoinPageState.initial => AppColors.dg495057, // 초기 상태는 너무 진하지 않게
    };

    final String passwordHelper = switch (_localState) {
      JoinPageState.error => '*비밀번호와 일치하지 않습니다',
      JoinPageState.success => '확인 완료',
      JoinPageState.initial => '*비밀번호를 입력해 주세요',
    };

    final Color passwordHelperColor = switch (_localState) {
      JoinPageState.error => AppColors.secondary,
      JoinPageState.success => AppColors.primary,
      JoinPageState.initial => AppColors.dg495057,
    };

    final bool isJoinEnabled = _isSuccess;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/button/arrow_left.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.dg1C1F23,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/onboarding');
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24), // 좌우 패딩 20 -> 24
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Photocurator',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Labrada',
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: AppColors.dg1C1F23,
                    ),
                  ),
                  const SizedBox(height: 48), // 타이틀과 입력폼 사이 간격 확보
                  _JoinInputRow(
                    label: '닉네임',
                    input: _buildTextField(
                      _nicknameController,
                      hint: '10자 이내로 입력해 주세요',
                    ),
                  ),
                  const SizedBox(height: 12), // Row 간 간격 추가
                  _JoinInputRow(
                    label: '이메일',
                    input: Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _emailController,
                            hint: '아이디를 입력해 주세요',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CompactButton(
                          label: '중복 확인',
                          onPressed: _checkEmail,
                          isActive: true,
                        ),
                      ],
                    ),
                    helper: _HelperText(
                      text: emailHelper,
                      color: emailHelperColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _JoinInputRow(
                    label: '비밀번호',
                    input: _buildTextField(
                      _passwordController,
                      hint: '비밀번호를 입력해 주세요',
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _JoinInputRow(
                    label: '비밀번호 확인',
                    input: _buildTextField(
                      _passwordConfirmController,
                      hint: '비밀번호를 재입력해 주세요',
                      obscureText: true,
                    ),
                    helper: _HelperText(
                      text: passwordHelper,
                      color: passwordHelperColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isJoinEnabled && !_isLoading ? _handleJoin : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50), // 버튼 높이 50
                    backgroundColor: AppColors.dg1C1F23, // 활성화 색상
                    disabledBackgroundColor: const Color(0xFFADB5BD), // 비활성화 색상 (회색)
                    foregroundColor: AppColors.wh1,
                    textStyle: const TextStyle(
                      fontFamily: 'NotoSansMedium',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0, // 플랫한 디자인을 위해 그림자 제거
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.wh1,
                    ),
                  )
                      : const Text(
                    '회원가입',
                    style: TextStyle(
                      color: AppColors.wh1,
                    ),
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinInputRow extends StatelessWidget {
  const _JoinInputRow({
    required this.label,
    required this.input,
    this.helper,
  });

  final String label;
  final Widget input;
  final Widget? helper;

  @override
  Widget build(BuildContext context) {
    // 라벨 영역의 너비 설정
    const double labelWidth = 90.0;
    const double gap = 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            // 중요: 라벨과 입력창의 수직 중앙 정렬을 맞춤
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'NotoSansMedium', // Medium으로 변경하여 라벨 강조
                    fontSize: 13,
                    color: AppColors.dg1C1F23,
                  ),
                ),
              ),
              const SizedBox(width: gap),
              Expanded(child: input),
            ],
          ),
          // 헬퍼 텍스트 위치 잡기
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(left: labelWidth + gap, top: 6),
              child: helper!,
            ),
        ],
      ),
    );
  }
}

class _HelperText extends StatelessWidget {
  const _HelperText({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'NotoSansRegular',
        fontSize: 11, // 살짝 키움
        color: color,
        height: 1.2,
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  const _CompactButton({
    required this.label,
    required this.onPressed,
    this.isActive = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44, // TextField 높이와 동일하게 맞춤
      width: 74,  // 너비 고정 (너무 넓지 않게)
      child: OutlinedButton(
        onPressed: isActive ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero, // 내부 패딩 제거하여 텍스트 중앙 정렬 용이하게
          side: const BorderSide(color: AppColors.lgADB5BD), // 테두리 색상
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // TextField와 동일한 라운드
          ),
          foregroundColor: AppColors.dg1C1F23,
          textStyle: const TextStyle(
            fontFamily: 'NotoSansMedium', // 글자 좀 더 선명하게
            fontSize: 12,
          ),
        ),
        child: Text(label),
      ),
    );
  }
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