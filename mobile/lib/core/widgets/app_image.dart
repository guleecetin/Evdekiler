import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../api/api_config.dart';

class AppImage extends StatelessWidget {
  const AppImage(
    this.path, {
    super.key,
    this.fallbackEmoji = '🍽️',
    this.fit = BoxFit.cover,
  });

  final String path;
  final String fallbackEmoji;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: '${ApiConfig.baseUrl}$path',
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: const Color(0xFFEDE8E0),
        highlightColor: const Color(0xFFF8F5F0),
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFF1ECE4),
        alignment: Alignment.center,
        child: Text(fallbackEmoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}
