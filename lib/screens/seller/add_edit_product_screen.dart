import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../state/catalog_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.product?.name ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.product?.description ?? '');
  late final _priceController = TextEditingController(
    text: widget.product != null ? widget.product!.basePrice.toString() : '',
  );
  late final _stockController = TextEditingController(
    text: widget.product != null ? widget.product!.stock.toString() : '',
  );
  late final _imageUrlController =
      TextEditingController(text: widget.product?.imageUrl ?? '');

  final List<_OptionDraft> _newOptions = [];
  bool _isSubmitting = false;
  String _previewImageUrl = '';

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _previewImageUrl = widget.product?.imageUrl ?? '';
    _imageUrlController.addListener(() {
      if (mounted) setState(() => _previewImageUrl = _imageUrlController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    for (final opt in _newOptions) {
      opt.dispose();
    }
    super.dispose();
  }

  void _addOptionRow() {
    setState(() => _newOptions.add(_OptionDraft()));
  }

  void _removeOptionRow(int index) {
    setState(() {
      _newOptions[index].dispose();
      _newOptions.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final catalog = context.read<CatalogProvider>();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final stock = int.parse(_stockController.text.trim());
    final imageUrl = _imageUrlController.text.trim();

    bool ok;
    if (_isEditing) {
      ok = await catalog.updateProduct(
        productId: widget.product!.id,
        name: name,
        description: description,
        price: price,
        stock: stock,
      );
    } else {
      ok = await catalog.addProduct(
        name: name,
        description: description,
        price: price,
        stock: stock,
        imageUrl: imageUrl,
      );
    }

    if (ok && _newOptions.isNotEmpty) {
      final target = catalog.products.firstWhere(
        (p) => p.name == name && p.basePrice == price,
        orElse: () => catalog.products.first,
      );
      final service = ProductService();
      for (final option in _newOptions) {
        if (option.category.text.trim().isEmpty ||
            option.value.text.trim().isEmpty) continue;
        await service.addOption(
          productId: target.id,
          category: option.category.text.trim(),
          value: option.value.text.trim(),
          priceDelta: double.tryParse(option.priceDelta.text) ?? 0,
        );
      }
      await catalog.refresh(onlyActive: false);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      Navigator.of(context).pop();
      // No podemos usar DulceWidgets desde aquí porque el contexto es del padre
    } else {
      DulceWidgets.showError(
        context,
        catalog.errorMessage ?? 'No se pudo guardar el producto',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con preview de imagen
          SliverAppBar(
            expandedHeight: _previewImageUrl.isNotEmpty ? 200 : kToolbarHeight,
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
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _isEditing ? 'Editar producto' : 'Nuevo producto',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              background: _previewImageUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _previewImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gradientBackground(),
                        ),
                        Container(color: Colors.black38),
                      ],
                    )
                  : _gradientBackground(),
            ),
          ),

          // Formulario
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: DulceColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección: Información básica
                    _FormSection(
                      title: 'Información básica',
                      icon: Icons.info_outline_rounded,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del producto',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                            maxLines: 3,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sección: Precio y stock
                    _FormSection(
                      title: 'Precio y stock',
                      icon: Icons.attach_money_rounded,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Precio base (\$)',
                                prefixIcon: Icon(Icons.sell_outlined),
                              ),
                              validator: (v) {
                                final value = double.tryParse(v ?? '');
                                return (value == null || value <= 0)
                                    ? 'Precio inválido'
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stock inicial',
                                prefixIcon:
                                    Icon(Icons.inventory_2_outlined),
                              ),
                              validator: (v) {
                                final value = int.tryParse(v ?? '');
                                return (value == null || value < 0)
                                    ? 'Stock inválido'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sección: Imagen (solo en creación)
                    if (!_isEditing) ...[
                      _FormSection(
                        title: 'Imagen del producto',
                        icon: Icons.image_outlined,
                        child: TextFormField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'URL de imagen (opcional)',
                            prefixIcon: Icon(Icons.link_rounded),
                            hintText: 'https://...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sección: Opciones de personalización
                    _FormSection(
                      title: 'Opciones de personalización',
                      icon: Icons.tune_rounded,
                      trailing: TextButton.icon(
                        onPressed: _addOptionRow,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Agregar'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      child: _newOptions.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: DulceColors.cream,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: DulceColors.sand,
                                    style: BorderStyle.solid),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 16,
                                      color: DulceColors.chocolateLight),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Agrega opciones como tamaño, sabor, color o forma',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: DulceColors.chocolateLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: List.generate(
                                _newOptions.length,
                                (index) => _OptionRow(
                                  option: _newOptions[index],
                                  onRemove: () => _removeOptionRow(index),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Botón de guardar
                    _SaveButton(
                      onPressed: _isSubmitting ? null : _submit,
                      isLoading: _isSubmitting,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBackground() {
    return Container(
      decoration: const BoxDecoration(gradient: DulceColors.gradientPrimary),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: DulceColors.chocolate.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: DulceColors.rose),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DulceColors.chocolateDark,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final _OptionDraft option;
  final VoidCallback onRemove;

  const _OptionRow({required this.option, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DulceColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DulceColors.sand),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: option.category,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    hintText: 'ej: size',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: option.value,
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    hintText: 'ej: Grande',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: option.priceDelta,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '+\$',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: DulceColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEditing;

  const _SaveButton({
    required this.onPressed,
    required this.isLoading,
    required this.isEditing,
  });

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
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
          height: 54,
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
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isEditing
                            ? Icons.save_rounded
                            : Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isEditing
                            ? 'Guardar cambios'
                            : 'Crear producto',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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

class _OptionDraft {
  final category = TextEditingController();
  final value = TextEditingController();
  final priceDelta = TextEditingController(text: '0');

  void dispose() {
    category.dispose();
    value.dispose();
    priceDelta.dispose();
  }
}
