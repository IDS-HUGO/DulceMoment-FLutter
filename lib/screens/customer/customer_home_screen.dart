import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/product.dart';
import '../../state/catalog_provider.dart';
import '../../state/orders_provider.dart';
import '../../state/session_provider.dart';
import '../../widgets/product_card.dart';
import 'customer_orders_screen.dart';
import 'product_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<SessionProvider>().currentUser;
      context.read<CatalogProvider>().start(onlyActive: true);
      if (user != null) {
        context.read<OrdersProvider>().start(customerId: user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final user = session.currentUser;
    final pages = [
      const _CatalogTab(),
      const CustomerOrdersScreen(),
    ];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: _tabIndex == 0 ? 140 : kToolbarHeight,
            backgroundColor: DulceColors.chocolate,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              title: _tabIndex == 0
                  ? null
                  : const Text(
                      'Mis Pedidos',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
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
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hola, ${user?.name.split(' ').first ?? 'Cliente'} 👋',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Text(
                                      'Dulce Moment',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white38, width: 2),
                                ),
                                child: const Icon(Icons.cake_rounded,
                                    color: Colors.white, size: 22),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.cake_outlined),
            selectedIcon: Icon(Icons.cake_rounded),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Mis pedidos',
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

class _CatalogTab extends StatelessWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final size = MediaQuery.sizeOf(context);

    if (catalog.isLoading) {
      return DulceWidgets.loadingState();
    }
    if (catalog.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: DulceColors.sand),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el catálogo',
                style: TextStyle(
                    fontSize: 16,
                    color: DulceColors.chocolateDark,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                catalog.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: DulceColors.chocolateLight),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => catalog.refresh(onlyActive: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(160, 44)),
              ),
            ],
          ),
        ),
      );
    }
    if (catalog.products.isEmpty) {
      return DulceWidgets.emptyState(
        'Aún no hay productos disponibles.\n¡Vuelve pronto!',
        icon: Icons.cake_outlined,
      );
    }

    // Grid adaptativo según tamaño de pantalla
    final crossAxisCount = size.width < 400
        ? 1
        : size.width < 700
            ? 2
            : size.width < 1000
                ? 3
                : 4;

    return RefreshIndicator(
      color: DulceColors.rose,
      onRefresh: () => catalog.refresh(onlyActive: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.70,
        ),
        itemCount: catalog.products.length,
        itemBuilder: (context, index) {
          final Product product = catalog.products[index];
          return _AnimatedProductCard(
            product: product,
            index: index,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product)),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedProductCard extends StatefulWidget {
  final Product product;
  final int index;
  final VoidCallback onTap;

  const _AnimatedProductCard({
    required this.product,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + widget.index * 60),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ProductCard(
          product: widget.product,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
