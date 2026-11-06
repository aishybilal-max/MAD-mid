import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// SQLite storage: two tables, `tasks` and `subtasks` (one-to-many).
class AppDb {
  static Database? _db;

  static Future<Database> get db async => _db ??= await _open();

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'seaside_tasks.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (d) async => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            due_at INTEGER NOT NULL,
            category TEXT,
            is_completed INTEGER NOT NULL DEFAULT 0,
            completed_at INTEGER,
            repeat_type INTEGER NOT NULL DEFAULT 0,
            repeat_days TEXT NOT NULL DEFAULT '[]',
            repeat_interval INTEGER NOT NULL DEFAULT 2,
            notify INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await d.execute('''
          CREATE TABLE subtasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            is_done INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  static Future<List<Task>> allTasks() async {
    final d = await db;
    final rows = await d.query('tasks', orderBy: 'due_at ASC');
    final subRows = await d.query('subtasks', orderBy: 'id ASC');
    final byTask = <int, List<Subtask>>{};
    for (final r in subRows) {
      final s = Subtask.fromMap(r);
      byTask.putIfAbsent(s.taskId!, () => []).add(s);
    }
    return rows
        .map((r) => Task.fromMap(r, byTask[r['id'] as int] ?? []))
        .toList();
  }

  static Future<int> insert(Task t) async {
    final d = await db;
    return d.transaction((txn) async {
      final map = t.toMap()..remove('id');
      final id = await txn.insert('tasks', map);
      for (final s in t.subtasks) {
        final sm = s.toMap()
          ..remove('id')
          ..['task_id'] = id;
        await txn.insert('subtasks', sm);
      }
      return id;
    });
  }

  static Future<void> update(Task t) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.update('tasks', t.toMap()..remove('id'),
          where: 'id = ?', whereArgs: [t.id]);
      await txn.delete('subtasks', where: 'task_id = ?', whereArgs: [t.id]);
      for (final s in t.subtasks) {
        final sm = s.toMap()
          ..remove('id')
          ..['task_id'] = t.id;
        await txn.insert('subtasks', sm);
      }
    });
  }

  static Future<void> delete(int id) async {
    final d = await db;
    await d.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
