import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_split_layout.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authControllerProvider.notifier).signUpAdmin(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _nameController.text,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Now register your pharmacy details.'),
            backgroundColor: AppColorsTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: AppColorsTokens.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    final cardContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColorsTokens.brandGradient,
                borderRadius: BorderRadius.circular(AppRadiusTokens.logoMark),
                boxShadow: const [AppColorsTokens.logoMarkShadow],
              ),
              alignment: Alignment.center,
              child: const Text(
                '+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Create Admin Account',
            textAlign: TextAlign.center,
            style: tokens.typography.pageTitle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 6),
          Text(
            'Step 1 of 2: Create your pharmacy owner profile',
            textAlign: TextAlign.center,
            style: tokens.typography.cardSubtitle,
          ),
          const SizedBox(height: 24),

          // Full Name
          Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.colors.ink)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            style: tokens.typography.body,
            decoration: _inputDecoration(tokens, 'e.g. Dr. Ahmed Khan', LucideIcons.user),
            validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
          ),
          const SizedBox(height: 14),

          // Email
          Text('Email Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.colors.ink)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: tokens.typography.body,
            decoration: _inputDecoration(tokens, 'owner@pharmacy.com', LucideIcons.mail),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Phone
          Text('Phone Number (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.colors.ink)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: tokens.typography.body,
            decoration: _inputDecoration(tokens, '+92 300 1234567', LucideIcons.phone),
          ),
          const SizedBox(height: 14),

          // Password
          Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.colors.ink)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: tokens.typography.body,
            decoration: _inputDecoration(
              tokens,
              'Minimum 8 characters',
              LucideIcons.lock,
              suffix: IconButton(
                icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: tokens.colors.muted),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Confirm Password
          Text('Confirm Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.colors.ink)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscurePassword,
            style: tokens.typography.body,
            decoration: _inputDecoration(tokens, 'Re-enter your password', LucideIcons.lock),
            validator: (v) {
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          AppButton(
            text: 'Continue to Pharmacy Info',
            isLoading: isLoading,
            radius: 12,
            height: 48,
            onPressed: isLoading ? null : _handleSignUp,
          ),
          const SizedBox(height: 20),

          // Back to login
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Already have an account? ', style: TextStyle(fontSize: 13, color: tokens.colors.muted)),
              GestureDetector(
                onTap: () => context.pop(),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColorsTokens.brand),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return AuthSplitLayout(cardContent: cardContent);
  }

  InputDecoration _inputDecoration(AppTokens tokens, String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: tokens.colors.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: tokens.isDark ? tokens.colors.track : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.colors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.colors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsTokens.focusRing, width: 2),
      ),
    );
  }
}
