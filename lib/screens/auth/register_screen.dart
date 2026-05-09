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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _loading = false;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_ensureTermsAccepted()) return;
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).registerWithReferral(
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _passCtrl.text,
          referralCode: _referralCtrl.text.trim().isEmpty
              ? null
              : _referralCtrl.text.trim(),
          termsAccepted: _termsAccepted,
        );
    final registerState = ref.read(authProvider);
    if (mounted) setState(() => _loading = false);
    if (mounted && !registerState.hasError) {
      await _showEmailVerificationDialog(_emailCtrl.text.trim());
    }
  }

  bool _ensureTermsAccepted() {
    if (_termsAccepted) return true;
    AppSnackBar.warning(
      context,
      title: 'Acepta los terminos',
      message:
          'Tenes que aceptar los Terminos/EULA y la Politica de Privacidad.',
    );
    return false;
  }

  Future<void> _openLegal(String path) async {
    final uri = Uri.parse('https://pawmatch.com.ar/$path');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showEmailVerificationDialog(String email) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EmailVerificationDialog(
        email: email,
        onConfirm: () {
          Navigator.pop(ctx);
          if (mounted) context.go('/login');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, next) {
      next.when(
        data: (state) {
          if (state.status == AuthStatus.authenticated) {
            context.go('/create-pet');
          }
        },
        error: (e, _) {
          if (mounted) setState(() => _loading = false);
          AppSnackBar.error(
            context,
            message: _authErrorMessage(e),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Center(
                  child: BrandLogo(width: 230, height: 102),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bienvenido a\nPawMatch',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tu cuenta para empezar',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => Validators.required(v, 'El nombre'),
                ),
                const SizedBox(height: 14),
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
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
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
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirmPass,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    hintText: 'Repetir contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirmPass = !_obscureConfirmPass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Repetí tu contraseña';
                    }
                    if (v != _passCtrl.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _referralCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Codigo de referido (opcional)',
                    prefixIcon: Icon(Icons.card_giftcard_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Si te invitaron a PawMatch, carga el codigo y ambos reciben 10 Patitas. Tambien funciona si te registras con Google.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 28),
                _TermsConsent(
                  value: _termsAccepted,
                  onChanged: (value) => setState(
                    () => _termsAccepted = value ?? false,
                  ),
                  onTerms: () => _openLegal('terminos.html'),
                  onPrivacy: () => _openLegal('privacidad.html'),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Crear cuenta',
                  onPressed: _loading ? null : _register,
                  isLoading: _loading,
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
                  label: 'Registrarse con Google',
                  onPressed: _loading
                      ? null
                      : () {
                          if (!_ensureTermsAccepted()) return;
                          ref.read(authProvider.notifier).loginWithGoogle(
                                referralCode: _referralCtrl.text.trim().isEmpty
                                    ? null
                                    : _referralCtrl.text.trim(),
                                termsAccepted: _termsAccepted,
                              );
                        },
                ),
                if (Platform.isIOS) ...[
                  const SizedBox(height: 12),
                  AppleButton(
                    label: 'Registrarse con Apple',
                    onPressed: _loading
                        ? null
                        : () {
                            if (!_ensureTermsAccepted()) return;
                            ref.read(authProvider.notifier).loginWithApple(
                                  referralCode:
                                      _referralCtrl.text.trim().isEmpty
                                          ? null
                                          : _referralCtrl.text.trim(),
                                  termsAccepted: _termsAccepted,
                                );
                          },
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _authErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    final detail = data is Map ? data['detail'] : null;

    if (detail is String && detail.isNotEmpty) {
      if (detail.contains('Codigo de referido invalido')) {
        return 'El codigo de referido no es valido.';
      }
      if (detail.contains('terminos')) {
        return 'Tenes que aceptar los terminos.';
      }
      if (detail.contains('Ya existe una cuenta')) {
        return 'Ya existe una cuenta con ese email.';
      }
      return detail;
    }

    if (detail is List && detail.isNotEmpty) {
      return 'Revisa los datos ingresados.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Sin conexion al servidor.';
    }
  }

  final errorText = error.toString();
  if (errorText.contains('SocketException') ||
      errorText.contains('Connection')) {
    return 'Sin conexion al servidor.';
  }
  return 'Error al crear la cuenta.';
}

class _EmailVerificationDialog extends StatelessWidget {
  final String email;
  final VoidCallback onConfirm;

  const _EmailVerificationDialog({
    required this.email,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '¡Ya casi terminás!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Te enviamos un correo a\n'),
                  TextSpan(
                    text: email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '\n\nHacé clic en el enlace para verificar tu cuenta. Revisá también la carpeta de spam.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              const Text('Acepto los ', style: TextStyle(fontSize: 12)),
              InkWell(
                onTap: onTerms,
                child: const Text(
                  'Terminos/EULA',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(' y la ', style: TextStyle(fontSize: 12)),
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
                '. Tolerancia cero al contenido inapropiado.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
