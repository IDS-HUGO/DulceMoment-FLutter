import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/product.dart';
import '../../services/cloudinary_service.dart';
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

  final List<_OptionDraft> _newOptions = [];
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  // Imagen seleccionada localmente (antes de subir)
  File? _pickedImage;
  // URL final en Cloudinary (o la que ya tenía el producto)
  String _uploadedImageUrl = '';

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _uploadedImageUrl = widget.product?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    for (final opt in _newOptions) {
      opt.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────── IMAGEN ───────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked == null) return;
      if (!mounted) return;

      setState(() {
        _pickedImage = File(picked.path);
        _isUploadingImage = true;
      });

      final url = await CloudinaryService.uploadImage(_pickedImage!);

      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = url;
        _isUploadingImage = false;
      });

      DulceWidgets.showSuccess(context, '¡Imagen subida con éxito!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      DulceWidgets.showError(context, 'Error al subir imagen: $e');
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Seleccionar imagen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: DulceColors.chocolateDark,
                ),
              ),
              const SizedBox(height: 16),
              _SourceTile(
                icon: Icons.camera_alt_rounded,
                label: 'Tomar foto',
                color: DulceColors.chocolate,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              _SourceTile(
                icon: Icons.photo_library_rounded,
                label: 'Elegir de la galería',
                color: DulceColors.rose,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_uploadedImageUrl.isNotEmpty || _pickedImage != null)
                _SourceTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Quitar imagen',
                  color: DulceColors.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedImage = null;
                      _uploadedImageUrl = '';
                    });
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── OPCIONES ─────────────────────────────────────

  void _addOptionRow() {
    setState(() => _newOptions.add(_OptionDraft()));
  }

  void _removeOptionRow(int index) {
    setState(() {
      _newOptions[index].dispose();
      _newOptions.removeAt(index);
    });
  }

  // ─────────────────────────── SUBMIT ───────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingImage) {
      DulceWidgets.showError(
          context, 'Espera a que la imagen termine de subirse');
      return;
    }

    setState(() => _isSubmitting = true);

    final catalog = context.read<CatalogProvider>();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final stock = int.parse(_stockController.text.trim());

    bool ok;
    if (_isEditing) {
      ok = await catalog.updateProduct(
        productId: widget.product!.id,
        name: name,
        description: description,
        price: price,
        stock: stock,
        imageUrl: _uploadedImageUrl.isNotEmpty ? _uploadedImageUrl : null,
      );
    } else {
      ok = await catalog.addProduct(
        name: name,
        description: description,
        price: price,
        stock: stock,
        imageUrl: _uploadedImageUrl,
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
    } else {
      DulceWidgets.showError(
        context,
        catalog.errorMessage ?? 'No se pudo guardar el producto',
      );
    }
  }

  // ─────────────────────────── BUILD ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con preview de la imagen seleccionada
          SliverAppBar(
            expandedHeight: 240,
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
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen preview
                  _buildHeroImage(),
                  // Botón para cambiar la imagen
                  Positioned(
                    bottom: 52,
                    right: 16,
                    child: GestureDetector(
                      onTap: _isUploadingImage
                          ? null
                          : _showImageSourceDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isUploadingImage
                              ? Colors.black45
                              : DulceColors.rose,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isUploadingImage)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            else
                              const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _isUploadingImage
                                  ? 'Subiendo...'
                                  : (_pickedImage != null ||
                                          _uploadedImageUrl.isNotEmpty)
                                      ? 'Cambiar foto'
                                      : 'Agregar foto',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                    // Información básica
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

                    // Precio y stock
                    _FormSection(
                      title: 'Precio y stock',
                      icon: Icons.attach_money_rounded,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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

                    // Opciones de personalización
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
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: DulceColors.cream,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: DulceColors.sand),
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

                    // Botón guardar
                    _SaveButton(
                      onPressed: (_isSubmitting || _isUploadingImage)
                          ? null
                          : _submit,
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

  Widget _buildHeroImage() {
    // Imagen local recién seleccionada (ya subida o subiendo)
    if (_pickedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_pickedImage!, fit: BoxFit.cover),
          if (_isUploadingImage)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('Subiendo imagen...',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    // URL de Cloudinary ya existente (edición o subida previa)
    if (_uploadedImageUrl.isNotEmpty) {
      return Image.network(
        _uploadedImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientBackground(),
      );
    }
    // Sin imagen
    return _gradientBackground();
  }

  Widget _gradientBackground() {
    return Container(
      decoration: const BoxDecoration(gradient: DulceColors.gradientPrimary),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                size: 56, color: Colors.white54),
            SizedBox(height: 8),
            Text(
              'Toca "Agregar foto" para subir\nuna imagen del producto',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── WIDGETS AUXILIARES ───────────────────────────────

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
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
      child: Row(
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
            width: 72,
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
