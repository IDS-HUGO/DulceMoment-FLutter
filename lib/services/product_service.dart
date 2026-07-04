import '../core/supabase_config.dart';
import '../models/product.dart';

class ProductService {
  static const _selectWithOptions = '*, product_options(*)';

  /// Catálogo. `onlyActive = true` para clientes; la tienda ve todo
  /// (la política RLS ya filtra por rol, pero mantenemos el flag por claridad).
  Future<List<Product>> fetchProducts({bool onlyActive = true}) async {
    var query = supabase.from('products').select(_selectWithOptions);
    if (onlyActive) {
      query = query.eq('is_active', true);
    }
    final rows = await query.order('id', ascending: false);
    return (rows as List).map((e) => Product.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// Stream en vivo del catálogo (Supabase Realtime).
  Stream<List<Product>> watchProducts() {
    return supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .order('id', ascending: false)
        .asyncMap((rows) async {
      // El stream de Supabase no anida relaciones; recargamos con opciones.
      return fetchProducts(onlyActive: false);
    });
  }

  Future<Product> addProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String imageUrl,
  }) async {
    if (name.trim().isEmpty || description.trim().isEmpty || price <= 0 || stock < 0) {
      throw ArgumentError('Datos de producto inválidos');
    }

    final row = await supabase
        .from('products')
        .insert({
          'name': name.trim(),
          'description': description.trim(),
          'base_price': price,
          'stock': stock,
          'image_url': imageUrl.trim(),
          'is_active': true,
        })
        .select(_selectWithOptions)
        .single();

    return Product.fromMap(row);
  }

  Future<void> addOption({
    required int productId,
    required String category,
    required String value,
    required double priceDelta,
  }) async {
    await supabase.from('product_options').insert({
      'product_id': productId,
      'category': category,
      'value': value,
      'price_delta': priceDelta,
    });
  }

  Future<Product> updateProduct({
    required int productId,
    required String name,
    required String description,
    required double price,
    required int stock,
    String? imageUrl,
  }) async {
    if (name.trim().isEmpty || description.trim().isEmpty || price <= 0 || stock < 0) {
      throw ArgumentError('Datos de producto inválidos');
    }

    final updates = {
      'name': name.trim(),
      'description': description.trim(),
      'base_price': price,
      'stock': stock,
    };

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      updates['image_url'] = imageUrl.trim();
    }

    final row = await supabase
        .from('products')
        .update(updates)
        .eq('id', productId)
        .select(_selectWithOptions)
        .single();

    return Product.fromMap(row);
  }

  Future<void> deleteProduct(int productId) async {
    // Baja lógica: se oculta del catálogo en lugar de borrar filas
    // referenciadas por pedidos existentes.
    await supabase.from('products').update({
      'is_active': false,
      'stock': 0,
    }).eq('id', productId);
  }

  Future<void> setOutOfStock(int productId) async {
    await supabase.from('products').update({'stock': 0}).eq('id', productId);
  }

  Future<void> restockProduct(int productId, int unitsToAdd) async {
    if (unitsToAdd <= 0) {
      throw ArgumentError('La reposición debe ser mayor a 0');
    }
    final current = await supabase.from('products').select('stock').eq('id', productId).single();
    final newStock = (current['stock'] as int) + unitsToAdd;
    await supabase.from('products').update({'stock': newStock, 'is_active': true}).eq('id', productId);
  }

  Future<void> toggleProductActive(int productId, bool isActive) async {
    await supabase.from('products').update({'is_active': isActive}).eq('id', productId);
  }

  Future<void> setProductStockState({
    required int productId,
    required bool isOutOfStock,
    required int currentStock,
    required bool currentIsActive,
  }) async {
    final targetStock = isOutOfStock ? 0 : (currentStock > 0 ? currentStock : 1);
    await supabase.from('products').update({
      'stock': targetStock,
      'is_active': currentIsActive,
    }).eq('id', productId);
  }
}
