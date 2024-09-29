import 'dart:io';
import 'package:aligo/models/inventory.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class InventoryDBHelper {
  InventoryDBHelper._privateConstructor();

  static final InventoryDBHelper instance =
      InventoryDBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'aligo.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inventory(
          id INTEGER PRIMARY KEY,
          code TEXT,
          brand TEXT,
          variety TEXT,
          colour TEXT,
          quantity INTEGER,
          date_added DATE,
          image BLOB
      )
      ''');
    await db.execute('''
      CREATE TABLE disbursements(
          id INTEGER PRIMARY KEY,
          employeeId INTEGER,
          productId INTEGER,
          quantity INTEGER,
          dateOfDisbursement DATE
      )
      ''');
  }

  Future<List<Inventory>> getInventories() async {
    Database db = await instance.database;
    var inventories = await db.query('inventory', orderBy: 'date_added DESC');
    List<Inventory> inventoryList = inventories.isNotEmpty
        ? inventories.map((c) => Inventory.fromMap(c)).toList()
        : [];
    return inventoryList;
  }

  Future<List<Inventory>> getInventoryByCode(String code) async {
    Database db = await instance.database;
    var inventories =
        await db.query('inventory', where: 'code="$code"', limit: 1);
    List<Inventory> inventoryList = inventories.isNotEmpty
        ? inventories.map((c) => Inventory.fromMap(c)).toList()
        : [];
    return inventoryList;
  }

  Future<int> add(Inventory inventory) async {
    Database db = await instance.database;
    return await db.insert('inventory', inventory.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Inventory inventory) async {
    Database db = await instance.database;
    return await db.update('inventory', inventory.toMap(),
        where: "id = ?", whereArgs: [inventory.id]);
  }

  Future<String> sumQty() async {
    Database db = await instance.database;
    var sum = await db.rawQuery("SELECT sum(quantity) FROM inventory");
    return sum[0]['sum(quantity)'].toString();
  }

  @Deprecated('No used for now')
  Future<String> sumPrice() async {
    Database db = await instance.database;
    var sum = await db.rawQuery("SELECT sum(price*quantity) FROM inventory");
    return sum[0]['sum(price*quantity)'].toString();
  }

  Future<String> numProducts() async {
    Database db = await instance.database;
    var sum = await db.rawQuery("SELECT count(id) FROM inventory");
    return sum[0]['count(id)'].toString();
  }

  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'aligo.db');
    databaseFactory.deleteDatabase(path);
  }
}
