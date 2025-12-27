import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/product.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stockmaster.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Increment version to 3 to trigger onUpgrade if needed
    return await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      sku TEXT NOT NULL,
      category TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      costPrice REAL NOT NULL,
      sellingPrice REAL NOT NULL,
      supplier TEXT,
      images TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      passwordHash TEXT NOT NULL,
      role TEXT NOT NULL
    )
    ''');
    
    await _seedUsers(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        role TEXT NOT NULL
      )
      ''');
      await _seedUsers(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE products ADD COLUMN images TEXT');
    }
  }

  Future<void> _seedUsers(Database db) async {
    // Admin User
    final adminPass = sha256.convert(utf8.encode('admin123')).toString();
    await db.insert('users', {
      'username': 'admin',
      'passwordHash': adminPass,
      'role': 'admin'
    });

    // Employee User
    final userPass = sha256.convert(utf8.encode('employee123')).toString();
    await db.insert('users', {
      'username': 'employee',
      'passwordHash': userPass,
      'role': 'employee'
    });
  }

  // --- Products CRUD ---

  Future<int> createProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> readAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'id DESC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // --- Users Auth ---

  Future<User?> getUserByUsername(String username) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    } else {
      return null;
    }
  }
}
