import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // ✅ Create Database
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            isDone INTEGER NOT NULL,
            dueDate TEXT )''');},
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {await db.execute('ALTER TABLE tasks ADD COLUMN dueDate TEXT;');}
      },
    );
  }

  // 🟢 Insert Task ( With Duplicate Check)
  Future<int> insertTask(Task task) async {
    final db = await database;

    final existing = await db.query(
      'tasks',
      where: 'title = ? AND dueDate = ?',
      whereArgs: [task.title, task.dueDate]);

    if (existing.isNotEmpty) {
      throw Exception('Duplicate task found');
    }

    return await db.insert('tasks', task.toMap());
  }

  // 🟢 Get All Tasks (New First)
  Future<List<Task>> getTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // 🟢 Update Task
  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // 🟢 Delete Task
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
