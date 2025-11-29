import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/features/auth/join/view_model/join_view_model.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key, required this.state});

  final JoinPageState state;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  // 컨트롤러는 View의 생명주기와 관련되므로 여기서 관리합니다.
  late final TextEditingController _nicknameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _passwordConfirmController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _passwordConfirmController = TextEditingController();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  // 버튼 클릭 핸들러: ViewModel 호출 후 UI 피드백(SnackBar, Navigation) 처리
  Future<void> _onJoinPressed(JoinViewModel viewModel) async {
    // 키보드 내리기
    FocusScope.of(context).unfocus();

    final error = await viewModel.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      passwordConfirm: _passwordConfirmController.text,
      nickname: _nicknameController.text,
    );

    if (!mounted) return;

    if (error == null) {
      // 성공
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다.')),
      );
      context.go('/login');
    } else {
      // 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider로 ViewModel 주입 (상위에서 주입하지 않았을 경우를 대비해 여기서 생성)
    return ChangeNotifierProvider(
      create: (_) => JoinViewModel(initialState: widget.state),
      child: Consumer<JoinViewModel>(
        builder: (context, viewModel, child) {
          // 헬퍼 텍스트 로직
          final String emailHelper = switch (viewModel.joinState) {
            JoinPageState.error => '*사용 불가능한 이메일입니다',
            JoinPageState.success => '사용 가능',
            JoinPageState.initial => '*이메일 중복을 확인해주세요',
          };

          final Color emailHelperColor = switch (viewModel.joinState) {
            JoinPageState.error => AppColors.secondary,
            JoinPageState.success => AppColors.primary,
            JoinPageState.initial => AppColors.dg495057,
          };

          final String passwordHelper = switch (viewModel.joinState) {
            JoinPageState.error => '*비밀번호와 일치하지 않습니다',
            JoinPageState.success => '확인 완료',
            JoinPageState.initial => '*비밀번호를 입력해 주세요',
          };

          final Color passwordHelperColor = switch (viewModel.joinState) {
            JoinPageState.error => AppColors.secondary,
            JoinPageState.success => AppColors.primary,
            JoinPageState.initial => AppColors.dg495057,
          };

          final bool isJoinEnabled = viewModel.isSuccess;

          return Scaffold(
            backgroundColor: AppColors.wh1,
            body: SafeArea(
              child: Column(
                children: [
                  // --- Header ---
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

                  // --- Form Fields ---
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        const SizedBox(height: 48),

                        // 닉네임
                        _JoinInputRow(
                          label: '닉네임',
                          input: _buildTextField(
                            _nicknameController,
                            hint: '10자 이내로 입력해 주세요',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 이메일
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
                                onPressed: () => viewModel.checkEmail(_emailController.text),
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

                        // 비밀번호
                        _JoinInputRow(
                          label: '비밀번호',
                          input: _buildTextField(
                            _passwordController,
                            hint: '비밀번호를 입력해 주세요',
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 비밀번호 확인
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

                  // --- Bottom Button ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // 로딩 중이 아니고, 가입 가능 상태일 때만 버튼 활성화
                        onPressed: (isJoinEnabled && !viewModel.isLoading)
                            ? () => _onJoinPressed(viewModel)
                            : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: AppColors.dg1C1F23,
                          disabledBackgroundColor: const Color(0xFFADB5BD),
                          foregroundColor: AppColors.wh1,
                          textStyle: const TextStyle(
                            fontFamily: 'NotoSansMedium',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: viewModel.isLoading
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
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI Components (동일하게 유지) ---

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.lgE9ECEF),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.dg1C1F23),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, {
        required String hint,
        bool obscureText = false,
      }) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontFamily: 'NotoSansRegular',
          fontSize: 14,
          color: AppColors.dg1C1F23,
        ),
        textAlignVertical: TextAlignVertical.center,
        decoration: _inputDecoration(hint),
      ),
    );
  }
}

// 아래 컴포넌트 클래스들은 변경사항 없이 그대로 사용합니다.
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
    const double labelWidth = 90.0;
    const double gap = 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'NotoSansMedium',
                    fontSize: 13,
                    color: AppColors.dg1C1F23,
                  ),
                ),
              ),
              const SizedBox(width: gap),
              Expanded(child: input),
            ],
          ),
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
  const _HelperText({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'NotoSansRegular',
        fontSize: 11,
        color: color,
        height: 1.2,
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  const _CompactButton({required this.label, required this.onPressed, this.isActive = true});
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: 74,
      child: OutlinedButton(
        onPressed: isActive ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.lgADB5BD),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          foregroundColor: AppColors.dg1C1F23,
          textStyle: const TextStyle(
            fontFamily: 'NotoSansMedium',
            fontSize: 12,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}