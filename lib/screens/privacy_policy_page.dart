import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/policy_section.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                          '隐私协议',
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
                        'CS-IM 隐私协议（草案）',
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
                          '提示：本协议为 V1 原型草案，正式上线前需经法务审核。',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: AppColors.pendingInk,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const PolicySection(
                        title: '隐私速览',
                        body: '我们只处理提供客服服务所必需的信息，并采取加密与访问控制措施保护数据。',
                        bullets: [
                          '收集什么：账号信息、会话消息与附件、客户/渠道标识、翻译文本、AI 决策上下文、运行日志。',
                          '存储什么：服务端保存会话、客户、AI 记录与投递日志；本机保存图片/视频/语音缓存与临时文件。',
                          '如何加密：HTTPS/WSS 加密传输；服务端数据库与对象存储加密，渠道凭据单独加密；本机缓存受应用沙箱与设备加密保护。',
                          '不会用于第三方：不出售、不出租，不用于广告营销或用户画像；仅在提供翻译、AI、转发功能时向所选服务商发送必要数据。',
                        ],
                      ),
                      const PolicySection(
                        title: '1. 引言',
                        body: '聚合客服系统（以下简称“本产品”）为客服团队提供消息接入、AI 决策、人工接待、翻译与转发能力。本协议说明我们如何收集、存储、加密、使用和保护信息。',
                      ),
                      const PolicySection(
                        title: '2. 我们收集的信息',
                        body: '为提供客服服务，我们仅收集以下必要信息：',
                        bullets: [
                          '账号信息：姓名、账号标识、角色、所属租户；',
                          '会话信息：客户标识、来源渠道、渠道账号、消息内容、附件与会话状态；',
                          '翻译信息：待翻译文本、源/目标语言与译文；',
                          'AI 信息：AI 决策所需的会话上下文、知识库引用与执行记录；',
                          '日志信息：设备与网络信息、错误日志、审计与投递记录。',
                        ],
                      ),
                      const PolicySection(
                        title: '3. 我们存储的信息',
                        body: '信息按用途分别存储在服务端与本机：',
                        bullets: [
                          '服务端：账号与租户、会话与消息、客户身份、AI 决策记录、转发投递与重试日志、渠道配置；',
                          '服务端不会保存业务前端本地的临时文件；',
                          '本机：图片/视频/语音缓存、翻译临时缓存、AI 临时结果、日志与临时文件；',
                          '本机缓存的清理方式见《存储协议》，清理缓存不会删除服务端消息。',
                        ],
                      ),
                      const PolicySection(
                        title: '4. 我们如何加密保护',
                        body: '我们采用传输加密、存储加密与最小权限控制：',
                        bullets: [
                          '传输加密：接口使用 HTTPS，实时通道使用 WSS/TLS；',
                          '服务端存储：数据库与对象存储启用加密（AES-256 或云服务商透明加密）；',
                          '渠道凭据：Token/Secret 等单独使用 AES-GCM 加密存储，主密钥通过 KMS/环境变量管理，不与业务数据混存；',
                          '本机缓存：保存在应用沙箱内，受系统设备加密保护；敏感凭据使用系统安全存储，不写入明文日志。',
                        ],
                      ),
                      const PolicySection(
                        title: '5. 信息的使用',
                        body: '我们仅在提供服务所需的范围内使用信息：',
                        bullets: [
                          '接收与展示客服消息，完成会话分配与人工接待；',
                          '执行 AI 决策、翻译和消息转发；',
                          '保障系统安全、排查故障与进行审计；',
                          '改进服务质量与产品体验。',
                        ],
                      ),
                      const PolicySection(
                        title: '6. 第三方服务与共享边界',
                        body: '我们不会将你的信息出售、出租，也不会用于广告营销或用户画像。仅在实现具体功能时，向所选服务商发送必要数据：',
                        bullets: [
                          '机器翻译：将待翻译文本发送给所选翻译服务商（Google、腾讯翻译君、有道、百度、DeepL、火山翻译、彩云小译、腾讯交互翻译、Papago、CNKI、MyMemory、LibreTranslate、ChatGPT 免费等）；',
                          'AI 服务：将组装后的会话上下文发送给配置的 AI 模型服务；',
                          '转发渠道：将消息内容发送到 Telegram、WhatsApp、飞书、企业微信、Webhook 等目标；',
                          '除用户授权、功能必需或法律要求外，不向其他第三方共享信息；',
                          '翻译源与转发渠道可在设置中查看、切换或关闭，具体以实际配置为准。',
                        ],
                      ),
                      const PolicySection(
                        title: '7. 存储与保留',
                        body: '信息按业务与合规要求保存。超过保存期限后，我们将删除或匿名化处理，法律法规另有要求的除外。',
                      ),
                      const PolicySection(
                        title: '8. 信息安全',
                        body: '我们采用访问控制、加密传输、审计与最小权限等措施保护信息。互联网环境不存在绝对安全，请妥善保管账号与设备。',
                      ),
                      const PolicySection(
                        title: '9. 你的权利',
                        body: '你可以通过租户管理员或产品支持渠道申请查询、更正、删除信息，或撤回相关授权。我们会在合理期限内处理。',
                      ),
                      const PolicySection(
                        title: '10. 未成年人',
                        body: '本产品面向企业客服场景，不面向未成年人单独提供服务。',
                      ),
                      const PolicySection(
                        title: '11. 协议更新',
                        body: '我们可能根据业务或法规变化更新本协议。更新后将在产品内公示，重大变更将另行通知。',
                      ),
                      const PolicySection(
                        title: '12. 联系我们',
                        body: '如对本协议有疑问，请通过所属租户管理员或产品支持渠道联系我们。',
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
