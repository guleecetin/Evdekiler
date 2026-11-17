import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _herbSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 260" fill="none" stroke="#B89A5F" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
<path d="M30 250C80 200 120 140 150 40"/>
<path d="M140 72c-30-6-48-24-52-50 28 4 46 22 52 50Z"/>
<path d="M150 64c26-14 50-14 70 0-22 16-46 16-70 0Z"/>
<path d="M118 128c-32 0-54-14-66-40 30-2 52 12 66 40Z"/>
<path d="M128 118c22-22 46-28 72-20-16 24-40 30-72 20Z"/>
<path d="M90 180c-30 6-56-2-74-24 28-8 54 0 74 24Z"/>
<path d="M100 168c16-26 38-38 66-36-12 28-34 40-66 36Z"/>
</svg>''';

// Uygulamanın zemini: krem degrade + çok yavaş süzülen yumuşak ışıklar + silik ot dalı.
// İçerik (child) üstte; zemin kendi katmanında çizildiği için içerik her karede yeniden çizilmez.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  // Tek controller, 28 saniyede bir tur; her ışık kendi hızında ve yönünde dolaşır
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _t.stop();
    } else if (!_t.isAnimating) {
      _t.repeat();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF6F1E7),
                    Color(0xFFFAF7F2),
                    Color(0xFFF3EEE3),
                  ],
                ),
              ),
              child: CustomPaint(painter: _GlowPainter(_t)),
            ),
          ),
        ),
        Positioned(
          right: -40,
          bottom: 40,
          width: 220,
          child: IgnorePointer(
            child: Opacity(opacity: 0.07, child: SvgPicture.string(_herbSvg)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final a = t.value * 2 * pi;

    void glow(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final w = size.width, h = size.height;

    // Adaçayı yeşili: sağ üstte, yavaş daire çiziyor
    glow(
      Offset(w * (0.85 + 0.12 * cos(a)), h * (0.18 + 0.06 * sin(a))),
      w * 0.75,
      const Color(0xFF9CC79A).withValues(alpha: 0.32),
    );

    // Şampanya altını: sol ortada, ters yönde
    glow(
      Offset(w * (0.1 + 0.15 * sin(a * 2)), h * (0.55 + 0.08 * cos(a))),
      w * 0.7,
      const Color(0xFFD8BD82).withValues(alpha: 0.28),
    );

    // Açık nane: altta, yatay süzülüyor
    glow(
      Offset(w * (0.6 + 0.2 * cos(a + 1.5)), h * (0.92 + 0.04 * sin(a * 2))),
      w * 0.65,
      const Color(0xFFBFE0C8).withValues(alpha: 0.30),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => false; // tekrar çizimi "repaint: t" yönetiyor
}
