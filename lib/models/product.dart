class ProductOption {
  final int id;
  final int productId;
  final String category; // ej: "size", "shape", "flavor", "color"
  final String value;
  final double priceDelta;

  const ProductOption({
    required this.id,
    required this.productId,
    required this.category,
    required this.value,
    required this.priceDelta,
  });

  factory ProductOption.fromMap(Map<String, dynamic> map) {
    return ProductOption(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      category: map['category'] as String,
      value: map['value'] as String,
      priceDelta: (map['price_delta'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'product_id': productId,
        'category': category,
        'value': value,
        'price_delta': priceDelta,
      };
}

class Product {
  final int id;
  final String name;
  final String description;
  final double basePrice;
  final int stock;
  final String imageUrl;
  final bool isActive;
  final List<ProductOption> options;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.stock,
    required this.imageUrl,
    required this.isActive,
    this.options = const [],
  });

  bool get isInStock => stock > 0 && isActive;

  List<String> optionValues(String category) => options
      .where((o) => o.category == category)
      .map((o) => o.value)
      .toList();

  double priceDeltaFor(String category, String value) {
    final match = options.where((o) => o.category == category && o.value == value);
    return match.isEmpty ? 0 : match.first.priceDelta;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final rawOptions = (map['product_options'] as List<dynamic>?) ?? const [];
    return Product(
      id: map['id'] as int,
      name: (map['name'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      basePrice: (map['base_price'] as num).toDouble(),
      stock: map['stock'] as int,
      imageUrl: (map['image_url'] ?? '') as String,
      isActive: (map['is_active'] ?? true) as bool,
      options: rawOptions
          .map((o) => ProductOption.fromMap(o as Map<String, dynamic>))
          .toList(),
    );
  }

  Product copyWith({
    String? name,
    String? description,
    double? basePrice,
    int? stock,
    String? imageUrl,
    bool? isActive,
    List<ProductOption>? options,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      options: options ?? this.options,
    );
  }
}
