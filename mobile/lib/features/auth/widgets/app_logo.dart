import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/app_logo.dart' as brand;

// Eski logo bileşeninin yerine geçer: aynı ad, aynı parametreler,
// ama içeride yeni marka logosu (assets/branding/logo.svg) çizilir.
// Bu dosyayı kullanan eski ekranlar import değiştirmeden yeni logoya geçer.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD8BD82).withValues(alpha: 0.45),
                blurRadius: size * 0.4,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: brand.AppLogo(size: size),
        ),
        if (showName) ...[
          SizedBox(height: size * 0.2),
          Text(
            'Evdekiler',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D3A2A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
