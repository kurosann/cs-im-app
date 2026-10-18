import 'package:flutter/material.dart';

import '../models/conversation.dart';
import 'platform_logo.dart';
import '../theme/app_theme.dart';

/// 会话头像 + 右下角平台来源 logo。
///
/// 内置渠道使用 assets/platform/ 下的系统图标；
/// 若后端/后台为渠道上传了自定义 logo（channelLogoUrl），则优先生效。
class ChannelAvatar extends StatelessWidget {
  const ChannelAvatar({super.key, required this.conversation, this.size = 44});

  final Conversation conversation;
  final double size;

  @override
  Widget build(BuildContext context) {
    final double badgeSize = size * 0.5;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Text(
              conversation.initial,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child:
                  conversation.channelLogoUrl == null ||
                      conversation.channelLogoUrl!.isEmpty
                  ? PlatformLogo(
                      channel: conversation.channel,
                      size: badgeSize,
                      paddingFactor: 0.14,
                      showBorder: true,
                    )
                  : Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          conversation.channelLogoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stack,
                              ) => PlatformLogo(
                                channel: conversation.channel,
                                size: badgeSize,
                                paddingFactor: 0.14,
                                showBorder: true,
                              ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
