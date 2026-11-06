import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'task_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime _selected = dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = dateOnly(now);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final week = List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));

    final list = app.forDay(_selected);
    final isToday = _selected == today;

    final pending = app.forDay(today).length;
    final done = app.doneToday;
    final total = pending + done;
    final pct = total == 0 ? 0.0 : done / total;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        children: [
          SectionTitle(
            isToday ? 'Today' : DateFormat('EEEE').format(_selected),
            sub: DateFormat('d MMMM yyyy').format(_selected),
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: Row(children: [
              ProgressRing(
                value: pct,
                center: Text('${(pct * 100).round()}%',
                    style: celestial(17, color: scheme.onSurface, bold: true, spacing: 0)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    total == 0
                        ? 'Today is empty'
                        : (pending == 0 ? 'All done!' : '$pending left, $done completed'),
                    style: celestial(15, color: scheme.onSurface, bold: true, spacing: 0.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    total == 0
                        ? 'Tap + below and add a new task.'
                        : 'Take small steps, keep flowing like the sea.',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 78,
            child: Row(children: [
              for (final d in week)
                Expanded(
                  child: Pressable(
                    hoverScale: 1.08,
                    onTap: () => setState(() => _selected = d),
                    builder: (hover) {
                      final sel = d == _selected;
                      final has = app.hasTasksOn(d);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: sel
                              ? scheme.primary
                              : scheme.primary.withOpacity(hover ? 0.22 : 0.08),
                          boxShadow: sel
                              ? [BoxShadow(color: scheme.primary.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 5))]
                              : null,
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(DateFormat('E').format(d).substring(0, 2),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: sel ? scheme.onPrimary : scheme.onSurface.withOpacity(0.7),
                              )),
                          const SizedBox(height: 4),
                          Text('${d.day}',
                              style: celestial(17,
                                  color: sel ? scheme.onPrimary : scheme.onSurface,
                                  bold: true,
                                  spacing: 0)),
                          const SizedBox(height: 4),
                          Icon(Icons.circle,
                              size: 6,
                              color: has
                                  ? (sel ? scheme.onPrimary : C.seaGreen)
                                  : Colors.transparent),
                        ]),
                      );
                    },
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 18),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: EmptyState(
                icon: Icons.water_drop_outlined,
                text: 'No tasks on this day.\nRelax or add a new task.',
              ),
            )
          else
            for (final t in list) TaskCard(key: ValueKey('t${t.id}'), task: t),
        ],
      ),
    );
  }
}
