import 'dart:convert';

enum RepeatType { none, daily, weekly, interval }

const List<String> kCategories = ['Academic', 'Personal', 'Work', 'Health', 'Errands'];

int dayNum(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class Subtask {
  int? id;
  int? taskId;
  String title;
  bool done;

  Subtask({this.id, this.taskId, required this.title, this.done = false});

  Subtask copy() => Subtask(title: title, done: done);

  Map<String, Object?> toMap() => {
        'id': id,
        'task_id': taskId,
        'title': title,
        'is_done': done ? 1 : 0,
      };

  factory Subtask.fromMap(Map<String, Object?> m) => Subtask(
        id: m['id'] as int?,
        taskId: m['task_id'] as int?,
        title: m['title'] as String,
        done: (m['is_done'] as int) == 1,
      );
}

class Task {
  int? id;
  String title;
  String description;
  DateTime dueAt;
  String category;
  bool completed;
  DateTime? completedAt;
  RepeatType repeat;
  List<int> repeatDays; // 1 = Monday ... 7 = Sunday
  int repeatInterval; // every N days (for RepeatType.interval)
  bool notify;
  List<Subtask> subtasks;

  Task({
    this.id,
    required this.title,
    this.description = '',
    required this.dueAt,
    this.category = 'Personal',
    this.completed = false,
    this.completedAt,
    this.repeat = RepeatType.none,
    List<int>? repeatDays,
    this.repeatInterval = 2,
    this.notify = true,
    List<Subtask>? subtasks,
  })  : repeatDays = repeatDays ?? [],
        subtasks = subtasks ?? [];

  bool get isRepeating => repeat != RepeatType.none;

  double get progress {
    if (subtasks.isEmpty) return completed ? 1 : 0;
    return subtasks.where((s) => s.done).length / subtasks.length;
  }

  String get repeatLabel {
    switch (repeat) {
      case RepeatType.none:
        return 'Once';
      case RepeatType.daily:
        return 'Every day';
      case RepeatType.weekly:
        const n = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final days = [...repeatDays]..sort();
        return days.map((d) => n[d - 1]).join(', ');
      case RepeatType.interval:
        return 'Every $repeatInterval days';
    }
  }

  /// Does this (active) task fall on [day]?
  bool occursOn(DateTime day) {
    final d = dayNum(day);
    final due = dayNum(dueAt);
    switch (repeat) {
      case RepeatType.none:
        return d == due;
      case RepeatType.daily:
        return d >= due;
      case RepeatType.weekly:
        return d >= due && repeatDays.contains(day.weekday);
      case RepeatType.interval:
        final n = repeatInterval < 1 ? 1 : repeatInterval;
        return d >= due && (d - due) % n == 0;
    }
  }

  /// First valid date for a repeating task, on or after [from].
  DateTime firstOccurrence(DateTime from) {
    var d = DateTime(from.year, from.month, from.day, dueAt.hour, dueAt.minute);
    if (repeat == RepeatType.weekly && repeatDays.isNotEmpty) {
      for (var i = 0; i < 8; i++) {
        if (repeatDays.contains(d.weekday)) break;
        d = DateTime(d.year, d.month, d.day + 1, dueAt.hour, dueAt.minute);
      }
    }
    return d;
  }

  /// Next due date strictly after [after] (used after completing a repeat task).
  DateTime nextAfter(DateTime after) {
    final h = dueAt.hour, m = dueAt.minute;
    switch (repeat) {
      case RepeatType.none:
        return dueAt;
      case RepeatType.daily:
        return DateTime(after.year, after.month, after.day + 1, h, m);
      case RepeatType.interval:
        final n = repeatInterval < 1 ? 1 : repeatInterval;
        return DateTime(after.year, after.month, after.day + n, h, m);
      case RepeatType.weekly:
        for (var i = 1; i <= 7; i++) {
          final c = DateTime(after.year, after.month, after.day + i, h, m);
          if (repeatDays.contains(c.weekday)) return c;
        }
        return DateTime(after.year, after.month, after.day + 7, h, m);
    }
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'due_at': dueAt.millisecondsSinceEpoch,
        'category': category,
        'is_completed': completed ? 1 : 0,
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'repeat_type': repeat.index,
        'repeat_days': jsonEncode(repeatDays),
        'repeat_interval': repeatInterval,
        'notify': notify ? 1 : 0,
      };

  factory Task.fromMap(Map<String, Object?> m, List<Subtask> subs) => Task(
        id: m['id'] as int?,
        title: m['title'] as String,
        description: (m['description'] as String?) ?? '',
        dueAt: DateTime.fromMillisecondsSinceEpoch(m['due_at'] as int),
        category: (m['category'] as String?) ?? 'Personal',
        completed: (m['is_completed'] as int) == 1,
        completedAt: m['completed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int),
        repeat: RepeatType.values[m['repeat_type'] as int],
        repeatDays: List<int>.from(jsonDecode(m['repeat_days'] as String) as List),
        repeatInterval: m['repeat_interval'] as int,
        notify: (m['notify'] as int) == 1,
        subtasks: subs,
      );
}
