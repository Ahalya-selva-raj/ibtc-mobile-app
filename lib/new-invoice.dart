import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ibtc/DbTables/invoice-table.dart';
import 'package:ibtc/db-helper.dart';
import 'package:ibtc/reusable/widgets.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import 'DbTables/product-item-table.dart';

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

class NewInvoice extends StatefulWidget {
  final Invoice? invoice;
  final List<ProductItem>? productItems;

  const NewInvoice({Key? key, this.invoice, this.productItems})
      : super(key: key);

  @override
  State<NewInvoice> createState() => _NewInvoiceState();
}

class _NewInvoiceState extends State<NewInvoice> {
  final db = DatabaseHelper.instance;
  late ProductItemDataSource productItemDataSource;
  List<ProductItem>? productItem;
  int? productIndexToBeUpdated;
  DateTime? pickedInvoiceDate;

  TextEditingController customerName = TextEditingController();
  TextEditingController customerAddress = TextEditingController();
  TextEditingController invoiceDate = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController quantity = TextEditingController();
  TextEditingController unitPrice = TextEditingController();
  TextEditingController invoiceNumber = TextEditingController();

  final _customerFormKey = GlobalKey<FormState>();
  final _productFormKey = GlobalKey<FormState>();

  bool isCreatingProduct = false;
  bool isEditingProduct = false;

  List<ProductItem>? getProductItems() {
    if (widget.invoice != null) {
      setState(() {
        customerName.text = widget.invoice?.customerName ?? "";
        customerAddress.text = widget.invoice?.customerAddress ?? "";
        invoiceDate.text = DateFormat("dd/MM/yyyy")
            .format(DateTime.parse(widget.invoice?.date ?? ""));
      });
    }
    if (widget.productItems != null && widget.productItems!.isNotEmpty) {
      productItem = widget.productItems;
      return productItem;
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    productItem = getProductItems();
    updateDataSource();
  }

  void updateDataSource() {
    if (productItem != null) {
      productItemDataSource = ProductItemDataSource(productItems: productItem!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.invoice != null ? "Edit Invoice" : "Create Invoice"),
        actions: [
          IconButton(
              onPressed: () {
                productIndexToBeUpdated = null;
                createProductItem();
              },
              icon: const Icon(Icons.add)),
        ],
      ),
      body: Column(
        children: [
          Form(
            key: _customerFormKey,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xff941751),
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  TextFormField(
                    controller: invoiceNumber,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                        hintText: "Enter Invoice Number",
                        hintStyle: TextStyle(
                            color: Color(0xfff3e5eb),
                            fontWeight: FontWeight.w300,
                            fontSize: 13),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        errorStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  TextFormField(
                    controller: customerName,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Customer Name Required!";
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                        hintText: "Enter Customer Name",
                        hintStyle: TextStyle(
                            color: Color(0xfff3e5eb),
                            fontWeight: FontWeight.w300,
                            fontSize: 13),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        errorStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  TextFormField(
                    controller: customerAddress,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Customer Address Required!";
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                        hintText: "Enter Customer Address",
                        hintStyle: TextStyle(
                            color: Color(0xfff3e5eb),
                            fontWeight: FontWeight.w300,
                            fontSize: 13),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        errorStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  GestureDetector(
                    onTap: () async {
                      await datePicker(context);
                    },
                    child: TextFormField(
                      controller: invoiceDate,
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "Invoice Date Required!";
                        }
                        return null;
                      },
                      enabled: false,
                      decoration: const InputDecoration(
                          hintText: "DD/MM/YYYY",
                          hintStyle: TextStyle(
                              color: Color(0xfff3e5eb),
                              fontWeight: FontWeight.w300,
                              fontSize: 13),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                          suffixIcon: Icon(
                            Icons.date_range,
                            color: Color(0xffe7cbd8),
                          ),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xffe7cbd8)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xffe7cbd8)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xffe7cbd8)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          errorStyle: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SfDataGrid(
              allowEditing: true,
              selectionMode: SelectionMode.single,
              navigationMode: GridNavigationMode.cell,
              columnWidthMode: ColumnWidthMode.fitByColumnName,
              columns: <GridColumn>[
                GridColumn(
                    columnWidthMode: ColumnWidthMode.fitByColumnName,
                    allowEditing: true,
                    columnName: 'Description',
                    label: Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Description',
                        ))),
                GridColumn(
                    allowEditing: true,
                    columnName: 'Qty',
                    label: Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.centerLeft,
                        child: const Text('Qty'))),
                GridColumn(
                    columnName: 'Unit Price',
                    allowEditing: true,
                    width: 120,
                    label: Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.centerLeft,
                        child: const Text('Unit Price'))),
                GridColumn(
                    allowEditing: false,
                    columnName: 'Total',
                    label: Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.centerRight,
                        child: const Text('Total'))),
                GridColumn(
                    allowEditing: false,
                    columnName: 'Edit',
                    label: Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.centerRight,
                        child: const Text('Edit'))),
                GridColumn(
                    columnName: 'Delete',
                    allowEditing: false,
                    label: Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.centerRight,
                        child: const Text('Delete'))),
              ],
              onCellTap: (DataGridCellTapDetails dataGridCellTapDetails) {
                if (dataGridCellTapDetails.rowColumnIndex.columnIndex == 4) {
                  final rowIndex =
                      dataGridCellTapDetails.rowColumnIndex.rowIndex;
                  print(rowIndex);
                  final productIndex = rowIndex - 1;
                  productIndexToBeUpdated = productIndex;
                  createProductItem();
                }
                if (dataGridCellTapDetails.rowColumnIndex.columnIndex == 5) {
                  final rowIndex =
                      dataGridCellTapDetails.rowColumnIndex.rowIndex;
                  final productIndex = rowIndex - 1;
                  deleteProduct(productIndex);
                }
              },
              source: productItemDataSource,
            ),
          )
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(Color(0xff941751)),
              foregroundColor: MaterialStatePropertyAll(Colors.white70)),
          onPressed: () async {
            if (isCreatingProduct || isEditingProduct) {
              if (_productFormKey.currentState?.validate() == true) {
                addProduct();
              }
            } else {
              if (_customerFormKey.currentState?.validate() == true) {
                await saveInvoice(context);
              }
            }
          },
          child: Text(isCreatingProduct
              ? "Add Product Item"
              : widget.invoice != null
                  ? "Update"
                  : "Save"),
        ),
      ),
    );
  }

  Future<void> datePicker(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      //get today's date
      firstDate: DateTime(2000),
      //DateTime.now() - not to allow to choose before today.
      lastDate: DateTime(DateTime.now().year + 30),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff941751),
              // header background color
              onPrimary: Colors.white70,
              // header text color
              onSurface: Color(0xffab4a77), // b// ody text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xffab4a77), // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        invoiceDate.text = DateFormat("dd/MM/yyyy").format(pickedDate);
        pickedInvoiceDate = pickedDate;
      });
    }
  }

  Future<void> saveInvoice(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const LoadingProgressPopup();
      },
    );
    deleteProductFromInvoice();
    double totalAmount = 0.0;
    for (var item in productItem!) {
      totalAmount += (item.quantity! * item.price!);
    }
    var invoice = Invoice(
        id: widget.invoice?.id,
        invoiceNumber: invoiceNumber.text.isEmpty
            ? await db.generateInvoiceNumber()
            : invoiceNumber.text,
        date: pickedInvoiceDate == null
            ? (widget.invoice?.date ?? "")
            : pickedInvoiceDate!.toIso8601String(),
        customerName: customerName.text,
        customerAddress: customerAddress.text,
        totalAmount: totalAmount);
    var invoiceId = invoice.id == null
        ? await db.insertInvoice(invoice)
        : await db.editInvoice(invoice);
    for (var item in productItem!) {
      item.invoiceId = widget.invoice?.id ?? invoiceId;
      if (widget.invoice?.id != null) {
        var result = await db.editProductItem(item);
        if (result == 0) {
          await db.insertProductItem(item);
        }
      } else {
        await db.insertProductItem(item);
      }
    }
    Navigator.of(context).pop(true);
    Navigator.of(context).pop(true);
  }

  void createProductItem({productId}) {
    description = TextEditingController();
    quantity = TextEditingController();
    unitPrice = TextEditingController();
    ProductItem? product;
    setState(() {
      if (productIndexToBeUpdated != null) {
        product = productItem![productIndexToBeUpdated!];
        description.text = product!.name.toString();
        quantity.text = product!.quantity.toString();
        unitPrice.text = product!.price.toString();
        isEditingProduct = true;
      } else {
        isCreatingProduct = true;
      }
    });
    scaffoldKey.currentState
        ?.showBottomSheet((context) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _productFormKey,
              child: Column(
                children: [
                  const SizedBox(
                    height: 25,
                  ),
                  TextFormField(
                    controller: description,
                    cursorColor: const Color(0xff941751),
                    style: const TextStyle(color: Colors.black, fontSize: 13),
                    decoration: const InputDecoration(
                        labelText: "Enter Product Description",
                        labelStyle: TextStyle(
                            color: Color(0xff941751),
                            fontWeight: FontWeight.w300,
                            fontSize: 13),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffe7cbd8)),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffe7cbd8)),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        )),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Description Required!";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: quantity,
                    cursorColor: const Color(0xff941751),
                    style: const TextStyle(color: Colors.black, fontSize: 13),
                    keyboardType:
                        const TextInputType.numberWithOptions(signed: true),
                    decoration: const InputDecoration(
                        labelText: "Enter Product Qty",
                        labelStyle: TextStyle(
                            color: Color(0xff941751),
                            fontWeight: FontWeight.w300,
                            fontSize: 13),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffe7cbd8)),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffe7cbd8)),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        )),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Quantity Required!";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: unitPrice,
                    cursorColor: const Color(0xff941751),
                    style: const TextStyle(color: Colors.black, fontSize: 13),
                    keyboardType:
                        const TextInputType.numberWithOptions(signed: true),
                    decoration: const InputDecoration(
                        labelText: "Enter Product Unit Price",
                        labelStyle: TextStyle(
                            color: Color(0xff941751),
                            fontWeight: FontWeight.w300,
                            fontSize: 13),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xffe7cbd8)),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffe7cbd8)),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffe7cbd8)),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        )),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Unit Price Required!";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          );
        })
        .closed
        .then((value) {
          setState(() {
            isCreatingProduct = false;
            isEditingProduct = false;
          });
        });
  }

  void addProduct() {
    setState(() {
      if (productIndexToBeUpdated != null) {
        var productTemp = productItem![productIndexToBeUpdated!];
        productTemp.name = description.text;
        productTemp.quantity = int.parse(quantity.text);
        productTemp.price = double.parse(unitPrice.text);
        print("Editing");
      } else {
          productItem?.add(ProductItem(
            name: description.text,
            quantity: int.parse(quantity.text),
            price: double.parse(unitPrice.text),
          ));
      }
      productItemDataSource = ProductItemDataSource(productItems: productItem!);
    });
    Navigator.pop(context);
  }

  List<int> deletedProductIds = [];

  void deleteProduct(int productIndex) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteConfirmationDialog(
          onDelete: () async {
            if (productItem![productIndex].id != null) {
              deletedProductIds.add(productItem![productIndex].id!);
            }
            setState(() {
              productItem?.removeAt(productIndex);
              productItemDataSource =
                  ProductItemDataSource(productItems: productItem!);
            });
          },
        );
      },
    );
  }

  void deleteProductFromInvoice() async {
    if (deletedProductIds.isNotEmpty) {
      await db.deleteProduct(deletedProductIds);
    }
  }
}

class Product {
  Product({this.description, this.quantity, this.unitPrice});

  final String? description;
  final int? quantity;
  final double? unitPrice;

  toMap() {
    return {
      "description": description,
      "quantity": quantity,
      "unitPrice": unitPrice
    };
  }
}

class ProductItemDataSource extends DataGridSource {
  ProductItemDataSource({required List<ProductItem> productItems}) {
    _employees = productItems
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'Description', value: e.name),
              DataGridCell<int>(columnName: 'Qty', value: e.quantity),
              DataGridCell<double>(columnName: 'Unit Price', value: e.price),
              DataGridCell<double>(
                  columnName: 'Total',
                  value: ((e.quantity ?? 0) * (e.price ?? 0))),
              const DataGridCell<Widget>(
                  columnName: 'Edit',
                  value: Icon(
                    Icons.edit,
                    size: 15,
                    color: CupertinoColors.activeBlue,
                  )),
              const DataGridCell<Widget>(
                  columnName: 'Delete',
                  value: Icon(
                    Icons.delete,
                    size: 15,
                    color: Colors.redAccent,
                  )),
            ]))
        .toList();
  }

  List<DataGridRow> _employees = [];

  @override
  List<DataGridRow> get rows => _employees;

  List<DataGridRow> dataGridRows = <DataGridRow>[];

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((dataGridCell) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: dataGridCell.columnName == "Edit" ||
                dataGridCell.columnName == "Delete"
            ? dataGridCell.value
            : Text(dataGridCell.value.toString()),
      );
    }).toList());
  }
}

class LoadingProgressPopup extends StatelessWidget {
  const LoadingProgressPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
