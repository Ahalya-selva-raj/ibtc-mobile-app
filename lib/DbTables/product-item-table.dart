class ProductItem {
  int? id;
  int? invoiceId;
  String? name;
  int? quantity;
  double? price;

  ProductItem({this.id, this.invoiceId, this.name, this.quantity, this.price});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory ProductItem.fromMap(Map<String, dynamic> map) {
    return ProductItem(
      id: map['id'],
      invoiceId: map['invoiceId'],
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'],
    );
  }
}