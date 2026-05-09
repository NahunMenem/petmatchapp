import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/apple_button.dart';
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
  bool _loadingApple = false;
  bool _termsAccepted = false;

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
    if (!_ensureTermsAccepted()) return;
    setState(() => _loadingGoogle = true);
    await ref
        .read(authProvider.notifier)
        .loginWithGoogle(termsAccepted: _termsAccepted);
    if (mounted) setState(() => _loadingGoogle = false);
  }

  Future<void> _loginWithApple() async {
    if (!_ensureTermsAccepted()) return;
    setState(() => _loadingApple = true);
    await ref
        .read(authProvider.notifier)
        .loginWithApple(termsAccepted: _termsAccepted);
    if (mounted) setState(() => _loadingApple = false);
  }

  bool _ensureTermsAccepted() {
    if (_termsAccepted) return true;
    AppSnackBar.warning(
      context,
      title: 'Acepta los terminos',
      message:
          'Para crear una cuenta con Google o Apple tenes que aceptar los terminos.',
    );
    return false;
  }

  Future<void> _openLegal(String path) async {
    final uri = Uri.parse('https://pawmatch.com.ar/$path');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
              _loadingApple = false;
            });
          }
          AppSnackBar.error(
            context,
            message: _authErrorMessage(error),
          );
        },
      );
    });

    final checkingSession = authState.isLoading &&
        !_loadingEmail &&
        !_loadingGoogle &&
        !_loadingApple;

    return Scaffold(
      backgroundColor: const Color(0xFF17111F),
      body: SafeArea(
        child: checkingSession
            ? const _Splash()
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF17111F),
                      Color(0xFF331538),
                      Color(0xFFFF5F7E),
                      Color(0xFFFF8A3D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.42, 0.78, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    const _LoginColorWash(),
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: Form(
                            key: _formKey,
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(22, 24, 22, 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(34),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.24),
                                    blurRadius: 42,
                                    offset: const Offset(0, 24),
                                  ),
                                  BoxShadow(
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.18),
                                    blurRadius: 60,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Center(
                                    child: BrandLogo(width: 245, height: 98),
                                  ),
                                  const SizedBox(height: 12),

                                  const SizedBox(height: 8),
                                  const Text(
                                    'Matches, adopciones y alertas cerca tuyo.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  GoogleButton(
                                    label: _loadingGoogle
                                        ? 'Conectando...'
                                        : 'Continuar con Google',
                                    onPressed: _loadingEmail ||
                                            _loadingGoogle ||
                                            _loadingApple
                                        ? null
                                        : _loginWithGoogle,
                                  ),
                                  if (Platform.isIOS) ...[
                                    const SizedBox(height: 12),
                                    AppleButton(
                                      label: _loadingApple
                                          ? 'Conectando...'
                                          : 'Continuar con Apple',
                                      onPressed: _loadingEmail ||
                                              _loadingGoogle ||
                                              _loadingApple
                                          ? null
                                          : _loginWithApple,
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  _TermsConsent(
                                    value: _termsAccepted,
                                    onChanged: (value) => setState(
                                      () => _termsAccepted = value ?? false,
                                    ),
                                    onTerms: () => _openLegal('terminos.html'),
                                    onPrivacy: () =>
                                        _openLegal('privacidad.html'),
                                  ),
                                  const SizedBox(height: 18),
                                  const _DividerLabel(),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
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
                                      labelText: 'Contraseña',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
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
                                    onPressed: _loadingEmail ||
                                            _loadingGoogle ||
                                            _loadingApple
                                        ? null
                                        : _login,
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () => context.push('/register'),
                                    child: const Text('Crear cuenta nueva'),
                                  ),
                                  const SizedBox(height: 16),
                                  const _LoginFooter(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _authErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final detail = data is Map ? data['detail'] : null;
      if (detail is String && detail.isNotEmpty) {
        if (detail.contains('verificar')) {
          return 'Tenes que verificar tu correo antes de ingresar.';
        }
        return detail;
      }
    }
    final text = error.toString();
    if (text.contains('403')) {
      return 'Tenes que verificar tu correo antes de ingresar.';
    }
    if (text.contains('401')) return 'Email o contraseña incorrectos';
    if (text.contains('SocketException') || text.contains('Connection')) {
      return 'Sin conexión al servidor';
    }
    if (text.contains('Google')) return 'No se pudo ingresar con Google';
    if (text.contains('Apple')) return 'No se pudo ingresar con Apple';
    if (text.contains('terminos')) return 'Tenes que aceptar los terminos';
    return 'No se pudo iniciar sesión';
  }
}

class _TermsConsent extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  const _TermsConsent({
    required this.value,
    required this.onChanged,
    required this.onTerms,
    required this.onPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Acepto los ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              InkWell(
                onTap: onTerms,
                child: const Text(
                  'Terminos y EULA',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                ' y la ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              InkWell(
                onTap: onPrivacy,
                child: const Text(
                  'Privacidad',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                '. PawMatch tiene tolerancia cero al contenido inapropiado.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginColorWash extends StatelessWidget {
  const _LoginColorWash();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -70,
          right: -70,
          top: 50,
          child: Transform.rotate(
            angle: -0.18,
            child: Container(
              height: 116,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.16),
                    AppColors.primary.withValues(alpha: 0.24),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const Positioned(
          right: 22,
          top: 56,
          child: _FloatingPaw(
            size: 28,
            angle: 0.22,
            opacity: 0.30,
          ),
        ),
        const Positioned(
          left: 24,
          top: 156,
          child: _FloatingPaw(
            size: 20,
            angle: -0.26,
            opacity: 0.22,
          ),
        ),
        const Positioned(
          right: 36,
          bottom: 108,
          child: _FloatingPaw(
            size: 34,
            angle: -0.18,
            opacity: 0.24,
          ),
        ),
        const Positioned(
          left: 34,
          bottom: 46,
          child: _FloatingPaw(
            size: 24,
            angle: 0.34,
            opacity: 0.18,
          ),
        ),
        Positioned(
          top: -95,
          right: -110,
          child: Container(
            width: 310,
            height: 310,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  AppColors.secondary.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -120,
          bottom: 36,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.28),
                  AppColors.secondary.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingPaw extends StatelessWidget {
  final double size;
  final double angle;
  final double opacity;

  const _FloatingPaw({
    required this.size,
    required this.angle,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Icon(
        Icons.pets_rounded,
        color: Colors.white.withValues(alpha: opacity),
        size: size,
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o con email',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 17),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Tu sesión queda protegida en este dispositivo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
