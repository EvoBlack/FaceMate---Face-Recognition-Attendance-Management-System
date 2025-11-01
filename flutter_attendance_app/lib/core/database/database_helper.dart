import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../config/app_config.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = path.join(await getDatabasesPath(), AppConfig.dbName);
    return await openDatabase(
      dbPath,
      version: AppConfig.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE face_encodings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        encoding TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertFaceEncoding(Map<String, dynamic> encoding) async {
    final db = await database;
    return await db.insert('face_encodings', encoding);
  }

  Future<List<Map<String, dynamic>>> getFaceEncodings() async {
    final db = await database;
    return await db.query('face_encodings');
  }

  Future<int> insertAttendanceCache(Map<String, dynamic> attendance) async {
    final db = await database;
    return await db.insert('attendance_cache', attendance);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedAttendance() async {
    final db = await database;
    return await db.query('attendance_cache', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markAttendanceSynced(int id) async {
    final db = await database;
    await db.update(
      'attendance_cache',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}