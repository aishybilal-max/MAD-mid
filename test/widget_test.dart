import 'package:flutter_test/flutter_test.dart';
import 'package:seaside_tasks/models.dart';

void main() {
  test('daily task reaches next day at the same time', () {
    final t = Task(
      title: 'Read',
      dueAt: DateTime(2026, 11, 5, 20, 0),
      repeat: RepeatType.daily,
    );
    final next = t.nextAfter(DateTime(2026, 11, 5));
    expect(next, DateTime(2026, 11, 6, 20, 0));
  });

  test('weekly task picks the next chosen weekday', () {
    final t = Task(
      title: 'Gym',
      dueAt: DateTime(2026, 11, 5, 18, 0), // Thursday
      repeat: RepeatType.weekly,
      repeatDays: [1, 4], // Mon, Thu
    );
    final next = t.nextAfter(DateTime(2026, 11, 5));
    expect(next.weekday, 1);
    expect(next, DateTime(2026, 11, 9, 18, 0));
  });

  test('subtask progress', () {
    final t = Task(
      title: 'Project',
      dueAt: DateTime.now(),
      subtasks: [Subtask(title: 'a', done: true), Subtask(title: 'b')],
    );
    expect(t.progress, 0.5);
  });
}
