import 'platform_channel.dart';

enum ForwardChannelState { connected, disconnected, unconfigured }

extension ForwardChannelStateX on ForwardChannelState {
  String get label => switch (this) {
    ForwardChannelState.connected => '已连接',
    ForwardChannelState.disconnected => '未连接',
    ForwardChannelState.unconfigured => '未配置',
  };
}

class ForwardChannelStatus {
  const ForwardChannelStatus({
    required this.platform,
    required this.displayName,
    required this.channelLabel,
    required this.target,
    required this.state,
  });

  final PlatformChannel platform;

  /// 转发目标显示名，例如 售后值班群 / 海外客服 / 财务提醒。
  final String displayName;

  /// 渠道名称，例如 Telegram / WhatsApp / 飞书。
  final String channelLabel;

  /// 目标账号/群标识。
  final String target;

  final ForwardChannelState state;
}
