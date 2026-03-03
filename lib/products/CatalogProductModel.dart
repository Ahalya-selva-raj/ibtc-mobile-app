class CatalogProduct {
  int? id;
  String? name;
  double? defaultPrice;

  CatalogProduct({this.id, this.name, this.defaultPrice});

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'defaultPrice': defaultPrice,
    };
  }

  factory CatalogProduct.fromMap(Map<String, dynamic> map) {
    return CatalogProduct(
      id: map['id'],
      name: map['name'],
      defaultPrice: map['defaultPrice'],
    );
  }
}