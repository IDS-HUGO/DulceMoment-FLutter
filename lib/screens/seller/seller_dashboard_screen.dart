import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../state/catalog_provider.dart';
import '../../state/orders_provider.dart';
import '../../state/session_provider.dart';
import 'seller_orders_screen.dart';
import 'seller_products_screen.dart';
import 'seller_summary_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().start(onlyActive: false);
      context.read<OrdersProvider>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final orders = context.watch<OrdersProvider>().orders;
    final pendingCount = orders
        .where((o) => o.status == 'created' && !o.isPaid)
        .length;
    final readyCount = orders
        .where((o) => o.isPaid && o.status != 'delivered' && o.status != 'cancelled')
        .length;

    const pages = [
      SellerOrdersScreen(),
      SellerProductsScreen(),
      SellerSummaryScreen(),
    ];

    final tabTitles = ['Pedidos', 'Productos', 'Resumen'];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: _tabIndex == 0 ? 180 : kToolbarHeight,
            backgroundColor: DulceColors.chocolate,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              title: _tabIndex != 0
                  ? Text(
                      tabTitles[_tabIndex],
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    )
                  : null,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: DulceColors.gradientPrimary,
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: _tabIndex == 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Panel de tienda',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            session.currentUser?.name ?? 'Tienda',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _QuickStat(
                                icon: Icons.pending_actions_rounded,
                                label: 'Sin pagar',
                                value: '$pendingCount',
                                color: DulceColors.warning,
                              ),
                              const SizedBox(width: 12),
                              _QuickStat(
                                icon: Icons.local_fire_department_rounded,
                                label: 'En proceso',
                                value: '$readyCount',
                                color: DulceColors.rose,
                              ),
                              const SizedBox(width: 12),
                              _QuickStat(
                                icon: Icons.receipt_long_rounded,
                                label: 'Total',
                                value: '${orders.length}',
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Cerrar sesión',
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
        ],
        body: pages[_tabIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.receipt_long_rounded),
            ),
            label: 'Pedidos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.cake_outlined),
            selectedIcon: Icon(Icons.cake_rounded),
            label: 'Productos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Resumen',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DulceColors.error,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<SessionProvider>().logout();
    }
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
