import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/product.dart';
import '../../state/catalog_provider.dart';
import 'add_edit_product_screen.dart';

class SellerProductsScreen extends StatelessWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();

    if (catalog.isLoading) {
      return DulceWidgets.loadingState();
    }

    if (catalog.products.isEmpty) {
      return Stack(
        children: [
          DulceWidgets.emptyState(
            'No tienes productos aún.\nAgrega tu primer producto 🎂',
            icon: Icons.cake_outlined,
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: _AddProductFAB(),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: DulceColors.cream,
      floatingActionButton: _AddProductFAB(),
      body: RefreshIndicator(
        color: DulceColors.rose,
        onRefresh: () => catalog.refresh(onlyActive: false),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: catalog.products.length,
          itemBuilder: (context, index) =>
              _ProductRow(product: catalog.products[index], index: index),
        ),
      ),
    );
  }
}

class _AddProductFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: DulceColors.gradientPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DulceColors.chocolate.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const AddEditProductScreen()),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Nuevo producto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatefulWidget {
  final Product product;
  final int index;

  const _ProductRow({required this.product, required this.index});

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 50),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final catalog = context.read<CatalogProvider>();

    return FadeTransition(
      opacity: _fade,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: DulceColors.chocolate.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => AddEditProductScreen(product: product)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Imagen
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: DulceColors.chocolateDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge activo/oculto
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.isActive
                                  ? DulceColors.success.withOpacity(0.1)
                                  : DulceColors.sand.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              product.isActive ? 'Activo' : 'Oculto',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: product.isActive
                                    ? DulceColors.success
                                    : DulceColors.chocolateLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product.basePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: DulceColors.rose,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: product.stock > 0
                                ? DulceColors.success
                                : DulceColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stock: ${product.stock}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: product.stock > 0
                                  ? DulceColors.success
                                  : DulceColors.error,
                            ),
                          ),
                          if (product.options.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '· ${product.options.length} opciones',
                              style: TextStyle(
                                fontSize: 11,
                                color: DulceColors.chocolateLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Acciones
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: DulceColors.chocolateLight),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (action) async {
                    switch (action) {
                      case 'stock_out':
                        await catalog.setOutOfStock(product.id);
                        if (context.mounted) {
                          DulceWidgets.showInfo(
                              context, 'Producto marcado como agotado');
                        }
                        break;
                      case 'restock':
                        await catalog.restockProduct(product.id, 10);
                        if (context.mounted) {
                          DulceWidgets.showSuccess(
                              context, '+10 unidades agregadas al stock');
                        }
                        break;
                      case 'toggle':
                        await catalog.toggleActive(
                            product.id, !product.isActive);
                        if (context.mounted) {
                          DulceWidgets.showInfo(
                            context,
                            product.isActive
                                ? 'Producto ocultado del catálogo'
                                : 'Producto visible en el catálogo',
                          );
                        }
                        break;
                      case 'delete':
                        if (context.mounted) {
                          await _confirmDelete(context, catalog, product.id);
                        }
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'stock_out',
                      child: Row(
                        children: [
                          Icon(Icons.remove_shopping_cart_outlined,
                              size: 18, color: DulceColors.warning),
                          SizedBox(width: 10),
                          Text('Marcar agotado'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'restock',
                      child: Row(
                        children: [
                          Icon(Icons.add_shopping_cart_outlined,
                              size: 18, color: DulceColors.success),
                          SizedBox(width: 10),
                          Text('Reponer +10'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            product.isActive
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: DulceColors.info,
                          ),
                          const SizedBox(width: 10),
                          Text(product.isActive ? 'Ocultar' : 'Mostrar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: DulceColors.error),
                          SizedBox(width: 10),
                          Text('Eliminar',
                              style: TextStyle(color: DulceColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, CatalogProvider catalog, int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar producto',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            '¿Estás seguro? Esta acción no se puede deshacer.'),
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await catalog.deleteProduct(productId);
      if (context.mounted) {
        DulceWidgets.showInfo(context, 'Producto eliminado');
      }
    }
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.cake_rounded,
            size: 30, color: DulceColors.chocolate),
      ),
    );
  }
}
