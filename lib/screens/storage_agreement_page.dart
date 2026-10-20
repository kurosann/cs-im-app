import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/policy_section.dart';

class StorageAgreementPage extends StatelessWidget {
  const StorageAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(6, 8, 16, 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 20,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.ink,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          '存储协议',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    children: [
                      const Text(
                        '本地存储协议（草案）',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '版本 v0.1 · 2026-10-17',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pendingBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '提示：本协议为原型草案，正式上线前需经法务审核。',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: AppColors.pendingInk,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const PolicySection(
                        title: '1. 本地缓存的内容',
                        body: '为提升加载速度与使用体验，本产品会在设备本地保存以下缓存：',
                        bullets: [
                          '聊天中的图片、视频缩略图与语音文件；',
                          '翻译结果与待翻译文本的临时缓存；',
                          'AI 回复与知识库检索的临时结果；',
                          '日志、临时文件与其他运行数据。',
                        ],
                      ),
                      const PolicySection(
                        title: '2. 缓存用途',
                        body: '本地缓存仅用于加速页面打开、减少重复下载与提升消息加载体验，不用于广告投放，也不会改变服务器上的消息与客户数据。',
                      ),
                      const PolicySection(
                        title: '3. 加密与保护',
                        body: '本地缓存与凭据采用以下保护措施：',
                        bullets: [
                          '缓存文件保存在应用沙箱目录，其他应用无法直接访问；',
                          '设备开启系统加密时，缓存受设备级加密保护；',
                          '敏感凭据使用系统安全存储，不以明文写入缓存或日志；',
                          '缓存内容通过应用内权限控制读取，不对外提供公共访问地址。',
                        ],
                      ),
                      const PolicySection(
                        title: '4. 不会用于第三方',
                        body: '本机缓存不会上传用于广告投放、用户画像或第三方营销。仅当你使用翻译、AI 或转发功能时，产品才会按功能需要向所选服务商发送必要的消息文本；具体规则见《隐私协议》。',
                      ),
                      const PolicySection(
                        title: '5. 清理与影响',
                        body: '清理本地缓存会删除设备上的图片、视频、语音与临时文件。服务器上的会话、消息和客户资料不会受到影响；再次打开相关内容时可能需要重新下载或重新生成。',
                      ),
                      const PolicySection(
                        title: '6. 自动清理',
                        body: '当缓存超过产品设定的上限时，本产品可能自动清理较早或可重新获取的缓存文件。重要数据请以服务器记录为准。',
                      ),
                      const PolicySection(
                        title: '7. 安全与隐私',
                        body: '缓存保存在本机应用沙箱内，并受系统权限保护。我们对信息的使用与保护规则详见《隐私协议》。',
                      ),
                      const PolicySection(
                        title: '8. 更新与联系',
                        body: '本协议可能随产品功能更新。如有疑问，请通过所属租户管理员或产品支持渠道联系我们。',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '本页面为演示文本，不构成正式法律文件。',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
