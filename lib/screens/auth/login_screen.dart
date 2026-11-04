import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AuthProvider authProvider = context.read<AuthProvider>();

    final bool success = await authProvider.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      final String error =
          authProvider.errorMessage ?? 'Login failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppConstants.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. Top App Logo / Icon Badge
                  Center(
                    child: Container(
                      width: 72.0,
                      height: 72.0,
                      decoration: BoxDecoration(
                        color: AppConstants.lightBlueSurface,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: AppConstants.primaryBlue,
                        size: 40.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // 2. Welcome Heading & Subtitle
                  const Center(
                    child: Text(
                      'Campus Incident Reporter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const Center(
                    child: Text(
                      'Sign in to report campus issues and track resolutions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // 3. Email Input Field
                  CustomTextField(
                    label: 'Email Address',
                    hintText: 'Enter your student or staff email',
                    controller: _emailController,
                    validator: Validators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 18.0),

                  // 4. Password Input Field
                  CustomTextField(
                    label: 'Password',
                    hintText: 'Enter your password',
                    controller: _passwordController,
                    validator: Validators.validatePassword,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppConstants.textSecondary,
                        size: 20.0,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 28.0),

                  // 5. Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 52.0,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryBlue,
                        foregroundColor: AppConstants.cardWhite,
                        disabledBackgroundColor:
                            AppConstants.primaryBlue.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22.0,
                              height: 22.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppConstants.cardWhite,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // 6. Quick Demo Hint Box (Helpful for Testing & Video Demo)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: AppConstants.cardWhite,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppConstants.borderColor),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16.0,
                              color: AppConstants.primaryBlue,
                            ),
                            SizedBox(width: 6.0),
                            Text(
                              'Role-Based Access Info',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.textDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          '• Students: Sign up with your campus email.\n• Authorized Staff: Sign up/in using pre-approved @alueducation.com emails (e.g., facilities@alueducation.com).',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: AppConstants.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // 7. Navigate to Register Screen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14.0,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            color: AppConstants.primaryBlue,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}