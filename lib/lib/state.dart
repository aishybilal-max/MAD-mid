import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm.dart';
import 'db.dart';
import 'models.dart';
import 'notifications.dart';

class AppState extends ChangeNotifier {
  List<Task> tasks = [];
  ThemeMode themeMode = ThemeMode.system;
  String sound = 'dragon';
  bool loaded = false;
  Task? ringing; // task whose reminder is ringing right now (in-app alarm)
  Timer? _watcher;
  final Set<String> _fired = {};
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values[_prefs.getInt('theme') ?? 0];
    sound = _prefs.getString('sound') ?? 'dragon';
    // FIX: if notifications init fails, do not stop the whole app init
    try {
      await Notifier.init();
    } catch (e) {
      debugPrint('Notifier.init failed: $e');
    }
    try {
      tasks = await AppDb.allTasks();
    } catch (_) {
      tasks = [];
    }
    loaded = true;
    notifyListeners();
    _watcher = Timer.periodic(const Duration(seconds: 10), (_) => _checkDue());
    for (final t in tasks) {
      await _schedule(t);
    }
  }

  /// FIX: reminders are cancelled for completed / notify-off tasks,
  /// and one task's error does not stop the rest.
  Future<void> _schedule(Task t) async {
    try {
      if (t.completed || !t.notify) {
        if (t.id != null) await Notifier.cancelFor(t.id!);
        return;
      }
      await Notifier.schedule(t, sound);
    } catch (e) {
      debugPrint('Notification schedule failed: $e');
    }
  }

  // ---------- in-app alarm ----------
  void _checkDue() {
    if (ringing != null) return;
    final now = DateTime.now();
    for (final t in tasks) {
      if (t.completed || !t.notify) continue;
      DateTime? occ;
      if (t.isRepeating) {
        if (t.occursOn(now)) {
          occ = DateTime(now.year, now.month, now.day, t.dueAt.hour, t.dueAt.minute);
        }
      } else {
        occ = t.dueAt;
      }
      if (occ == null) continue;
      final diff = now.difference(occ);
      if (diff.inSeconds >= 0 && diff.inMinutes < 2) {
        if (_fired.add('${t.id}@${occ.millisecondsSinceEpoch}')) {
          _ring(t);
          break;
        }
      }
    }
  }

  void _ring(Task t) {
    ringing = t;
    Alarm.play(sound);
    notifyListeners();
  }

  void stopRinging() {
    ringing = null;
    Alarm.stop();
    notifyListeners();
  }

  /// Rings the in-app alarm 10 seconds from now (for testing).
  void testAlarmIn10s() {
    Timer(const Duration(seconds: 10), () {
      _ring(Task(id: -1, title: 'Test alarm', description: 'The alarm sound and reminder dialog are working.', dueAt: DateTime.now()));
    });
  }

  @override
  void dispose() {
    _watcher?.cancel();
    super.dispose();
  }

  // ---------- settings ----------
  void setTheme(ThemeMode m) {
    themeMode = m;
    _prefs.setInt('theme', m.index);
    notifyListeners();
  }

  Future<void> setSound(String s) async {
    sound = s;
    _prefs.setString('sound', s);
    notifyListeners();
    for (final t in tasks.where((t) => !t.completed)) {
      await _schedule(t);
    }
  }

  // ---------- queries ----------
  List<Task> forDay(DateTime day) {
    final today = dateOnly(DateTime.now());
    final d = dateOnly(day);
    final list = tasks.where((t) {
      if (t.completed) return false;
      if (t.occursOn(d)) return true;
      // overdue one-time tasks stay visible on "today"
      return d == today && !t.isRepeating && dateOnly(t.dueAt).isBefore(today);
    }).toList();
    list.sort((a, b) => (a.dueAt.hour * 60 + a.dueAt.minute)
        .compareTo(b.dueAt.hour * 60 + b.dueAt.minute));
    return list;
  }

  List<Task> get repeated => tasks.where((t) => !t.completed && t.isRepeating).toList();

  List<Task> get completed {
    final l = tasks.where((t) => t.completed).toList();
    l.sort((a, b) => (b.completedAt ?? b.dueAt).compareTo(a.completedAt ?? a.dueAt));
    return l;
  }

  int get doneToday => tasks
      .where((t) => t.completed && t.completedAt != null && sameDay(t.completedAt!, DateTime.now()))
      .length;

  bool hasTasksOn(DateTime day) => tasks.any((t) => !t.completed && t.occursOn(day));

  // ---------- commands ----------
  Future<void> add(Task t) async {
    t.id = await AppDb.insert(t);
    tasks = await AppDb.allTasks();
    notifyListeners();
    await _schedule(tasks.firstWhere((x) => x.id == t.id));
  }

  Future<void> save(Task t) async {
    await AppDb.update(t);
    tasks = await AppDb.allTasks();
    notifyListeners();
    await _schedule(tasks.firstWhere((x) => x.id == t.id));
  }

  Future<void> remove(Task t) async {
    if (t.id == null) return;
    // remove from memory first so the swiped Dismissible leaves the tree immediately
    tasks = tasks.where((x) => x.id != t.id).toList();
    notifyListeners();
    try {
      await Notifier.cancelFor(t.id!);
    } catch (e) {
      debugPrint('cancel failed: $e');
    }
    await AppDb.delete(t.id!);
    tasks = await AppDb.allTasks();
    notifyListeners();
  }

  /// Put a deleted task back (Undo).
  Future<void> restore(Task t) async {
    t.id = null;
    await add(t);
  }

  Future<void> toggleSubtask(Task t, Subtask s) async {
    s.done = !s.done;
    await save(t);
  }

  /// Mark complete / un-complete.
  /// Repeating tasks: a finished copy goes to "Completed" and the original
  /// automatically resets to its next due date with subtasks cleared.
  Future<void> toggleComplete(Task t) async {
    if (t.completed) {
      t.completed = false;
      t.completedAt = null;
      await save(t);
      return;
    }
    final now = DateTime.now();
    if (t.isRepeating) {
      final copy = Task(
        title: t.title,
        description: t.description,
        dueAt: t.dueAt,
        category: t.category,
        completed: true,
        completedAt: now,
        notify: false,
        subtasks: t.subtasks.map((s) => Subtask(title: s.title, done: true)).toList(),
      );
      await AppDb.insert(copy);
      final after = dayNum(t.dueAt) > dayNum(now) ? t.dueAt : now;
      t.dueAt = t.nextAfter(after);
      for (final s in t.subtasks) {
        s.done = false;
      }
      await save(t);
    } else {
      t.completed = true;
      t.completedAt = now;
      for (final s in t.subtasks) {
        s.done = true;
      }
      await save(t);
    }
  }
}
