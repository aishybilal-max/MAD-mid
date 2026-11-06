import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import '../widgets.dart';
import 'task_card.dart';

class CompletedScreen extends StatelessWidget {
  const CompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.watch<AppState>().completed;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        children: [
          SectionTitle('Completed', sub: '${list.length} tasks completed'),
          const SizedBox(height: 20),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 50),
              child: EmptyState(
                icon: Icons.check_circle_outline_rounded,
                text: 'No task completed yet.\nTick your first task',
              ),
            )
          else
            for (final t in list) TaskCard(key: ValueKey('c${t.id}'), task: t),
        ],
      ),
    );
  }
}
