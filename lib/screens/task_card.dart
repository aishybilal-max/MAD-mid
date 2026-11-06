import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'add_edit_screen.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool dismissible;
  const TaskCard({super.key, required this.task, this.dismissible = true});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final catColor = categoryColor(task.category);
    final overdue = !task.completed &&
        !task.isRepeating &&
        dateOnly(task.dueAt).isBefore(dateOnly(DateTime.now()));

    final card = Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditScreen(task: task)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _CheckCircle(
              done: task.completed,
              color: catColor,
              onTap: () => app.toggleComplete(task),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                    color: scheme.onSurface.withOpacity(task.completed ? 0.55 : 1),
                  ),
                ),
                if (task.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurface.withOpacity(0.65))),
                  ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(categoryIcon(task.category), size: 18, color: catColor),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _Pill(
              icon: Icons.schedule_rounded,
              text: task.completed && task.completedAt != null
                  ? 'Done ${DateFormat('d MMM, h:mm a').format(task.completedAt!)}'
                  : (dateOnly(task.dueAt) == dateOnly(DateTime.now())
                      ? DateFormat('h:mm a').format(task.dueAt)
                      : DateFormat('d MMM, h:mm a').format(task.dueAt)),
              color: overdue ? scheme.error : scheme.primary,
            ),
            if (task.isRepeating)
              _Pill(icon: Icons.autorenew_rounded, text: task.repeatLabel, color: C.seaGreen),
            if (task.notify && !task.completed)
              _Pill(icon: Icons.notifications_active_rounded, text: 'Reminder', color: C.leaf),
            if (overdue) _Pill(icon: Icons.warning_amber_rounded, text: 'Overdue', color: scheme.error),
          ]),
          if (task.subtasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: task.progress),
                    duration: const Duration(milliseconds: 500),
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 9,
                      color: catColor,
                      backgroundColor: catColor.withOpacity(0.18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${(task.progress * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            for (final s in task.subtasks)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: task.completed ? null : () => app.toggleSubtask(task, s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Icon(
                      s.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: s.done ? catColor : scheme.onSurface.withOpacity(0.45),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.title,
                          style: TextStyle(
                            decoration: s.done ? TextDecoration.lineThrough : null,
                            color: scheme.onSurface.withOpacity(s.done ? 0.5 : 0.9),
                          )),
                    ),
                  ]),
                ),
              ),
          ],
        ]),
      ),
    );

    if (!dismissible) return card;
    return Dismissible(
      key: ValueKey('task_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 26),
        decoration: BoxDecoration(
          color: scheme.error.withOpacity(0.85),
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 30),
      ),
      onDismissed: (_) {
        final backup = Task(
          title: task.title,
          description: task.description,
          dueAt: task.dueAt,
          category: task.category,
          completed: task.completed,
          completedAt: task.completedAt,
          repeat: task.repeat,
          repeatDays: [...task.repeatDays],
          repeatInterval: task.repeatInterval,
          notify: task.notify,
          subtasks: task.subtasks.map((s) => Subtask(title: s.title, done: s.done)).toList(),
        );
        app.remove(task);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: const Text('Task deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: C.sky,
              onPressed: () => app.restore(backup),
            ),
          ));
      },
      child: card,
    );
  }
}

class _CheckCircle extends StatelessWidget {
  final bool done;
  final Color color;
  final VoidCallback onTap;
  const _CheckCircle({required this.done, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      hoverScale: 1.15,
      builder: (hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? color : color.withOpacity(hover ? 0.22 : 0.0),
          border: Border.all(color: color, width: 2.2),
          boxShadow: done || hover
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 12)]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: done
              ? const Icon(Icons.check_rounded, key: ValueKey(1), size: 20, color: Colors.white)
              : const SizedBox(key: ValueKey(0)),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Pill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
