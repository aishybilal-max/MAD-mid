import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../export.dart';
import '../notifications.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    Widget head(String t, IconData i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Icon(i, color: scheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(t, style: celestial(16, color: scheme.onSurface, bold: true)),
          ]),
        );

    void toast(String msg, {int seconds = 6}) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: seconds)));
    }

    Future<void> run(Future<void> Function() job) async {
      if (app.tasks.isEmpty) {
        toast('Add a task first, then export.', seconds: 4);
        return;
      }
      try {
        await job();
      } catch (e) {
        toast('Export failed: $e');
      }
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        children: [
          const SectionTitle('Settings', sub: 'as free as the sea.'),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              head('Theme', Icons.brightness_6_rounded),
              Wrap(spacing: 10, runSpacing: 10, children: [
                GlowChip(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  selected: app.themeMode == ThemeMode.light,
                  onTap: () => app.setTheme(ThemeMode.light),
                ),
                GlowChip(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  selected: app.themeMode == ThemeMode.dark,
                  onTap: () => app.setTheme(ThemeMode.dark),
                ),
                GlowChip(
                  label: 'System',
                  icon: Icons.phone_android_rounded,
                  selected: app.themeMode == ThemeMode.system,
                  onTap: () => app.setTheme(ThemeMode.system),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              head('Notification sound', Icons.music_note_rounded),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final e in kSounds.entries)
                  GlowChip(
                    label: e.value,
                    selected: app.sound == e.key,
                    onTap: () => app.setSound(e.key),
                  ),
              ]),
              const SizedBox(height: 14),
              GlowButton(
                icon: Icons.notifications_active_rounded,
                label: 'Send test notification',
                outlined: true,
                compact: true,
                onTap: () async {
                  final msg = await Notifier.showTest(app.sound);
                  toast(msg, seconds: 8);
                },
              ),
              const SizedBox(height: 10),
              GlowButton(
                icon: Icons.timer_rounded,
                label: 'Test in 10 seconds',
                outlined: true,
                compact: true,
                onTap: () async {
                  app.testAlarmIn10s();
                  final msg = await Notifier.scheduleTest(app.sound);
                  toast(msg, seconds: 8);
                },
              ),
            ]),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              head('Export tasks', Icons.ios_share_rounded),
              Text('${app.tasks.length} tasks will be exported (pending + completed).',
                  style: TextStyle(color: scheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10, children: [
                GlowButton(
                  icon: Icons.table_chart_rounded,
                  label: 'CSV',
                  compact: true,
                  onTap: () => run(() => Exporter.shareCsv(app.tasks)),
                ),
                GlowButton(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'PDF',
                  compact: true,
                  color: C.leaf,
                  onTap: () => run(() => Exporter.sharePdf(app.tasks)),
                ),
                GlowButton(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  compact: true,
                  color: C.navy,
                  onTap: () => run(() => Exporter.email(app.tasks)),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Row(children: [
              Icon(Icons.auto_awesome, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Seaside Tasks v1.0 - Flutter + SQLite',
                    style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface.withOpacity(0.8))),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
