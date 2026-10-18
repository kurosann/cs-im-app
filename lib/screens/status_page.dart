import 'package:flutter/material.dart';

import '../models/channel_status.dart';
import '../models/forward_channel_status.dart';
import '../models/platform_channel.dart';
import '../state/app_scope.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/platform_logo.dart';
import 'channel_conversations_page.dart';
import '../widgets/app_card.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);
    return ColoredBox(
      color: AppColors.page,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 104),
        children: [
          const Text(
            '状态',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '值守概况和渠道可用性。',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '${store.waitingCount}',
                  label: '待人工',
                  color: AppColors.red600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '${store.handlingCount}',
                  label: '处理中',
                  color: AppColors.blue600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '${store.aiHandledCount}',
                  label: 'AI 已处理',
                  color: AppColors.emerald600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '业务渠道',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < store.channels.length; i++) ...[
                  _ChannelRow(
                    channel: store.channels[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            ChannelConversationsPage(
                              channel: store.channels[i],
                            ),
                      ),
                    ),
                  ),
                  if (i != store.channels.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '转发渠道',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < store.forwardChannels.length; i++) ...[
                  _ForwardChannelRow(channel: store.forwardChannels[i]),
                  if (i != store.forwardChannels.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.onTap});

  final ChannelStatus channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.page,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              PlatformLogo(channel: channel.platform, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      channel.account,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: channel.online
                      ? AppColors.emerald50
                      : AppColors.lavender,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  channel.online ? '在线' : '离线',
                  style: TextStyle(
                    fontSize: 12,
                    color: channel.online
                        ? AppColors.emerald600
                        : AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForwardChannelRow extends StatelessWidget {
  const _ForwardChannelRow({required this.channel});

  final ForwardChannelStatus channel;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (channel.state) {
      ForwardChannelState.connected => (
        AppColors.emerald50,
        AppColors.emerald600,
      ),
      ForwardChannelState.disconnected => (AppColors.red50, AppColors.red600),
      ForwardChannelState.unconfigured => (
        AppColors.pendingBg,
        AppColors.pendingInk,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _ForwardLogo(channel: channel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${channel.channelLabel} · ${channel.target}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              channel.state.label,
              style: TextStyle(fontSize: 12, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForwardLogo extends StatelessWidget {
  const _ForwardLogo({required this.channel});

  final ForwardChannelStatus channel;

  @override
  Widget build(BuildContext context) {
    if (channel.platform.logoAsset != null) {
      return PlatformLogo(channel: channel.platform, size: 38);
    }
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.blue50,
        shape: BoxShape.circle,
      ),
      child: Text(
        channel.channelLabel.isEmpty
            ? '?'
            : channel.channelLabel.substring(0, 1),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.blue600,
        ),
      ),
    );
  }
}
