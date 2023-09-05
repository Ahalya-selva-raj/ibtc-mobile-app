import 'package:ibtc/DbTables/invoice-table.dart';
import 'package:ibtc/DbTables/product-item-table.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._getInstance();
  static Database? _database;

  DatabaseHelper._getInstance();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'ibtc-invoices.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNumber TEXT,
        customerName TEXT,
        customerAddress TEXT,
        date TEXT,
        totalAmount REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE productItems(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER,
        name TEXT,
        quantity INTEGER,
        price REAL
      )
    ''');
  }

  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    return await db.insert('invoices', invoice.toMap());
  }

  Future<int> editInvoice(Invoice invoice) async {
    final db = await database;
    return await db.update('invoices', invoice.toMap(), where: 'id = ?', whereArgs: [invoice.id]);
  }

  Future<int> insertProductItem(ProductItem item) async {
    final db = await database;
    return await db.insert('productItems', item.toMap());
  }

  Future<int> editProductItem(ProductItem item) async {
    final db = await database;
    return await db.update('productItems', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }


  Future<List<Invoice>> getInvoices() async {
    final db = await database;
    final maps = await db.query('invoices');
    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ProductItem>> getItemsByInvoiceId(int invoiceId) async {
    final db = await database;
    final maps = await db.query('productItems', where: 'invoiceId = ?', whereArgs: [invoiceId]);
    return List.generate(maps.length, (i) {
      return ProductItem.fromMap(maps[i]);
    });
  }

  Future<Invoice> getInvoiceByInvoiceId(int id) async {
    final db = await database;
    final maps = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    return Invoice.fromMap(maps[0]);
  }

  Future<String> generateInvoiceNumber() async{
    final db = await database;
    final result = await db.rawQuery("SELECT MAX(SUBSTR(invoiceNumber, 2)) AS max_invoice_number FROM invoices WHERE invoiceNumber LIKE 'C%';");
    final maxInvoiceNumber = result.first['max_invoice_number'];
    int nextInvoiceNumber = (maxInvoiceNumber != null) ? int.parse(maxInvoiceNumber.toString()) + 1 : 1;
    return 'C${nextInvoiceNumber.toString().padLeft(3, '0')}';
  }

  deleteProduct(List<int?> ids) async{
    final db = await database;
    for (int? id in ids) {
      await db.delete('productItems', where: 'id = ?', whereArgs: [id]);
    }
  }
}