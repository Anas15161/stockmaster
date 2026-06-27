import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/product.dart';
import '../models/user.dart';
import '../models/stock_movement.dart';

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

    // Increment version to 8 to trigger onUpgrade
    return await openDatabase(path, version: 8, onCreate: _createDB, onUpgrade: _onUpgrade);
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
      email TEXT NOT NULL,
      passwordHash TEXT NOT NULL,
      role TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      productId INTEGER NOT NULL,
      productName TEXT NOT NULL,
      type TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      date TEXT NOT NULL,
      reason TEXT,
      userId TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE
    )
    ''');

    await db.execute('''
    CREATE TABLE roles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE
    )
    ''');

    await db.execute('''
    CREATE TABLE role_permissions (
      role_name TEXT NOT NULL,
      permission TEXT NOT NULL,
      PRIMARY KEY (role_name, permission)
    )
    ''');
    
    await _seedUsers(db);
    await _seedCategories(db);
    await _seedRolesAndPermissions(db);
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
    if (oldVersion < 4) {
      await db.execute('''
      CREATE TABLE movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        date TEXT NOT NULL,
        reason TEXT,
        userId TEXT NOT NULL
      )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
      ''');
      await _seedCategories(db);
    }
    if (oldVersion < 6) {
      await db.execute('''
      CREATE TABLE roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
      ''');
      await db.execute('''
      CREATE TABLE role_permissions (
        role_name TEXT NOT NULL,
        permission TEXT NOT NULL,
        PRIMARY KEY (role_name, permission)
      )
      ''');
      await _seedRolesAndPermissions(db);
    }
    if (oldVersion < 7) {
      // Ensure admin has manage_settings and other permissions
      final adminPerms = ['manage_products', 'manage_stock', 'view_reports', 'manage_users', 'manage_settings'];
      for (var p in adminPerms) {
        try {
          await db.insert('role_permissions', {'role_name': 'admin', 'permission': p});
        } catch (e) {
          // Ignore unique constraint errors
        }
      }
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      await db.rawUpdate("UPDATE users SET email = username || '@stockmaster.com' WHERE email IS NULL");
    }
  }

  Future<void> _seedUsers(Database db) async {
    // Admin User
    final adminPass = sha256.convert(utf8.encode('admin123')).toString();
    await db.insert('users', {
      'username': 'admin',
      'email': 'admin@stockmaster.com',
      'passwordHash': adminPass,
      'role': 'admin'
    });

    // Employee User
    final userPass = sha256.convert(utf8.encode('employee123')).toString();
    await db.insert('users', {
      'username': 'employee',
      'email': 'employee@stockmaster.com',
      'passwordHash': userPass,
      'role': 'employee'
    });
  }

  Future<void> _seedCategories(Database db) async {
    final categories = ['General', 'Electronics', 'Clothing', 'Food', 'Furniture'];
    for (var cat in categories) {
      try {
        await db.insert('categories', {'name': cat});
      } catch (e) {
        // Ignore unique constraint error if re-running
      }
    }
  }

  Future<void> _seedRolesAndPermissions(Database db) async {
    // Roles
    try {
      await db.insert('roles', {'name': 'admin'});
      await db.insert('roles', {'name': 'employee'});
    } catch (e) {
      // Ignore
    }

    // Permissions
    final adminPerms = ['manage_products', 'manage_stock', 'view_reports', 'manage_users', 'manage_settings'];
    final employeePerms = ['manage_products', 'manage_stock'];

    for (var p in adminPerms) {
      try { await db.insert('role_permissions', {'role_name': 'admin', 'permission': p}); } catch(e){
        // Ignore
      }
    }
    for (var p in employeePerms) {
      try { await db.insert('role_permissions', {'role_name': 'employee', 'permission': p}); } catch(e){
        // Ignore
      }
    }
  }

  // --- Categories CRUD ---

  Future<int> createCategory(String name) async {
    final db = await instance.database;
    return await db.insert('categories', {'name': name});
  }

  Future<List<String>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => json['name'] as String).toList();
  }

  Future<int> deleteCategory(String name) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'name = ?', whereArgs: [name]);
  }

  // --- Users CRUD ---

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((json) => User.fromMap(json)).toList();
  }

  Future<int> createUser(User user, String password) async {
    final db = await instance.database;
    final passwordHash = sha256.convert(utf8.encode(password)).toString();
    return await db.insert('users', {
      'username': user.username,
      'email': user.email,
      'passwordHash': passwordHash,
      'role': user.role,
    });
  }

  Future<int> updateUser(User user, String? newPassword) async {
    final db = await instance.database;
    Map<String, dynamic> data = {
      'username': user.username,
      'email': user.email,
      'role': user.role,
    };
    if (newPassword != null && newPassword.isNotEmpty) {
      data['passwordHash'] = sha256.convert(utf8.encode(newPassword)).toString();
    }
    return await db.update('users', data, where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --- Roles & Permissions ---

  Future<List<String>> getAllRoles() async {
    final db = await instance.database;
    final result = await db.query('roles');
    return result.map((json) => json['name'] as String).toList();
  }

  Future<int> createRole(String name) async {
    final db = await instance.database;
    return await db.insert('roles', {'name': name});
  }

  Future<int> deleteRole(String name) async {
    final db = await instance.database;
    // Also delete permissions
    await db.delete('role_permissions', where: 'role_name = ?', whereArgs: [name]);
    return await db.delete('roles', where: 'name = ?', whereArgs: [name]);
  }

  Future<List<String>> getPermissionsForRole(String roleName) async {
    final db = await instance.database;
    final result = await db.query('role_permissions', where: 'role_name = ?', whereArgs: [roleName]);
    return result.map((json) => json['permission'] as String).toList();
  }

  Future<void> updateRolePermissions(String roleName, List<String> permissions) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('role_permissions', where: 'role_name = ?', whereArgs: [roleName]);
      for (var p in permissions) {
        await txn.insert('role_permissions', {'role_name': roleName, 'permission': p});
      }
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

  Future<Product?> getProductBySku(String sku) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: 'sku = ?',
      whereArgs: [sku],
    );

    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    } else {
      return null;
    }
  }

  // --- Movements / History ---

  Future<int> logMovement(StockMovement movement) async {
    final db = await instance.database;
    return await db.insert('movements', movement.toMap());
  }

  Future<List<StockMovement>> readAllMovements() async {
    final db = await instance.database;
    final result = await db.query('movements', orderBy: 'date DESC');
    return result.map((json) => StockMovement.fromMap(json)).toList();
  }

  // Top Sales: Sum quantity where type = OUT
  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT productId, productName, SUM(quantity) as totalSold
      FROM movements
      WHERE type = 'OUT'
      GROUP BY productId, productName
      ORDER BY totalSold DESC
      LIMIT 5
    ''');
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

  Future<User?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    } else {
      return null;
    }
  }
}