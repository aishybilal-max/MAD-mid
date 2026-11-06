import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class AddEditScreen extends StatefulWidget {
  final Task? task;
  const AddEditScreen({super.key, this.task});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _sub = TextEditingController();
  late DateTime _date;
  late TimeOfDay _time;
  String _category = 'Personal';
  RepeatType _repeat = RepeatType.none;
  final Set<int> _days = {};
  int _interval = 2;
  bool _notify = true;
  List<Subtask> _subs = [];
  String? _error;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t == null) {
      final n = DateTime.now().add(const Duration(hours: 1));
      _date = dateOnly(n);
      _time = TimeOfDay(hour: n.hour, minute: 0);
    } else {
      _title.text = t.title;
      _desc.text = t.description;
      _date = dateOnly(t.dueAt);
      _time = TimeOfDay(hour: t.dueAt.hour, minute: t.dueAt.minute);
      _category = t.category;
      _repeat = t.repeat;
      _days.addAll(t.repeatDays);
      _interval = t.repeatInterval;
      _notify = t.notify;
      _subs = t.subtasks.map((s) => Subtask(title: s.title, done: s.done)).toList();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _sub.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  void _addSub() {
    final v = _sub.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _subs.add(Subtask(title: v));
      _sub.clear();
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }
    if (_repeat == RepeatType.weekly && _days.isEmpty) {
      setState(() => _error = 'Select at least one day');
      return;
    }
    final app = context.read<AppState>();
    var due = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final task = Task(
      id: widget.task?.id,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      dueAt: due,
      category: _category,
      completed: widget.task?.completed ?? false,
      completedAt: widget.task?.completedAt,
      repeat: _repeat,
      repeatDays: _days.toList()..sort(),
      repeatInterval: _interval,
      notify: _notify,
      subtasks: _subs,
    );
    if (_repeat == RepeatType.weekly) task.dueAt = task.firstOccurrence(_date);
    try {
      if (_editing) {
        await app.save(task);
      } else {
        await app.add(task);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('Could not save task: $e')));
      }
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This task will be deleted forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppState>().remove(widget.task!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: Text(t, style: celestial(15, color: scheme.onSurface, bold: true)),
        );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_editing ? 'Edit Task' : 'New Task',
            style: celestial(21, color: scheme.onSurface, bold: true)),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Delete',
              onPressed: _delete,
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
        ],
      ),
      body: SparkleBackground(
        lightImage: 'assets/images/gingham_blue.jpg',
        darkImage: 'assets/images/swirl.jpg',
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 64, 20, 40),
            children: [
              GlassCard(
                child: Column(children: [
                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      errorText: _error,
                      prefixIcon: const Icon(Icons.auto_awesome_rounded),
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _desc,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ]),
              ),
              label('Due date & time'),
              Row(children: [
                Expanded(
                  child: GlowButton(
                    icon: Icons.calendar_month_rounded,
                    label: DateFormat('d MMM yyyy').format(_date),
                    outlined: true,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlowButton(
                    icon: Icons.schedule_rounded,
                    label: _time.format(context),
                    outlined: true,
                    onTap: _pickTime,
                  ),
                ),
              ]),
              label('Category'),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final c in kCategories)
                  GlowChip(
                    label: c,
                    icon: categoryIcon(c),
                    color: categoryColor(c),
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ]),
              label('Repeat'),
              Wrap(spacing: 10, runSpacing: 10, children: [
                GlowChip(label: 'Once', selected: _repeat == RepeatType.none,
                    onTap: () => setState(() => _repeat = RepeatType.none)),
                GlowChip(label: 'Daily', selected: _repeat == RepeatType.daily,
                    onTap: () => setState(() => _repeat = RepeatType.daily)),
                GlowChip(label: 'Weekdays', selected: _repeat == RepeatType.weekly,
                    onTap: () => setState(() => _repeat = RepeatType.weekly)),
                GlowChip(label: 'Every N days', selected: _repeat == RepeatType.interval,
                    onTap: () => setState(() => _repeat = RepeatType.interval)),
              ]),
              if (_repeat == RepeatType.weekly) ...[
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  for (var i = 1; i <= 7; i++)
                    Pressable(
                      hoverScale: 1.12,
                      onTap: () => setState(() => _days.contains(i) ? _days.remove(i) : _days.add(i)),
                      builder: (hover) => AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _days.contains(i)
                              ? scheme.primary
                              : scheme.primary.withOpacity(hover ? 0.25 : 0.1),
                          boxShadow: _days.contains(i)
                              ? [BoxShadow(color: scheme.primary.withOpacity(0.5), blurRadius: 12)]
                              : null,
                        ),
                        child: Text(dayNames[i - 1],
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _days.contains(i) ? scheme.onPrimary : scheme.onSurface,
                            )),
                      ),
                    ),
                ]),
              ],
              if (_repeat == RepeatType.interval) ...[
                const SizedBox(height: 14),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    const Expanded(
                        child: Text('Repeat every', style: TextStyle(fontWeight: FontWeight.w700))),
                    IconButton(
                      onPressed: _interval > 1 ? () => setState(() => _interval--) : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text('$_interval days', style: celestial(15, color: scheme.onSurface, bold: true, spacing: 0)),
                    IconButton(
                      onPressed: _interval < 60 ? () => setState(() => _interval++) : null,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ]),
                ),
              ],
              label('Reminder'),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notify me at due time',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  secondary: Icon(Icons.notifications_active_rounded, color: scheme.primary),
                  value: _notify,
                  onChanged: (v) => setState(() => _notify = v),
                ),
              ),
              label('Subtasks'),
              GlassCard(
                child: Column(children: [
                  for (var i = 0; i < _subs.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _subs[i].done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: scheme.primary,
                      ),
                      title: Text(_subs[i].title),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _subs.removeAt(i)),
                      ),
                      onTap: () => setState(() => _subs[i].done = !_subs[i].done),
                    ),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _sub,
                        onSubmitted: (_) => _addSub(),
                        decoration: const InputDecoration(
                          hintText: 'Add a small step…',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GlowButton(icon: Icons.add_rounded, compact: true, onTap: _addSub),
                  ]),
                ]),
              ),
              const SizedBox(height: 28),
              GlowButton(
                icon: Icons.check_rounded,
                label: _editing ? 'Save changes' : 'Create task',
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
