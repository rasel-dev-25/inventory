/// A unit of measurement (e.g. 'pcs', 'kg', 'box', 'litre', 'dozen', etc.)
/// configured for a shop.
class ProductUnit {
  final String id;
  final String name;
  final int sortOrder;

  const ProductUnit({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

  ProductUnit copyWith({
    String? name,
    int? sortOrder,
  }) {
    return ProductUnit(
      id: id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductUnit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ sortOrder.hashCode;
}
