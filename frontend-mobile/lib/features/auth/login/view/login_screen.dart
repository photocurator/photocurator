import 'package:flutter/material.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:photocurator/common/theme/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final client = FlutterBetterAuth.client;
      final result = await client.signIn.email(
        email: _idController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      (result as dynamic).when(
        ok: (_) {
          context.go('/start');
        },
        err: (error) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('로그인 실패: ${error.message}')),
           );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.dg1C1F23,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _LogoMark(darkMode: true),
                    const SizedBox(height: 12),
                    const Text(
                      'Photocurator',
                      style: TextStyle(
                        fontFamily: 'NotoSansExtraBold',
                        fontSize: 28,
                        color: AppColors.dg1C1F23,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _idController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('아이디'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: _inputDecoration('비밀번호').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.lgADB5BD,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
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
                        child: _isLoading 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, 
                                  color: AppColors.wh1
                                ),
                              )
                            : const Text('로그인'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    final Widget logo = SvgPicture.asset(
      'assets/icons/navigator/logo.svg',
      width: 60,
      height: 60,
      colorFilter: darkMode
          ? const ColorFilter.mode(AppColors.dg1C1F23, BlendMode.srcIn)
          : null,
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
