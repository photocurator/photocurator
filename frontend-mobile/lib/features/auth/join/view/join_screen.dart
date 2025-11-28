import 'package:flutter/material.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:go_router/go_router.dart';
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

  // Override state locally to manage UI updates
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
  
  // Dummy check for email duplicate
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
        fontSize: 12,
        color: AppColors.lgADB5BD,
      ),
      filled: true,
      fillColor: AppColors.wh1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lgE9ECEF),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    required String hint,
    bool obscureText = false,
  }) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
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
      JoinPageState.initial => AppColors.dg1C1F23,
    };

    final String passwordHelper = switch (_localState) {
      JoinPageState.error => '*비밀번호와 일치하지 않습니다',
      JoinPageState.success => '확인 완료',
      JoinPageState.initial => '*비밀번호를 입력해 주세요',
    };

    final Color passwordHelperColor = switch (_localState) {
      JoinPageState.error => AppColors.secondary,
      JoinPageState.success => AppColors.primary,
      JoinPageState.initial => AppColors.dg1C1F23,
    };

    final bool isJoinEnabled = _isSuccess;

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.dg1C1F23,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/onboarding');
                  }
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Photocurator',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NotoSansExtraBold',
                      fontSize: 28,
                      color: AppColors.dg1C1F23,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _JoinInputRow(
                    label: '닉네임',
                    input: _buildTextField(
                      _nicknameController,
                      hint: '10자 이내로 입력해 주세요',
                    ),
                  ),
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
                        const SizedBox(width: 12),
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
                    labelColor:
                        _isSuccess ? AppColors.dg495057 : AppColors.dg1C1F23,
                  ),
                  _JoinInputRow(
                    label: '비밀번호',
                    input: _buildTextField(
                      _passwordController,
                      hint: '비밀번호를 입력해 주세요',
                      obscureText: true,
                    ),
                  ),
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isJoinEnabled && !_isLoading
                      ? _handleJoin
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor:
                        isJoinEnabled ? AppColors.dg1C1F23 : AppColors.lgADB5BD,
                    disabledBackgroundColor: AppColors.lgADB5BD,
                    foregroundColor: AppColors.wh1,
                    disabledForegroundColor:
                        AppColors.wh1.withValues(alpha: 0.8),
                    textStyle: const TextStyle(
                      fontFamily: 'NotoSansMedium',
                      fontSize: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.wh1,
                          )
                        )
                      : const Text('회원가입'),
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
    this.labelColor = AppColors.dg1C1F23,
  });

  final String label;
  final Widget input;
  final Widget? helper;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'NotoSansRegular',
                    fontSize: 12,
                    color: labelColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: input),
            ],
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(left: 92, top: 6),
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
        fontSize: 10,
        color: color,
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
      height: 40,
      width: 80,
      child: OutlinedButton(
        onPressed: isActive ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.lgADB5BD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: AppColors.dg1C1F23,
          textStyle: const TextStyle(
            fontFamily: 'NotoSansRegular',
            fontSize: 11,
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
