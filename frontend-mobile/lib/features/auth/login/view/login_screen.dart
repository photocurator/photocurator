import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Provider import 필수
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/features/auth/login/view_model/login_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 컨트롤러는 View의 생명주기에 종속되므로 여기서 관리합니다.
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoginEnabled = false;

  @override
  void initState() {
    super.initState();
    _idController.addListener(_updateLoginEnabled);
    _passwordController.addListener(_updateLoginEnabled);
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateLoginEnabled() {
    final canLogin = _idController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
    if (canLogin != _isLoginEnabled) {
      setState(() {
        _isLoginEnabled = canLogin;
      });
    }
  }

  // 로그인 버튼 클릭 시 실행
  Future<void> _handleLogin(LoginViewModel viewModel) async {
    FocusScope.of(context).unfocus();

    // ViewModel의 비동기 함수 호출
    final error = await viewModel.login(
      email: _idController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (error == null) {
      // 성공 시 페이지 이동
      context.go('/start');
    } else {
      // 실패 시 스낵바 노출
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lgADB5BD),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lgADB5BD),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.dg1C1F23, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. ChangeNotifierProvider로 ViewModel 주입
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Scaffold(
        backgroundColor: AppColors.wh1,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 뒤로가기 버튼 영역
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
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

              // 2. Consumer를 통해 ViewModel 상태 구독
              Expanded(
                child: Consumer<LoginViewModel>(
                  builder: (context, viewModel, child) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        children: [
                          const SizedBox(height: 91),
                          const _LogoMark(darkMode: true),
                          const SizedBox(height: 12),
                          const Text(
                            'Photocurator',
                            style: TextStyle(
                              fontFamily: 'Labrada',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dg1C1F23,
                            ),
                          ),
                          const SizedBox(height: 112),

                          // 아이디 입력
                          TextField(
                            controller: _idController,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration('아이디'),
                          ),
                          const SizedBox(height: 16),

                          // 비밀번호 입력
                          TextField(
                            controller: _passwordController,
                            obscureText: viewModel.obscurePassword, // ViewModel 상태 사용
                            textInputAction: TextInputAction.done,
                            decoration: _inputDecoration('비밀번호').copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  viewModel.obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.lgADB5BD,
                                ),
                                // ViewModel 액션 호출
                                onPressed: viewModel.togglePasswordVisibility,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 로그인 버튼
                          SizedBox(
                            width: double.infinity,
                              child: ElevatedButton(
                                // 로딩 중이면 버튼 비활성화
                                onPressed: viewModel.isLoading || !_isLoginEnabled
                                    ? null
                                    : () => _handleLogin(viewModel),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: AppColors.dg1C1F23,
                                foregroundColor: AppColors.wh1,
                                textStyle: const TextStyle(
                                  fontFamily: 'NotoSansMedium',
                                  fontSize: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
                                  : const Text('로그인'),
                            ),
                          ),
                          const SizedBox(height: 216),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({this.darkMode = false});

  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    final Widget logo = Image.asset(
      'assets/icons/navigator/logo_black.png',
      width: 60,
      height: 60,
    );

    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.wh1,
        ),
        child: Center(child: logo),
      ),
    );
  }
}
