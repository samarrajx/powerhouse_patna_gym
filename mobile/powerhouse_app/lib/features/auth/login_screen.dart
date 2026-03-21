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
    final bg = AppColors.background(context);
    final surfHigh = AppColors.surfaceHigh(context);
    final onSurf = AppColors.onSurface(context);
    final sec = AppColors.secondary(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: surfHigh,
                      borderRadius: BorderRadius.circular(45),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 44),
                  ),
                  const SizedBox(height: 28),
                  Text('POWER HOUSE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: AppColors.primary, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text('GYM & FITNESS', style: TextStyle(letterSpacing: 4, color: sec, fontSize: 11)),
                  const SizedBox(height: 48),

                  // Phone
                  _buildLabel('PHONE NUMBER', sec),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: onSurf),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.phone_android, color: AppColors.primary, size: 20),
                      hintText: 'Enter your phone number',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _buildLabel('PASSWORD', sec),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: onSurf),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                      hintText: 'Enter your password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: sec, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error
                  if (authState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(authState.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                        ]),
                      ),
                    ),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.metallicGradient,
                        borderRadius: BorderRadius.circular(8),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3F4041)))
                            : const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3F4041), letterSpacing: 2, fontSize: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Power House Gym, Patna', style: TextStyle(color: sec, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }
}
