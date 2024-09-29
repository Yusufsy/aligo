import 'dart:io';

import 'package:aligo/models/disbursement.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DisbursementDBHelper {
  DisbursementDBHelper._privateConstructor();

  static final DisbursementDBHelper instance =
      DisbursementDBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ?? await _initDatabase();
  var year = DateFormat('yyyy').format(DateTime.now());

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
      CREATE TABLE disbursements(
          id INTEGER PRIMARY KEY,
          employeeId INTEGER,
          productId INTEGER,
          quantity INTEGER,
          dateOfDisbursement DATE
      )
      ''');
    //amount INTEGER,
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
    //cost INTEGER,
    //price INTEGER,
  }

  Future<List<DisbursementRecord>> getDisbursements() async {
    try {
      Database db = await instance.database;
      // var sales = await db.query('sales', orderBy: 'dateOfDisbursement DESC').catchError((e){print (e);});
      var disbursementRecords = await db.rawQuery(
          "SELECT disbursements.id, disbursements.employeeId, disbursements.productId, inventory.image, inventory.brand, inventory.variety, "
          "disbursements.quantity, disbursements.dateOfDisbursement FROM disbursements, inventory WHERE disbursements.productId = inventory.id ORDER BY disbursements.dateOfDisbursement DESC");
      List<DisbursementRecord> disbursementsList =
          disbursementRecords.isNotEmpty
              ? disbursementRecords
                  .map((c) => DisbursementRecord.fromMap(c))
                  .toList()
              : [];
      return disbursementsList;
    } catch (e, stk) {
      debugPrint(e.toString());
      debugPrint(stk.toString());
      return Future.value([]);
    }
  }

  Future<List<DisbursementRecord>> getDisbursementsByDay() async {
    Database db = await instance.database;
    // var sales = await db.query('sales', orderBy: 'dateOfDisbursement DESC').catchError((e){print (e);});
    var disbursementRecords = await db.rawQuery(
        "SELECT disbursements.id, disbursements.employeeId, disbursements.productId, inventory.image, inventory.brand, inventory.variety, "
        "disbursements.quantity, disbursements.dateOfDisbursement FROM disbursements, inventory WHERE disbursements.productId = inventory.id "
        "AND disbursements.dateOfDisbursement = CURRENT_DATE ORDER BY disbursements.dateOfDisbursement DESC");
    List<DisbursementRecord> disbursementList = disbursementRecords.isNotEmpty
        ? disbursementRecords.map((c) => DisbursementRecord.fromMap(c)).toList()
        : [];
    return disbursementList;
  }

  Future<List<DisbursementRecord>> getDisbursementsByMonth() async {
    Database db = await instance.database;
    var disbursementRecords = await db.rawQuery(
        "SELECT disbursements.id, disbursements.employeeId, disbursements.productId, inventory.image, inventory.brand, inventory.variety, "
        "disbursements.quantity, disbursements.dateOfDisbursement FROM disbursements, inventory WHERE disbursements.productId = inventory.id "
        "AND disbursements.dateOfDisbursement > DATETIME('now', '-30 day') ORDER BY disbursements.dateOfDisbursement DESC");
    List<DisbursementRecord> disbursementList = disbursementRecords.isNotEmpty
        ? disbursementRecords.map((c) => DisbursementRecord.fromMap(c)).toList()
        : [];
    return disbursementList;
  }

  Future<List<DisbursementRecord>> getDisbursementByYear() async {
    Database db = await instance.database;
    var disbursementRecords = await db.rawQuery(
        "SELECT disbursements.id, disbursements.employeeId, disbursements.productId, inventory.image, inventory.brand, inventory.variety, "
        "disbursements.quantity, disbursements.dateOfDisbursement FROM disbursements, inventory WHERE disbursements.productId = inventory.id "
        "AND strftime('%Y', disbursements.dateOfDisbursement) = '$year' ORDER BY disbursements.dateOfDisbursement DESC");
    List<DisbursementRecord> disbursementsList = disbursementRecords.isNotEmpty
        ? disbursementRecords.map((c) => DisbursementRecord.fromMap(c)).toList()
        : [];
    return disbursementsList;
  }

  Future<int> add(Disbursement disbursement) async {
    Database db = await instance.database;
    await db.rawQuery(
        "UPDATE inventory SET quantity = quantity-${disbursement.quantity} WHERE id=${disbursement.productId}");
    return await db.insert('disbursements', disbursement.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('disbursements', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Disbursement disbursement) async {
    Database db = await instance.database;
    return await db.update('disbursements', disbursement.toMap(),
        where: "id = ?", whereArgs: [disbursement.id]);
  }

  Future<String> sumQty(String? filter) async {
    Database db = await instance.database;
    if (filter == 'day') {
      var sum = await db.rawQuery(
          "SELECT sum(quantity) FROM disbursements WHERE dateOfDisbursement = CURRENT_DATE");
      return sum[0]['sum(quantity)'].toString();
    }
    if (filter == 'month') {
      var sum = await db.rawQuery(
          "SELECT sum(quantity) FROM disbursements WHERE dateOfDisbursement > DATETIME('now', '-30 day')");
      return sum[0]['sum(quantity)'].toString();
    }
    if (filter == 'year') {
      var sum = await db.rawQuery(
          "SELECT sum(quantity) FROM disbursements WHERE strftime('%Y', dateOfDisbursement) = '$year'");
      return sum[0]['sum(quantity)'].toString();
    }
    var sum = await db.rawQuery("SELECT sum(quantity) FROM disbursements");
    return sum[0]['sum(quantity)'].toString();
  }

  Future<String> sumAmount(String? filter) async {
    Database db = await instance.database;
    if (filter == 'day') {
      var sum = await db.rawQuery(
          "SELECT sum(amount) FROM disbursements WHERE dateOfDisbursement = CURRENT_DATE");
      return sum[0]['sum(amount)'].toString();
    }
    if (filter == 'month') {
      var sum = await db.rawQuery(
          "SELECT sum(amount) FROM disbursements WHERE dateOfDisbursement > DATETIME('now', '-30 day')");
      return sum[0]['sum(amount)'].toString();
    }
    if (filter == 'year') {
      var sum = await db.rawQuery(
          "SELECT sum(amount) FROM disbursements WHERE strftime('%Y', dateOfDisbursement) = '$year'");
      return sum[0]['sum(amount)'].toString();
    }
    var sum = await db.rawQuery("SELECT sum(amount) FROM disbursements");
    return sum[0]['sum(amount)'].toString();
  }

  Future<String> numDisbursements(String? filter) async {
    Database db = await instance.database;
    if (filter == 'day') {
      var num = await db.rawQuery(
          "SELECT count(id) FROM disbursements WHERE dateOfDisbursement = CURRENT_DATE");
      return num[0]['count(id)'].toString();
    }
    if (filter == 'month') {
      var num = await db.rawQuery(
          "SELECT count(id) FROM disbursements WHERE dateOfDisbursement > DATETIME('now', '-30 day')");
      return num[0]['count(id)'].toString();
    }
    if (filter == 'month') {
      var num = await db.rawQuery(
          "SELECT count(id) FROM disbursements WHERE strftime('%Y', dateOfDisbursement) = '$year'");
      return num[0]['count(id)'].toString();
    }
    var num = await db.rawQuery("SELECT count(id) FROM disbursements");
    return num[0]['count(id)'].toString();
  }

  @Deprecated('No profit usage for now')
  Future<String> getProfit(String? filter) async {
    Database db = await instance.database;
    if (filter == 'day') {
      var profit = await db.rawQuery(
          "SELECT sum((inventory.price-inventory.cost)*sales.quantity) as profit from sales, inventory "
          "WHERE sales.productId = inventory.id AND dateOfDisbursement = CURRENT_DATE");
      return profit[0]['profit'].toString();
    }
    if (filter == 'month') {
      var profit = await db.rawQuery(
          "SELECT sum((inventory.price-inventory.cost)*sales.quantity) as profit from sales, inventory "
          "WHERE sales.productId = inventory.id AND dateOfDisbursement > DATETIME('now', '-30 day')");
      return profit[0]['profit'].toString();
    }
    if (filter == 'month') {
      var profit = await db.rawQuery(
          "SELECT sum((inventory.price-inventory.cost)*sales.quantity) as profit from sales, inventory "
          "WHERE sales.productId = inventory.id AND strftime('%Y', dateOfDisbursement) = '$year'");
      return profit[0]['profit'].toString();
    }
    var profit = await db.rawQuery(
        "SELECT sum((inventory.price-inventory.cost)*sales.quantity) as profit from sales, inventory WHERE sales.productId = inventory.id");
    return profit[0]['profit'].toString();
  }
}
