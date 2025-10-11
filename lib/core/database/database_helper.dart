import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite database helper for Bajetimor app
/// Manages database creation, versioning, and table operations
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Database configuration
  static const String _databaseName = 'bajetimor.db';
  static const int _databaseVersion = 2;

  /// Table names
  static const String tableIncome = 'income';
  static const String tableExpenses = 'expenses';
  static const String tableInvestments = 'investments';
  static const String tableBudgets = 'budgets';
  static const String tableCategories = 'categories';
  static const String tableOutbox = 'outbox';

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Categories table
    await db.execute('''
      CREATE TABLE $tableCategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'investment')),
        icon TEXT,
        color TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Income table
    await db.execute('''
      CREATE TABLE $tableIncome (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $tableCategories (id)
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE $tableExpenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $tableCategories (id)
      )
    ''');

    // Investments table
    await db.execute('''
      CREATE TABLE $tableInvestments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER,
        date TEXT NOT NULL,
        expected_return REAL,
        current_value REAL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $tableCategories (id)
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE $tableBudgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL CHECK (period IN ('monthly', 'weekly', 'yearly')),
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $tableCategories (id)
      )
    ''');

    // Outbox table for sync
    await db.execute('''
      CREATE TABLE $tableOutbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        operation TEXT NOT NULL CHECK (operation IN ('insert','update','delete')),
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sent_at TEXT
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add new tables without dropping existing user data
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableOutbox (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entity TEXT NOT NULL,
          operation TEXT NOT NULL CHECK (operation IN ('insert','update','delete')),
          payload TEXT NOT NULL,
          created_at TEXT NOT NULL,
          sent_at TEXT
        )
      ''');
    }
  }

  /// Insert default categories
  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Income categories
    final incomeCategories = [
      {'name': 'Salary', 'type': 'income', 'icon': 'work', 'color': '#4CAF50'},
      {'name': 'Business', 'type': 'income', 'icon': 'business', 'color': '#2196F3'},
      {'name': 'Freelance', 'type': 'income', 'icon': 'laptop', 'color': '#FF9800'},
      {'name': 'Investment Returns', 'type': 'income', 'icon': 'trending_up', 'color': '#9C27B0'},
      {'name': 'Other Income', 'type': 'income', 'icon': 'attach_money', 'color': '#607D8B'},
    ];

    // Expense categories
    final expenseCategories = [
      {'name': 'Food & Dining', 'type': 'expense', 'icon': 'restaurant', 'color': '#F44336'},
      {'name': 'Transportation', 'type': 'expense', 'icon': 'directions_car', 'color': '#E91E63'},
      {'name': 'Shopping', 'type': 'expense', 'icon': 'shopping_cart', 'color': '#9C27B0'},
      {'name': 'Entertainment', 'type': 'expense', 'icon': 'movie', 'color': '#673AB7'},
      {'name': 'Bills & Utilities', 'type': 'expense', 'icon': 'receipt', 'color': '#3F51B5'},
      {'name': 'Healthcare', 'type': 'expense', 'icon': 'local_hospital', 'color': '#009688'},
      {'name': 'Education', 'type': 'expense', 'icon': 'school', 'color': '#4CAF50'},
      {'name': 'Travel', 'type': 'expense', 'icon': 'flight', 'color': '#FF5722'},
      {'name': 'Other Expenses', 'type': 'expense', 'icon': 'more_horiz', 'color': '#795548'},
    ];

    // Investment categories
    final investmentCategories = [
      {'name': 'Stocks', 'type': 'investment', 'icon': 'show_chart', 'color': '#4CAF50'},
      {'name': 'Bonds', 'type': 'investment', 'icon': 'account_balance', 'color': '#2196F3'},
      {'name': 'Real Estate', 'type': 'investment', 'icon': 'home', 'color': '#FF9800'},
      {'name': 'Cryptocurrency', 'type': 'investment', 'icon': 'currency_bitcoin', 'color': '#FF5722'},
      {'name': 'Mutual Funds', 'type': 'investment', 'icon': 'pie_chart', 'color': '#9C27B0'},
      {'name': 'Other Investments', 'type': 'investment', 'icon': 'trending_up', 'color': '#607D8B'},
    ];

    // Insert all categories
    for (final category in [...incomeCategories, ...expenseCategories, ...investmentCategories]) {
      await db.insert(tableCategories, {
        ...category,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing purposes)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Outbox helpers
  Future<int> addOutboxEntry({
    required String entity,
    required String operation,
    required String payload,
    DateTime? createdAt,
  }) async {
    final db = await database;
    final now = (createdAt ?? DateTime.now()).toIso8601String();
    return await db.insert(tableOutbox, {
      'entity': entity,
      'operation': operation,
      'payload': payload,
      'created_at': now,
      'sent_at': null,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOutbox(String entity) async {
    final db = await database;
    return await db.query(
      tableOutbox,
      where: 'entity = ? AND sent_at IS NULL',
      whereArgs: [entity],
      orderBy: 'created_at ASC',
    );
  }

  Future<int> markOutboxSent(int id) async {
    final db = await database;
    return await db.update(
      tableOutbox,
      {'sent_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}