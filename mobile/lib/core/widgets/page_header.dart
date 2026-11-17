import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// Marka renkleri: birden fazla ekranda kullanılanlar tek yerde
abstract final class Brand {
  static const forest = Color(0xFF1D3A2A);
  static const forestDeep = Color(0xFF122A1C);
  static const forestLight = Color(0xFF2A5A40);
  static const gold = Color(0xFFD8BD82);
  static const border = Color(0xFFE6E1D8);
}

const brandHerbSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 260" fill="none" stroke="#D8BD82" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
<path d="M30 250C80 200 120 140 150 40"/>
<path d="M140 72c-30-6-48-24-52-50 28 4 46 22 52 50Z"/>
<path d="M150 64c26-14 50-14 70 0-22 16-46 16-70 0Z"/>
<path d="M118 128c-32 0-54-14-66-40 30-2 52 12 66 40Z"/>
<path d="M128 118c22-22 46-28 72-20-16 24-40 30-72 20Z"/>
<path d="M90 180c-30 6-56-2-74-24 28-8 54 0 74 24Z"/>
<path d="M100 168c16-26 38-38 66-36-12 28-34 40-66 36Z"/>
</svg>''';

TextStyle brandDisplay(double size, {Color color = Brand.forest}) =>
    GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.5,
    );

// Sekmelerin üstündeki yeşil başlık şeridi
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.chips = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Brand.forestLight, Brand.forest, Brand.forestDeep],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: top - 10,
              width: 170,
              child: Transform.flip(
                flipX: true,
                child: Opacity(
                  opacity: 0.13,
                  child: SvgPicture.string(brandHerbSvg),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, top + 18, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Brand.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(icon, color: Brand.gold, size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: brandDisplay(26, color: Colors.white),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Brand.gold.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: chips),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderChip extends StatelessWidget {
  const HeaderChip({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Brand.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Brand.gold),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
