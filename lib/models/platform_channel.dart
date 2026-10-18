/// 系统内置的平台渠道。
///
/// 列表只负责展示：内置图标来自 assets/platform/；
/// 业务方后续上传的自定义 logo 通过 Conversation.channelLogoUrl 覆盖。
enum PlatformChannel {
  telegram,
  whatsapp,
  instagram,
  x,
  facebook,
  meta,
  messenger,
  tiktok,
  discord,
  line,
  teams,
  zalo,
  unknown,
}

extension PlatformChannelX on PlatformChannel {
  String get label => switch (this) {
    PlatformChannel.telegram => 'Telegram',
    PlatformChannel.whatsapp => 'WhatsApp',
    PlatformChannel.instagram => 'Instagram',
    PlatformChannel.x => 'X',
    PlatformChannel.facebook => 'Facebook',
    PlatformChannel.meta => 'Meta',
    PlatformChannel.messenger => 'Messenger',
    PlatformChannel.tiktok => 'TikTok',
    PlatformChannel.discord => 'Discord',
    PlatformChannel.line => 'LINE',
    PlatformChannel.teams => 'Teams',
    PlatformChannel.zalo => 'Zalo',
    PlatformChannel.unknown => '其他渠道',
  };

  /// 系统内置 logo（透明底白色字形，用于品牌色圆形底）。
  String? get logoAsset => switch (this) {
    PlatformChannel.telegram => 'assets/platform/telegram.png',
    PlatformChannel.whatsapp => 'assets/platform/whatsapp.png',
    PlatformChannel.instagram => 'assets/platform/instagram.png',
    PlatformChannel.x => 'assets/platform/x.png',
    PlatformChannel.facebook => 'assets/platform/facebook.png',
    PlatformChannel.meta => 'assets/platform/meta-business.png',
    PlatformChannel.messenger => 'assets/platform/messenger.png',
    PlatformChannel.tiktok => 'assets/platform/tiktok.png',
    PlatformChannel.discord => 'assets/platform/discord.png',
    PlatformChannel.line => 'assets/platform/line.png',
    PlatformChannel.teams => 'assets/platform/teams.png',
    PlatformChannel.zalo => 'assets/platform/zalo.png',
    PlatformChannel.unknown => null,
  };
}
