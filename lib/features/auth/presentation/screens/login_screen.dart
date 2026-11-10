import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_role.dart';
import '../../../../shared/widgets/app_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_split_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authControllerProvider.notifier).signIn(
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text,
          );

      // Explicitly wait for profile resolution and direct the router
      final profile = await ref.read(currentProfileProvider.future);
      if (!mounted) return;

      if (profile == null) {
        throw Exception('Account profile not found. Please contact platform support.');
      }

      if (!profile.isActive) {
        throw Exception('Your account is currently inactive. Please contact administration.');
      }

      if (profile.role.isSuperAdmin) {
        context.go('/super-admin');
        return;
      }

      if (profile.pharmacyId == null) {
        context.go('/register-pharmacy');
        return;
      }

      final pharmacy = await ref.read(currentPharmacyProvider.future);
      if (!mounted) return;

      if (pharmacy == null || !pharmacy.isEffectivelyApproved) {
        context.go('/approval-status');
        return;
      }

      switch (profile.role) {
        case UserRole.admin:
          context.go('/dashboard');
          break;
        case UserRole.storekeeper:
          context.go('/inventory');
          break;
        case UserRole.cashier:
          context.go('/pos');
          break;
        case UserRole.superAdmin:
          context.go('/super-admin');
          break;
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $msg'),
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
          // Logo mark on mobile
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
            'Welcome back',
            textAlign: TextAlign.center,
            style: tokens.typography.pageTitle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to access your pharmacy portal',
            textAlign: TextAlign.center,
            style: tokens.typography.cardSubtitle,
          ),
          const SizedBox(height: 28),

          // Email Field
          Text(
            'Email address',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: tokens.typography.body,
            decoration: InputDecoration(
              hintText: 'e.g. cashier@yourpharmacy.com or admin@email.com',
              helperText:
                  'Cashiers & Storekeepers: Use the exact email assigned by your admin (e.g. ali@yourpharmacy.com)',
              helperMaxLines: 2,
              prefixIcon:
                  Icon(LucideIcons.mail, size: 18, color: tokens.colors.muted),
              filled: true,
              fillColor: tokens.isDark ? tokens.colors.track : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                borderSide:
                    const BorderSide(color: AppColorsTokens.focusRing, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              final clean = value.trim();
              if (!clean.contains('@')) {
                return 'Enter your full email (e.g. ali@yourpharmacy.com)';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Password Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.colors.ink,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/forgot-password'),
                child: const Text(
                  'Forgot?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColorsTokens.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: tokens.typography.body,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(LucideIcons.lock, size: 18, color: tokens.colors.muted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: tokens.colors.muted,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
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
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Sign In Button
          AppButton(
            text: 'Sign In to Portal',
            isLoading: isLoading,
            radius: 12,
            height: 48,
            onPressed: isLoading ? null : _handleLogin,
          ),
          const SizedBox(height: 20),

          // Register pharmacy link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'New pharmacy owner? ',
                style: TextStyle(fontSize: 13, color: tokens.colors.muted),
              ),
              GestureDetector(
                onTap: () => context.push('/signup'),
                child: const Text(
                  'Register your pharmacy',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColorsTokens.brand,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return AuthSplitLayout(cardContent: cardContent);
  }
}
