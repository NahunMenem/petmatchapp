import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/google_button.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _loadingEmail = false;
  bool _loadingGoogle = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loadingEmail = true);
    await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
    if (mounted) setState(() => _loadingEmail = false);
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loadingGoogle = true);
    await ref.read(authProvider.notifier).loginWithGoogle();
    if (mounted) setState(() => _loadingGoogle = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      next.whenOrNull(
        data: (state) {
          if (state.status == AuthStatus.authenticated) {
            context.go('/home');
          }
        },
        error: (error, _) {
          if (mounted) {
            setState(() {
              _loadingEmail = false;
              _loadingGoogle = false;
            });
          }
          AppSnackBar.error(
            context,
            message: _authErrorMessage(error),
          );
        },
      );
    });

    final checkingSession =
        authState.isLoading && !_loadingEmail && !_loadingGoogle;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: checkingSession
            ? const _Splash()
            : Stack(
                children: [
                  const _LoginBackdrop(),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const Center(
                            child: BrandLogo(width: 270, height: 112),
                          ),
                          const SizedBox(height: 14),
                          const _LoginHero(),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ingresá a tu cuenta',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Conectá con mascotas cercanas, matches y avisos importantes en un solo lugar.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscurePass,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  decoration: InputDecoration(
                                    hintText: 'Contrasena',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePass
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass,
                                      ),
                                    ),
                                  ),
                                  validator: Validators.password,
                                ),
                                const SizedBox(height: 18),
                                PrimaryButton(
                                  label: 'Ingresar',
                                  isLoading: _loadingEmail,
                                  onPressed: _loadingEmail || _loadingGoogle
                                      ? null
                                      : _login,
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'o seguí con',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                GoogleButton(
                                  label: _loadingGoogle
                                      ? 'Conectando...'
                                      : 'Continuar con Google',
                                  onPressed: _loadingEmail || _loadingGoogle
                                      ? null
                                      : _loginWithGoogle,
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: TextButton(
                                    onPressed: () => context.push('/register'),
                                    child: const Text(
                                      'No tenes cuenta? Crear cuenta',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _LoginTrustRow(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _authErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('401')) return 'Email o contrasena incorrectos';
    if (text.contains('SocketException') || text.contains('Connection')) {
      return 'Sin conexion al servidor';
    }
    if (text.contains('Google')) return 'No se pudo ingresar con Google';
    return 'No se pudo iniciar sesion';
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 110,
          right: -50,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: 118,
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.16),
                  AppColors.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF3E8),
            Color(0xFFFFF8F2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PawMatch',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Volvé a conectar con mascotas cerca tuyo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Matches, chats, adopciones y alertas solidarias en una experiencia más cálida y simple.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroBadge(icon: Icons.favorite_rounded, label: 'Matches reales'),
              _HeroBadge(icon: Icons.location_on_rounded, label: 'Mascotas cerca'),
              _HeroBadge(icon: Icons.chat_bubble_rounded, label: 'Chats rápidos'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTrustRow extends StatelessWidget {
  const _LoginTrustRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _TrustChip(
            icon: Icons.pets_rounded,
            label: 'Perfil de mascota',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _TrustChip(
            icon: Icons.notifications_active_rounded,
            label: 'Alertas útiles',
          ),
        ),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BrandLogo(width: 280, height: 280),
          SizedBox(height: 48),
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ],
      ),
    );
  }
}
