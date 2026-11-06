import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'add_edit_screen.dart';
import 'completed_screen.dart';
import 'repeated_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _dialogOpen = false;

  Future<void> _showRing(Task t) async {
    final app = context.read<AppState>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(children: [
          const Icon(Icons.alarm_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text(t.title, style: celestial(18, bold: true))),
        ]),
        content: Text(t.description.isEmpty ? 'It is time for this task' : t.description),
        actions: [
          TextButton(
            onPressed: () {
              app.stopRinging();
              Navigator.pop(c);
            },
            child: const Text('Dismiss'),
          ),
          if ((t.id ?? 0) > 0)
            FilledButton(
              onPressed: () {
                app.stopRinging();
                app.toggleComplete(t);
                Navigator.pop(c);
              },
              child: const Text('Mark done'),
            ),
        ],
      ),
    );
    _dialogOpen = false;
  }

  static const _items = [
    (Icons.wb_sunny_rounded, 'Today'),
    (Icons.autorenew_rounded, 'Repeated'),
    (Icons.check_circle_rounded, 'Done'),
    (Icons.tune_rounded, 'Settings'),
  ];

  static const _bg = [
    ('assets/images/gingham_blue.jpg', 'assets/images/swirl.jpg'),
    ('assets/images/gingham_green.jpg', 'assets/images/butterfly.jpg'),
    ('assets/images/foam.jpg', 'assets/images/umbrella.jpg'),
    ('assets/images/sea_text.jpg', 'assets/images/swirl.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    final loaded = context.select<AppState, bool>((s) => s.loaded);
    final ringing = context.select<AppState, Task?>((s) => s.ringing);
    if (ringing != null && !_dialogOpen) {
      _dialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRing(ringing);
      });
    }
    final dark = isDark(context);
    final scheme = Theme.of(context).colorScheme;

    final pages = const [TodayScreen(), RepeatedScreen(), CompletedScreen(), SettingsScreen()];

    return Scaffold(
      extendBody: true,
      body: SparkleBackground(
        lightImage: _bg[_tab].$1,
        darkImage: _bg[_tab].$2,
        child: loaded
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Pressable(
        hoverScale: 1.1,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditScreen()),
        ),
        builder: (hover) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, C.seaGreen],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(hover ? 0.75 : 0.45),
                blurRadius: hover ? 30 : 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, size: 34, color: dark ? C.night : Colors.white),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: (dark ? C.navy : Colors.white).withOpacity(dark ? 0.55 : 0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(dark ? 0.15 : 0.7)),
              ),
              child: Row(children: [
                _nav(0, scheme),
                _nav(1, scheme),
                const SizedBox(width: 64), // space for the + button
                _nav(2, scheme),
                _nav(3, scheme),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(int i, ColorScheme scheme) {
    final sel = _tab == i;
    return Expanded(
      child: Pressable(
        hoverScale: 1.1,
        onTap: () => setState(() => _tab = i),
        builder: (hover) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: sel
                  ? scheme.primary.withOpacity(0.22)
                  : (hover ? scheme.primary.withOpacity(0.1) : Colors.transparent),
            ),
            child: Icon(_items[i].$1,
                size: 24, color: sel ? scheme.primary : scheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 2),
          Text(_items[i].$2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: sel ? scheme.primary : scheme.onSurface.withOpacity(0.6),
              )),
        ]),
      ),
    );
  }
}
