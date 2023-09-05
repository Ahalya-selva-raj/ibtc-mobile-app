class Invoice {
  int? id;
  String invoiceNumber;
  String date;
  String customerName;
  String customerAddress;
  double totalAmount;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    required this.customerAddress,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'date': date,
      'customerName': customerName,
      'customerAddress': customerAddress,
      'totalAmount': totalAmount,
    };
  }

  static Invoice fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoiceNumber'],
      date: map['date'],
      customerName: map['customerName'],
      customerAddress: map['customerAddress'],
      totalAmount: map['totalAmount'],
    );
  }
}
