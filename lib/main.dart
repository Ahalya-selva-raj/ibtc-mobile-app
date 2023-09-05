import 'package:flutter/material.dart';
import 'package:ibtc/DbTables/invoice-table.dart';
import 'package:ibtc/db-helper.dart';
import 'package:ibtc/menu/drawer.dart';
import 'package:ibtc/new-invoice.dart';
import 'package:ibtc/service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff941751),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xff941751),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final db = DatabaseHelper.instance;

  List<Invoice>? invoices;

  @override
  void initState() {
    super.initState();
    getInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const IBTCDrawer(),
      appBar: AppBar(
        title: const Text("Invoice Generator"),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            if (invoices != null)
              ...?invoices?.map((e) => Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(15)),
                        border: Border.all(
                            color: const Color(0xff941751).withOpacity(0.2)),
                        image: const DecorationImage(
                            image: NetworkImage(
                                "https://www.pandle.com/wp-content/uploads/2021/12/How-to-Generate-an-Invoice-Best-Practice-Good-Habits-and-Time-Saving-Tips.png"),
                            fit: BoxFit.cover)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          width: MediaQuery.of(context).size.width,
                          decoration: const BoxDecoration(
                              color: Color(0xff941751),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.3,
                                  child: Text(
                                    "${e.invoiceNumber} - ${e.customerName}",
                                    style:
                                        const TextStyle(color: Colors.white70),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                              GestureDetector(
                                  onTapDown: (details) {
                                    _showPopUpMenu(details.globalPosition,
                                        data: e);
                                  },
                                  child: const Icon(
                                    Icons.more_vert_outlined,
                                    size: 15,
                                    color: Colors.white70,
                                  ))
                            ],
                          ),
                        )
                      ],
                    ),
                  ))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const NewInvoice()));
          if (result == true) {
            getInvoices();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  _showPopUpMenu(Offset offset, {required Invoice data}) async {
    final screenSize = MediaQuery.of(context).size;
    double left = offset.dx;
    double top = offset.dy;
    double right = screenSize.width - offset.dx;
    double bottom = screenSize.height - offset.dy;

    await showMenu<MenuItemType>(
      surfaceTintColor: Colors.amber,
      context: context,
      position: RelativeRect.fromLTRB(left, top, right, bottom),
      items: MenuItemType.values
          .map((MenuItemType menuItemType) => PopupMenuItem<MenuItemType>(
                value: menuItemType,
                child: Row(
                  children: [
                    showIcon(menuItemType),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(getMenuItemString(menuItemType)),
                  ],
                ),
              ))
          .toList(),
    ).then((MenuItemType? item) async {
      if (item == MenuItemType.delete) {
        await deleteInvoice(data);
      }
      if (item == MenuItemType.edit) {
        if (data.id != null) {
          var result = await db.getInvoiceByInvoiceId(data.id!);
          var productList = await db.getItemsByInvoiceId(data.id!);
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  NewInvoice(invoice: result, productItems: productList)));
        }
      }
      if (item == MenuItemType.clone) {
        await cloneInvoice(data);
      }
      if (item == MenuItemType.download) {
        var productList = await db.getItemsByInvoiceId(data.id!);
        Service.generateInvoice(data, productList);
      }
    });
  }

  Future<void> cloneInvoice(Invoice data) async {
    var productList = await db.getItemsByInvoiceId(data.id!);
    var invoice = Invoice(
        id: null,
        invoiceNumber: await db.generateInvoiceNumber(),
        date: data.date,
        customerName: data.customerName,
        customerAddress: data.customerAddress,
        totalAmount: data.totalAmount);
    var invoiceId = await db.insertInvoice(invoice);
    for (var item in productList) {
      item.invoiceId =  invoiceId;
      item.id = null;
      await db.insertProductItem(item);
    }
    getInvoices();
  }

  Future<void> deleteInvoice(Invoice data) async {
    if (data.id != null) {
      int result = await db.deleteInvoice(data.id!);
      if (result != 0) {
        setState(() {
          invoices?.removeWhere((element) => element.id == data.id);
        });
      }
    }
  }

  void getInvoices() async {
    invoices = await db.getInvoices();
    if (mounted) {
      setState(() {});
    }
  }

  showIcon(MenuItemType menuItemType) {
    if (menuItemType == MenuItemType.edit) {
      return const Icon(Icons.edit);
    }
    if (menuItemType == MenuItemType.delete) {
      return const Icon(Icons.delete);
    }
    if (menuItemType == MenuItemType.clone) {
      return const Icon(Icons.cyclone);
    }
    if (menuItemType == MenuItemType.download) {
      return const Icon(Icons.download);
    }
  }
}

enum MenuItemType {
  edit,
  delete,
  clone,
  download,
}

getMenuItemString(MenuItemType menuItemType) {
  switch (menuItemType) {
    case MenuItemType.edit:
      return "Edit";
    case MenuItemType.delete:
      return "Delete";
    case MenuItemType.clone:
      return "Clone";
    case MenuItemType.download:
      return "Download";
  }
}
