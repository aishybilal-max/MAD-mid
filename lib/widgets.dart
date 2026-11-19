import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'theme.dart';

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

// ───────────────────────── animated background ─────────────────────────
// Photo that slowly breathes/drifts + blue-green wash + twinkling stars + rising bubbles.

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
    with TickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _slow =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();

  @override
  void dispose() {
    _c.dispose();
    _slow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        // photo: slow zoom + drift
        ClipRect(
          child: AnimatedBuilder(
            animation: _slow,
            builder: (_, child) {
              final t = _slow.value * 2 * math.pi;
              return Transform.translate(
                offset: Offset(10 * math.sin(t), 6 * math.cos(t)),
                child: Transform.scale(scale: 1.16 + 0.03 * math.sin(t), child: child),
              );
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: Image.asset(
                dark ? widget.darkImage : widget.lightImage,
                key: ValueKey('${dark}_${widget.lightImage}'),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
        // blue-green wash so glass + text stay readable
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark
                  ? [
                      C.night.withOpacity(0.70),
                      C.navy.withOpacity(0.42),
                      C.deepGreen.withOpacity(0.62),
                    ]
                  : [
                      Colors.white.withOpacity(0.34),
                      C.sky.withOpacity(0.20),
                      C.seaGreen.withOpacity(0.34),
                    ],
            ),
          ),
        ),
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _BubblePainter(_slow, dark)),
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

class _BubblePainter extends CustomPainter {
  final Animation<double> anim;
  final bool dark;
  static final _rnd = math.Random(21);
  // x, size, phase, wobble, speed (integer => seamless loop)
  static final List<List<double>> _b = List.generate(
    20,
    (_) => [
      _rnd.nextDouble(),
      3 + _rnd.nextDouble() * 9,
      _rnd.nextDouble(),
      0.01 + _rnd.nextDouble() * 0.03,
      (1 + _rnd.nextInt(3)).toDouble(),
    ],
  );

  _BubblePainter(this.anim, this.dark) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _b) {
      final p = (anim.value * b[4] + b[2]) % 1.0;
      final y = size.height * (1.08 - p * 1.2);
      final x = size.width * (b[0] + b[3] * math.sin(p * 4 * math.pi));
      final fade = math.sin(p * math.pi).clamp(0.0, 1.0);
      final c = Offset(x, y);
      canvas.drawCircle(
        c,
        b[1],
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withOpacity(0.55 * fade),
            C.sky.withOpacity(0.10 * fade),
          ]).createShader(Rect.fromCircle(center: c, radius: b[1])),
      );
      canvas.drawCircle(
        c,
        b[1],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.white.withOpacity(0.45 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.dark != dark;
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
        ..color = (dark ? Colors.white : Colors.white).withOpacity(0.10 + 0.60 * t)
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

class _SlideGradient extends GradientTransform {
  final double slide; // -1 … 1
  const _SlideGradient(this.slide);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}

/// Glossy light band that sweeps diagonally across its parent every few seconds.
/// Put it inside a Stack on top of a glass surface.
class GlassShine extends StatefulWidget {
  final double strength;
  const GlassShine({super.key, this.strength = 0.30});

  @override
  State<GlassShine> createState() => _GlassShineState();
}

class _GlassShineState extends State<GlassShine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  )
    ..value = math.Random().nextDouble() // so cards do not shine in sync
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final p = const Interval(0.0, 0.35, curve: Curves.easeInOut).transform(_c.value);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1, -0.5),
                end: const Alignment(1, 0.5),
                colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(widget.strength),
                  Colors.white.withOpacity(0),
                ],
                stops: const [0.38, 0.5, 0.62],
                transform: _SlideGradient(-1.6 + 3.2 * p),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Transparent, shiny frosted-glass card. Lifts and glows on hover.
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
    final tint = widget.tint ?? C.ocean;
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
                color: (dark ? C.sky : C.navy).withOpacity(_hover ? 0.34 : 0.16),
                blurRadius: _hover ? 30 : 22,
                offset: Offset(0, _hover ? 14 : 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Stack(
                children: [
                  Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? [
                                Colors.white.withOpacity(_hover ? 0.22 : 0.16),
                                tint.withOpacity(0.12),
                                Colors.white.withOpacity(0.05),
                              ]
                            : [
                                Colors.white.withOpacity(_hover ? 0.60 : 0.46),
                                tint.withOpacity(0.10),
                                Colors.white.withOpacity(_hover ? 0.30 : 0.18),
                              ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(_hover ? 0.85 : (dark ? 0.35 : 0.65)),
                        width: 1.2,
                      ),
                    ),
                    child: widget.child,
                  ),
                  // glossy top edge
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 46,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(dark ? 0.16 : 0.30),
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(child: GlassShine()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade + slide-up entrance. `index` staggers items in a list.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 80 * widget.index.clamp(0, 8)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(_a),
        child: widget.child,
      ),
    );
  }
}

/// Gently "breathes" (scale pulse) - used on the + button.
class Breathing extends StatefulWidget {
  final Widget child;
  const Breathing({super.key, required this.child});

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      builder: (_, child) => Transform.scale(scale: 1 + 0.05 * _c.value, child: child),
      child: widget.child,
    );
  }
}

/// Glossy progress bar with a glow and a light streak on top.
class GlossyBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  const GlossyBar({super.key, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.30)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, Color.lerp(color, C.seaGreen, 0.6)!]),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)],
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.4,
                    child: ColoredBox(color: Colors.white.withOpacity(0.35)),
                  ),
                ),
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
