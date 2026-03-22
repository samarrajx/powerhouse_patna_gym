import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../core/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with Red Glow
                  Container(
                    width: 130,
                    height: 130,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.fitness_center, color: AppColors.primary, size: 60),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'POWER HOUSE',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: AppColors.primary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GYM & FITNESS CENTER',
                    style: TextStyle(letterSpacing: 4, color: AppColors.text3(context), fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 54),

                  // Phone Input
                  _buildInputLabel(context, 'PHONE NUMBER'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone_android, size: 20),
                      hintText: 'Enter your 10-digit number',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password Input
                  _buildInputLabel(context, 'PASSWORD'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error Message
                  if (authState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Login Button with Primary Gradient
                  Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGlow.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: authState.isLoading
                          ? null
                          : () => ref.read(authProvider.notifier).login(
                                _phoneController.text.trim(),
                                _passwordController.text,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text(
                              'SIGN IN',
                              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Footer
                  Text(
                    'By signing in you agree to our Terms',
                    style: TextStyle(color: AppColors.text3(context), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PH GYM v1.0.1',
                    style: TextStyle(color: AppColors.text3(context), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: TextStyle(fontSize: 10, color: AppColors.text3(context), fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ),
    );
  }
}
