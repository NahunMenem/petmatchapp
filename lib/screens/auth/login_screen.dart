import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_authErrorMessage(error)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
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
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: BrandLogo(width: 190, height: 92),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Hola de nuevo',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ingresa para conectar con mascotas cerca tuyo.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 28),
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
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Ingresar',
                        isLoading: _loadingEmail,
                        onPressed:
                            _loadingEmail || _loadingGoogle ? null : _login,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'o',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GoogleButton(
                        label: _loadingGoogle
                            ? 'Conectando...'
                            : 'Continuar con Google',
                        onPressed: _loadingEmail || _loadingGoogle
                            ? null
                            : _loginWithGoogle,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('No tenes cuenta? Crear cuenta'),
                        ),
                      ),
                    ],
                  ),
                ),
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

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BrandLogo(width: 220, height: 220),
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
