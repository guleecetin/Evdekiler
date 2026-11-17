import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'app_logo.dart';

const _forest = Color(0xFF1D3A2A);
const _gold = Color(0xFFD8BD82);

// Web panelindeki PageLoader'ın mobil hali: nefes alan logo + kayan ince çizgi.
// compact: true → bir bölümün içinde (başlıksız, küçük).
class AppLoader extends StatefulWidget {
  const AppLoader({
    super.key,
    this.message = 'Mutfak hazırlanıyor…',
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _bar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Animasyonları kaldır" erişilebilirlik ayarı açıksa hareket etmesin
    if (MediaQuery.of(context).disableAnimations) {
      _breath.stop();
      _bar.stop();
    } else {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
      if (!_bar.isAnimating) _bar.repeat();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = widget.compact ? 52.0 : 76.0;

    return Semantics(
      label: 'Yükleniyor',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.06).animate(
                CurvedAnimation(parent: _breath, curve: Curves.easeInOut),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(logoSize * 0.25),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AppLogo(size: logoSize),
              ),
            ),
            SizedBox(height: widget.compact ? 16 : 22),
            if (!widget.compact) ...[
              const Text(
                'Evdekiler',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _forest,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              widget.message,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            // İnce ilerleme çizgisi: kısa bir parça soldan sağa kayıyor
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 120,
                height: 4,
                child: ColoredBox(
                  color: _forest.withValues(alpha: 0.1),
                  child: AnimatedBuilder(
                    animation: _bar,
                    builder: (_, child) => FractionalTranslation(
                      translation: Offset(
                        -1 + Curves.easeInOutCubic.transform(_bar.value) * 3.5,
                        0,
                      ),
                      child: child,
                    ),
                    child: const FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.4,
                      child: ColoredBox(color: _forest),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
