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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: checkingSession
            ? const _Splash()
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: BrandLogo(width: 250, height: 104),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Entrá a PawMatch',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 30,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Matches, adopciones y alertas cerca tuyo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 28),
                          GoogleButton(
                            label: _loadingGoogle
                                ? 'Conectando...'
                                : 'Continuar con Google',
                            onPressed: _loadingEmail || _loadingGoogle
                                ? null
                                : _loginWithGoogle,
                          ),
                          const SizedBox(height: 20),
                          const _DividerLabel(),
                          const SizedBox(height: 20),
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
                            onPressed:
                                _loadingEmail || _loadingGoogle ? null : _login,
                          ),
                          const SizedBox(height: 18),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Text('Crear cuenta nueva'),
                          ),
                          const SizedBox(height: 20),
                          const _LoginFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  String _authErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('401')) return 'Email o contraseña incorrectos';
    if (text.contains('SocketException') || text.contains('Connection')) {
      return 'Sin conexión al servidor';
    }
    if (text.contains('Google')) return 'No se pudo ingresar con Google';
    return 'No se pudo iniciar sesión';
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
