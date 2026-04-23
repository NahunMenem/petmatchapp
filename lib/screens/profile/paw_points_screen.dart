import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snack_bar.dart';
import '../../models/patitas_model.dart';
import '../../providers/patitas_provider.dart';

class PawPointsScreen extends ConsumerWidget {
  const PawPointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(patitasWalletProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mis Patitas'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(patitasWalletProvider.notifier).refresh(),
        child: walletAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _PatitasError(),
          data: (wallet) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            children: [
              _BalanceCard(points: wallet.patitas),
              const SizedBox(height: 18),
              Text(
                'Historial de Transacciones',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              if (wallet.transactions.isEmpty)
                const _EmptyTransactions()
              else
                ...wallet.transactions.map(_TransactionTile.fromTransaction),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _ProfileBottomBar(),
    );
  }
}

class BuyPawPointsScreen extends ConsumerStatefulWidget {
  const BuyPawPointsScreen({super.key});

  @override
  ConsumerState<BuyPawPointsScreen> createState() => _BuyPawPointsScreenState();
}

class _BuyPawPointsScreenState extends ConsumerState<BuyPawPointsScreen>
    with WidgetsBindingObserver {
  String? _loadingPackId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(patitasWalletProvider);
    }
  }

  Future<void> _buy(PatitasPack pack) async {
    setState(() => _loadingPackId = pack.id);
    try {
      final preference =
          await ref.read(patitasServiceProvider).createPreference(pack.id);
      final checkoutUrl = kDebugMode
          ? preference.sandboxInitPoint ?? preference.initPoint
          : preference.initPoint;
      final uri = Uri.parse(checkoutUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showSnack('No se pudo abrir Mercado Pago');
      }
      if (mounted) {
        AppSnackBar.info(
          context,
          title: 'Compra iniciada',
          message:
              'Cuando Mercado Pago apruebe el pago se acreditan las Patitas.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnack('No se pudo iniciar la compra');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingPackId = null);
      }
    }
  }

  void _showSnack(String message) {
    AppSnackBar.error(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final packsAsync = ref.watch(patitasPacksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.invalidate(patitasWalletProvider);
            context.pop();
          },
        ),
        title: const Text('Comprar Patitas'),
      ),
      body: packsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _PatitasError(),
        data: (packs) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Center(
              child: Text(
                'Elegi el pack ideal para vos',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (packs.isEmpty)
              const _EmptyPacks()
            else
              for (final pack in packs) ...[
                _PackCard(
                  pack: pack,
                  isHighlighted: pack.id == 'popular',
                  isDark: pack.id == 'pro',
                  highlightLabel: pack.id == 'popular' ? 'MAS POPULAR' : null,
                  isLoading: _loadingPackId == pack.id,
                  onBuy: () => _buy(pack),
                ),
                const SizedBox(height: 16),
              ],
          ],
        ),
      ),
      bottomNavigationBar: const _ProfileBottomBar(),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int points;

  const _BalanceCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu saldo actual',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.pets_outlined, color: Colors.white, size: 38),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '$points',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Patitas disponibles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: () => context.push('/paw-points/buy'),
                  icon: const Icon(Icons.add, size: 19),
                  label: const Text('Comprar patitas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String date;
  final String amount;
  final Color amountColor;

  const _TransactionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.date,
    required this.amount,
    required this.amountColor,
  });

  factory _TransactionTile.fromTransaction(PatitasTransaction transaction) {
    final isPurchase = transaction.type == 'compra';
    final formatter = DateFormat('dd MMM yyyy - HH:mm');
    return _TransactionTile(
      icon: isPurchase ? Icons.shopping_cart_outlined : Icons.bolt_outlined,
      iconColor: isPurchase ? AppColors.primary : const Color(0xFF7C6DFF),
      iconBackground:
          isPurchase ? const Color(0xFFFFF0E7) : const Color(0xFFF1EFFF),
      title: transaction.description,
      date: formatter.format(transaction.date),
      amount: transaction.amount > 0
          ? '+${transaction.amount}'
          : '${transaction.amount}',
      amountColor: transaction.amount > 0 ? AppColors.success : AppColors.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color: amountColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final PatitasPack pack;
  final String? highlightLabel;
  final bool isHighlighted;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onBuy;

  const _PackCard({
    required this.pack,
    this.highlightLabel,
    this.isHighlighted = false,
    this.isDark = false,
    this.isLoading = false,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final background = isDark
        ? const Color(0xFF111111)
        : isHighlighted
            ? AppColors.primary
            : Colors.white;
    final foreground =
        isDark || isHighlighted ? Colors.white : AppColors.textPrimary;
    final accent = isDark ? const Color(0xFFFFD600) : AppColors.primary;
    final buttonBackground = isHighlighted
        ? Colors.white
        : isDark
            ? AppColors.primary
            : AppColors.surfaceVariant.withValues(alpha: 0.75);
    final buttonForeground = isHighlighted
        ? AppColors.primary
        : isDark
            ? Colors.white
            : AppColors.textPrimary;

    return Container(
      height: highlightLabel != null ? 144 : 124,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlightLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_border_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    highlightLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
          ],
          Row(
            children: [
              if (isDark) ...[
                const Icon(
                  Icons.workspace_premium,
                  color: Color(0xFFFFD600),
                  size: 19,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  pack.name,
                  style: TextStyle(
                    color: foreground,
                    fontSize: isDark ? 22 : 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _formatPrice(pack.price),
                style: TextStyle(
                  color: isHighlighted || isDark
                      ? Colors.white
                      : AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.pets_outlined, color: accent, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pack.bonusPatitas > 0
                      ? '${pack.totalPatitas} Patitas (+${pack.bonusPatitas} bonus)'
                      : '${pack.totalPatitas} Patitas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 34,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onBuy,
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.credit_card, size: 15),
                  label:
                      Text(pack.id == 'starter' ? 'Comprar' : 'Comprar con MP'),
                  style: FilledButton.styleFrom(
                    backgroundColor: buttonBackground,
                    foregroundColor: buttonForeground,
                    disabledBackgroundColor:
                        buttonBackground.withValues(alpha: 0.7),
                    disabledForegroundColor:
                        buttonForeground.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Todavia no tenes movimientos.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyPacks extends StatelessWidget {
  const _EmptyPacks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'No hay packs de Patitas disponibles en este momento.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PatitasError extends StatelessWidget {
  const _PatitasError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No se pudo cargar Patitas.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ProfileBottomBar extends StatelessWidget {
  const _ProfileBottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: const SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _BottomBarItem(icon: Icons.home_outlined, label: 'INICIO'),
              _BottomBarItem(
                icon: Icons.favorite_border_rounded,
                label: 'ADOPTAR',
              ),
              _BottomBarItem(
                icon: Icons.location_on_outlined,
                label: 'PERDIDOS',
              ),
              _BottomBarItem(icon: Icons.chat_bubble_outline, label: 'CHATS'),
              _BottomBarItem(
                icon: Icons.person_outline,
                label: 'PERFIL',
                isSelected: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _BottomBarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textHint;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isSelected) context.go('/home');
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPrice(int price) {
  final formatted = NumberFormat.decimalPattern('es_AR').format(price);
  return '\$$formatted';
}
