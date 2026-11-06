import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'theme.dart';

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

// ───────────────────────── background with twinkling stars ─────────────────────────

class SparkleBackground extends StatefulWidget {
  final String lightImage;
  final String darkImage;
  final Widget child;
  const SparkleBackground({
    super.key,
    required this.lightImage,
    required this.darkImage,
    required this.child,
  });

  @override
  State<SparkleBackground> createState() => _SparkleBackgroundState();
}

class _SparkleBackgroundState extends State<SparkleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Image.asset(
            dark ? widget.darkImage : widget.lightImage,
            key: ValueKey('${dark}_${widget.lightImage}'),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // soft veil so cards and text stay readable
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark
                  ? [C.night.withOpacity(0.78), C.night.withOpacity(0.92)]
                  : [Colors.white.withOpacity(0.55), const Color(0xFFDDEFF5).withOpacity(0.82)],
            ),
          ),
        ),
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _StarPainter(_c, dark)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _StarPainter extends CustomPainter {
  final Animation<double> anim;
  final bool dark;
  static final _rnd = math.Random(7);
  static final List<List<double>> _stars =
      List.generate(34, (_) => [_rnd.nextDouble(), _rnd.nextDouble(), _rnd.nextDouble(), 3 + _rnd.nextDouble() * 6]);

  _StarPainter(this.anim, this.dark) : super(repaint: anim);

  Path _star(Offset c, double r) {
    final p = Path()..moveTo(c.dx, c.dy - r);
    p.quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy);
    p.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r);
    p.quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy);
    p.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final t = (math.sin((anim.value + s[2]) * 2 * math.pi) + 1) / 2;
      final paint = Paint()
        ..color = (dark ? Colors.white : C.ocean).withOpacity(0.10 + 0.55 * t)
        ..style = PaintingStyle.fill;
      canvas.drawPath(_star(Offset(s[0] * size.width, s[1] * size.height), s[3] * (0.6 + 0.6 * t)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.dark != dark;
}

// ───────────────────────── hover / press helpers ─────────────────────────

class Pressable extends StatefulWidget {
  final Widget Function(bool hovered) builder;
  final VoidCallback? onTap;
  final double hoverScale;
  const Pressable({super.key, required this.builder, this.onTap, this.hoverScale = 1.03});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hover = false, _down = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.95 : (_hover ? widget.hoverScale : 1),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: widget.builder(_hover),
        ),
      ),
    );
  }
}

/// Frosted-glass card that lifts and glows on hover.
class GlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? tint;
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.tint,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final tint = widget.tint ?? (dark ? Colors.white : Colors.white);
    final radius = BorderRadius.circular(26);
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: (dark ? C.sky : C.ocean).withOpacity(_hover ? 0.38 : 0.12),
                blurRadius: _hover ? 26 : 14,
                offset: Offset(0, _hover ? 10 : 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: tint.withOpacity(dark ? (_hover ? 0.16 : 0.10) : (_hover ? 0.88 : 0.72)),
                  border: Border.all(
                    color: (dark ? C.sky : Colors.white).withOpacity(_hover ? 0.9 : 0.5),
                    width: 1.2,
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient button with glow on hover and a squish on press.
class GlowButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool outlined;
  final bool compact;
  final Color? color;
  const GlowButton({
    super.key,
    this.label,
    this.icon,
    this.onTap,
    this.outlined = false,
    this.compact = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final base = color ?? (dark ? C.sky : C.ocean);
    final fg = outlined ? base : (dark ? C.night : Colors.white);
    return Pressable(
      onTap: onTap,
      builder: (hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 22, vertical: compact ? 9 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: outlined
              ? null
              : LinearGradient(colors: [base, Color.lerp(base, C.seaGreen, 0.55)!]),
          color: outlined ? base.withOpacity(hover ? 0.18 : 0.06) : null,
          border: outlined ? Border.all(color: base, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: base.withOpacity(hover ? 0.6 : 0.25),
              blurRadius: hover ? 24 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: fg, size: 20),
            if (icon != null && label != null) const SizedBox(width: 8),
            if (label != null)
              Text(label!,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class GlowChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  const GlowChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final base = color ?? (dark ? C.sky : C.ocean);
    return Pressable(
      onTap: onTap,
      hoverScale: 1.06,
      builder: (hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: selected ? base : base.withOpacity(hover ? 0.22 : 0.10),
          border: Border.all(color: base.withOpacity(selected ? 1 : 0.5)),
          boxShadow: selected || hover
              ? [BoxShadow(color: base.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: selected ? (dark ? C.night : Colors.white) : base),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? (dark ? C.night : Colors.white) : Theme.of(context).colorScheme.onSurface,
              )),
        ]),
      ),
    );
  }
}

// ───────────────────────── progress ring ─────────────────────────

class ProgressRing extends StatelessWidget {
  final double value; // 0..1
  final double size;
  final Widget? center;
  const ProgressRing({super.key, required this.value, this.size = 84, this.center});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => CustomPaint(
          painter: _RingPainter(v, dark),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final bool dark;
  _RingPainter(this.v, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    const w = 9.0;
    final rect = Offset(w / 2, w / 2) & Size(size.width - w, size.height - w);
    canvas.drawArc(
      rect, 0, math.pi * 2, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = (dark ? Colors.white : C.navy).withOpacity(0.12),
    );
    canvas.drawArc(
      rect, -math.pi / 2, math.pi * 2 * v, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: const [C.seaGreen, C.sky, C.ocean],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.v != v || old.dark != dark;
}

class SectionTitle extends StatelessWidget {
  final String text;
  final String? sub;
  const SectionTitle(this.text, {super.key, this.sub});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurface;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.auto_awesome, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(child: Text(text, style: celestial(26, color: c, bold: true))),
      ]),
      if (sub != null)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 26),
          child: Text(sub!, style: TextStyle(color: c.withOpacity(0.7), fontWeight: FontWeight.w600)),
        ),
    ]);
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: c.primary.withOpacity(0.8)),
          const SizedBox(height: 14),
          Text(text,
              textAlign: TextAlign.center,
              style: celestial(17, color: c.onSurface.withOpacity(0.85))),
        ]),
      ),
    );
  }
}
