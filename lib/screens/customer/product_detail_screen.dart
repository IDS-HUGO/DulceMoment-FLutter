import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/product.dart';
import '../../services/order_service.dart';
import '../../state/catalog_provider.dart';
import '../../state/orders_provider.dart';
import '../../state/session_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String? _size;
  String? _shape;
  String? _flavor;
  String? _color;
  final _ingredientsController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _size = p.optionValues('size').firstOrNull;
    _shape = p.optionValues('shape').firstOrNull;
    _flavor = p.optionValues('flavor').firstOrNull;
    _color = p.optionValues('color').firstOrNull;
  }

  @override
  void dispose() {
    _ingredientsController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _unitPrice {
    final p = widget.product;
    var price = p.basePrice;
    if (_size != null) price += p.priceDeltaFor('size', _size!);
    if (_shape != null) price += p.priceDeltaFor('shape', _shape!);
    if (_flavor != null) price += p.priceDeltaFor('flavor', _flavor!);
    if (_color != null) price += p.priceDeltaFor('color', _color!);
    return price;
  }

  Future<void> _submitOrder() async {
    if (_addressController.text.trim().isEmpty) {
      DulceWidgets.showError(
          context, 'La dirección de entrega es obligatoria');
      return;
    }

    final session = context.read<SessionProvider>();
    final user = session.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final ordersProvider = context.read<OrdersProvider>();
    final orderId = await ordersProvider.createOrder(
      customer: user,
      catalog: context.read<CatalogProvider>().products,
      items: [
        OrderItemDraft(
          productId: widget.product.id,
          quantity: _quantity,
          unitPrice: _unitPrice,
          ingredients: _ingredientsController.text.trim(),
          size: _size ?? '',
          shape: _shape ?? '',
          flavor: _flavor ?? '',
          color: _color ?? '',
        ),
      ],
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (orderId != null) {
      Navigator.of(context).pop();
      DulceWidgets.showSuccess(
          context, '¡Pedido #$orderId creado! Ve a "Mis pedidos" para pagarlo.');
    } else {
      DulceWidgets.showError(
          context, ordersProvider.errorMessage ?? 'No se pudo crear el pedido');
    }
  }

  Widget _optionSelector(
      String label, String category, String? value, ValueChanged<String> onChanged) {
    final options = widget.product.optionValues(category);
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: DulceColors.chocolateDark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final selected = value == opt;
            return GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected ? DulceColors.gradientPrimary : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? DulceColors.chocolate : DulceColors.sand,
                    width: selected ? 0 : 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: DulceColors.chocolate.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.white : DulceColors.chocolateDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final total = _unitPrice * _quantity;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen hero
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: DulceColors.chocolate,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: p.imageUrl.isNotEmpty
                  ? Image.network(
                      p.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _heroPlaceholder(),
                    )
                  : _heroPlaceholder(),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: DulceColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y precio
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: DulceColors.chocolateDark,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${p.basePrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: DulceColors.rose,
                            ),
                          ),
                          Text(
                            'precio base',
                            style: TextStyle(
                              fontSize: 11,
                              color: DulceColors.chocolateLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  if (p.description.isNotEmpty) ...[
                    Text(
                      p.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: DulceColors.chocolateLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Stock badge
                  if (p.isInStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: DulceColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: DulceColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 14, color: DulceColors.success),
                          const SizedBox(width: 5),
                          Text(
                            '${p.stock} disponibles',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DulceColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Sección de opciones
                  if (p.options.isNotEmpty) ...[
                    _SectionLabel(label: 'Personaliza tu pastel'),
                    const SizedBox(height: 16),
                    _optionSelector('Tamaño', 'size', _size,
                        (v) => setState(() => _size = v)),
                    _optionSelector('Forma', 'shape', _shape,
                        (v) => setState(() => _shape = v)),
                    _optionSelector('Sabor', 'flavor', _flavor,
                        (v) => setState(() => _flavor = v)),
                    _optionSelector('Color', 'color', _color,
                        (v) => setState(() => _color = v)),
                  ],

                  // Ingredientes especiales
                  _SectionLabel(label: 'Personalización extra'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ingredientsController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredientes / decoración especial',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                      hintText: 'Ej: Sin gluten, flores comestibles...',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // Cantidad
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: DulceColors.chocolate.withOpacity(0.06),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_basket_outlined,
                            color: DulceColors.chocolate, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'Cantidad',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DulceColors.chocolateDark,
                          ),
                        ),
                        const Spacer(),
                        _QuantityButton(
                          icon: Icons.remove_rounded,
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: DulceColors.chocolateDark,
                            ),
                          ),
                        ),
                        _QuantityButton(
                          icon: Icons.add_rounded,
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sección de entrega
                  _SectionLabel(label: 'Datos de entrega'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de entrega *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas para la tienda',
                      prefixIcon: Icon(Icons.sticky_note_2_outlined),
                      hintText: 'Ej: Llame al timbre 2 veces',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 100), // espacio para sticky bottom
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky bottom bar
      bottomNavigationBar: Container(
        padding:
            const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: DulceColors.chocolate.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: DulceColors.chocolateLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: DulceColors.rose,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _SubmitButton(
                  onPressed: _isSubmitting || !p.isInStock
                      ? null
                      : _submitOrder,
                  isLoading: _isSubmitting,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: DulceColors.gradientPrimary,
      ),
      child: const Center(
        child: Icon(Icons.cake_rounded, size: 80, color: Colors.white38),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: DulceColors.gradientPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DulceColors.chocolateDark,
          ),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: onPressed != null ? DulceColors.gradientPrimary : null,
          color: onPressed == null ? DulceColors.sand : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: onPressed != null ? Colors.white : Colors.white70,
          size: 18,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _SubmitButton({required this.onPressed, required this.isLoading});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.onPressed == null
                ? LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade400])
                : DulceColors.gradientPrimary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                      color: DulceColors.chocolate.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_checkout_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Confirmar pedido',
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

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
