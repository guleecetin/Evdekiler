import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/app_logo.dart';

const _forest = Color(0xFF1D3A2A);
const _gold = Color(0xFFD8BD82);

// Native splash ile birebir aynı zemin (#1d3a2a): açılışta renk sıçraması olmaz
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _bar.stop();
    } else if (!_bar.isAnimating) {
      _bar.repeat();
    }
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _forest,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const AppLogo(size: 96),
              ),
              const SizedBox(height: 22),
              Text(
                'Evdekiler',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mutfak hazırlanıyor…',
                style: TextStyle(
                  color: _gold.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 28),
              // Soldan sağa kayan altın çubuk
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  width: 120,
                  height: 3,
                  child: Stack(
                    children: [
                      Container(color: Colors.white.withValues(alpha: 0.12)),
                      AnimatedBuilder(
                        animation: _bar,
                        builder: (_, child) => FractionallySizedBox(
                          widthFactor: 0.4,
                          child: FractionalTranslation(
                            translation: Offset(-1 + 3.5 * _bar.value, 0),
                            child: child,
                          ),
                        ),
                        child: Container(color: _gold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
