import 'platform_channel.dart';

class ChannelStatus {
  const ChannelStatus({
    required this.platform,
    required this.account,
    required this.online,
  });

  final PlatformChannel platform;

  /// 渠道账号（例如 WhatsApp 号码 / Telegram Bot / 主页账号）。
  final String account;

  final bool online;

  String get name => platform.label;
}
