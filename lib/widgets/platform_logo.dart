import 'package:flutter/material.dart';

import '../models/platform_channel.dart';

/// 平台来源 logo（品牌色圆底 + 白色字形）。
class PlatformLogo extends StatelessWidget {
  const PlatformLogo({
    super.key,
    required this.channel,
    this.size = 36,
    this.paddingFactor = 0.18,
    this.showBorder = false,
  });

  final PlatformChannel channel;
  final double size;
  final double paddingFactor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final String? asset = channel.logoAsset;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * paddingFactor),
      decoration: BoxDecoration(
        color: platformBrandColor(channel),
        shape: BoxShape.circle,
        border: showBorder ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: asset == null
          ? Icon(
              Icons.chat_bubble_outline_rounded,
              size: size * 0.5,
              color: Colors.white,
            )
          : Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

Color platformBrandColor(PlatformChannel channel) => switch (channel) {
  PlatformChannel.telegram => const Color(0xFF229ED9),
  PlatformChannel.whatsapp => const Color(0xFF25D366),
  PlatformChannel.instagram => const Color(0xFFE4405F),
  PlatformChannel.x => const Color(0xFF000000),
  PlatformChannel.facebook => const Color(0xFF1877F2),
  PlatformChannel.meta => const Color(0xFF0866FF),
  PlatformChannel.messenger => const Color(0xFF0084FF),
  PlatformChannel.tiktok => const Color(0xFF000000),
  PlatformChannel.discord => const Color(0xFF5865F2),
  PlatformChannel.line => const Color(0xFF06C755),
  PlatformChannel.teams => const Color(0xFF6264A7),
  PlatformChannel.zalo => const Color(0xFF0068FF),
  PlatformChannel.unknown => const Color(0xFF94A3B8),
};
