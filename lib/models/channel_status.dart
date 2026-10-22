import 'platform_channel.dart';

class ChannelStatus {
  const ChannelStatus({
    required this.platform,
    required this.account,
    required this.online,
    this.detail = '',
  });

  final PlatformChannel platform;

  /// 渠道账号（例如 WhatsApp 号码 / Telegram Bot / 主页账号）。
  final String account;

  final bool online;

  /// 健康或会话数量等补充信息，来自渠道监控接口。
  final String detail;

  String get name => platform.label;
}
