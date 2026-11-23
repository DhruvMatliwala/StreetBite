/// Represents a single dish offered by a street food stall.
class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.isVeg = true,
    this.category = 'Specials',
    this.description = '',
    this.imageUrl = '',
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final double price;
  final bool isVeg;
  final String category;
  final String description;
  final String imageUrl;
  final bool isAvailable;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isVeg: (json['isVeg'] as bool?) ?? true,
      category: (json['category'] as String?) ?? 'Specials',
      description: (json['description'] as String?) ?? '',
      imageUrl: (json['imageUrl'] as String?) ?? '',
      isAvailable: (json['isAvailable'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'price': price,
      'isVeg': isVeg,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    double? price,
    bool? isVeg,
    String? category,
    String? description,
    String? imageUrl,
    bool? isAvailable,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isVeg: isVeg ?? this.isVeg,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuItem &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.isVeg == isVeg &&
        other.category == category &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        price,
        isVeg,
        category,
        description,
        imageUrl,
        isAvailable,
      );
}
