import 'package:cs_im_app/models/platform_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('内置平台均有系统 logo 资源', () {
    for (final PlatformChannel channel in PlatformChannel.values) {
      if (channel == PlatformChannel.unknown) {
        continue;
      }
      expect(channel.logoAsset, isNotNull, reason: channel.name);
      expect(channel.logoAsset, startsWith('assets/platform/'));
    }
  });

  test('常用平台展示名正确', () {
    expect(PlatformChannel.telegram.label, 'Telegram');
    expect(PlatformChannel.whatsapp.label, 'WhatsApp');
    expect(PlatformChannel.instagram.label, 'Instagram');
    expect(PlatformChannel.x.label, 'X');
    expect(PlatformChannel.facebook.label, 'Facebook');
    expect(PlatformChannel.meta.label, 'Meta');
    expect(PlatformChannel.messenger.label, 'Messenger');
    expect(PlatformChannel.tiktok.label, 'TikTok');
    expect(PlatformChannel.discord.label, 'Discord');
    expect(PlatformChannel.teams.label, 'Teams');
    expect(PlatformChannel.line.label, 'LINE');
    expect(PlatformChannel.zalo.label, 'Zalo');
  });
}
