import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('light_meter.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 测量记录表
    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lux REAL NOT NULL,
        cct REAL NOT NULL,
        calibration_factor REAL,
        device_model TEXT,
        created_at INTEGER NOT NULL,
        note TEXT
      )
    ''');

    // 校准配置表
    await db.execute('''
      CREATE TABLE calibration_configs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        factor REAL NOT NULL,
        reference_lux REAL,
        is_default INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // 创建默认校准配置
    await db.insert('calibration_configs', {
      'name': '默认',
      'factor': 1.0,
      'is_default': 1,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}