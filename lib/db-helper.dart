import 'package:ibtc/DbTables/invoice-table.dart';
import 'package:ibtc/DbTables/product-item-table.dart';
import 'package:ibtc/customer/CustomerModel.dart';
import 'package:ibtc/products/CatalogProductModel.dart';
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
      version: 2, // bumped from 1 → 2
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
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

    await db.execute('''
      CREATE TABLE catalogProducts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        defaultPrice REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        address TEXT
      )
    ''');
  }

  /// Runs when upgrading an existing DB from version 1 to 2.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS catalogProducts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          defaultPrice REAL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          address TEXT
        )
      ''');
    }
  }

  // ─── Invoices ────────────────────────────────────────────────────────────────

  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    return await db.insert('invoices', invoice.toMap());
  }

  Future<int> editInvoice(Invoice invoice) async {
    final db = await database;
    return await db.update('invoices', invoice.toMap(),
        where: 'id = ?', whereArgs: [invoice.id]);
  }

  Future<List<Invoice>> getInvoices() async {
    final db = await database;
    final maps = await db.query('invoices');
    return List.generate(maps.length, (i) => Invoice.fromMap(maps[i]));
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<Invoice> getInvoiceByInvoiceId(int id) async {
    final db = await database;
    final maps =
    await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    return Invoice.fromMap(maps[0]);
  }

  Future<String> generateInvoiceNumber() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT MAX(SUBSTR(invoiceNumber, 2)) AS max_invoice_number FROM invoices WHERE invoiceNumber LIKE 'C%';");
    final maxInvoiceNumber = result.first['max_invoice_number'];
    int next =
    (maxInvoiceNumber != null) ? int.parse(maxInvoiceNumber.toString()) + 1 : 1;
    return 'C${next.toString().padLeft(3, '0')}';
  }

  // ─── Product Items (invoice line items) ──────────────────────────────────────

  Future<int> insertProductItem(ProductItem item) async {
    final db = await database;
    return await db.insert('productItems', item.toMap());
  }

  Future<int> editProductItem(ProductItem item) async {
    final db = await database;
    return await db.update('productItems', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<List<ProductItem>> getItemsByInvoiceId(int invoiceId) async {
    final db = await database;
    final maps = await db.query('productItems',
        where: 'invoiceId = ?', whereArgs: [invoiceId]);
    return List.generate(maps.length, (i) => ProductItem.fromMap(maps[i]));
  }

  Future<void> deleteProduct(List<int?> ids) async {
    final db = await database;
    for (int? id in ids) {
      await db.delete('productItems', where: 'id = ?', whereArgs: [id]);
    }
  }

  // ─── Catalog Products ─────────────────────────────────────────────────────────

  Future<int> insertCatalogProduct(CatalogProduct product) async {
    final db = await database;
    return await db.insert('catalogProducts', product.toMap());
  }

  Future<int> updateCatalogProduct(CatalogProduct product) async {
    final db = await database;
    return await db.update('catalogProducts', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteCatalogProduct(int id) async {
    final db = await database;
    return await db
        .delete('catalogProducts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CatalogProduct>> getCatalogProducts() async {
    final db = await database;
    final maps =
    await db.query('catalogProducts', orderBy: 'name ASC');
    return maps.map((m) => CatalogProduct.fromMap(m)).toList();
  }

  // ─── Customers ────────────────────────────────────────────────────────────────

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update('customers', customer.toMap(),
        where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }
}