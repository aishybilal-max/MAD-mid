import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import '../widgets.dart';
import 'task_card.dart';

class RepeatedScreen extends StatelessWidget {
  const RepeatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.watch<AppState>().repeated;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        children: [
          const SectionTitle('Repeated', sub: 'Tasks that repeat daily, weekly or every N days'),
          const SizedBox(height: 20),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 50),
              child: EmptyState(
                icon: Icons.autorenew_rounded,
                text: 'No repeating tasks.\nChoose Repeat when adding a task.',
              ),
            )
          else
            for (final t in list) TaskCard(key: ValueKey('r${t.id}'), task: t),
        ],
      ),
    );
  }
}
