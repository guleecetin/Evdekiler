import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Web panelindeki logonun aynısı (assets/branding/logo.svg)
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/branding/logo.svg',
      width: size,
      height: size,
      semanticsLabel: 'Evdekiler',
    );
  }
}
