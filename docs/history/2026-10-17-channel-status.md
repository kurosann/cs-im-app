# 2026-10-17 渠道状态优化

## 变更内容

- 状态页拆分为「业务渠道」与「转发渠道」两个列表；
- 业务渠道行新增平台 logo、渠道账号（WhatsApp orange-support / Telegram @orange_support_bot / Messenger orange-page）；
- 转发渠道展示目标显示名、渠道/目标账号与连接状态（已连接 / 未连接 / 未配置）；
- 行尾新增进入箭头；
- 点击渠道进入「渠道会话列表」页：展示渠道信息与该渠道下全部会话，可继续进入聊天；
- 新增 PlatformLogo 组件（品牌色圆底 + 平台图标），会话头像角标复用同一组件；
- ChannelStatus 模型增加 platform / account 字段；
- 更新深浅色截图、测试与文档。

## 原因

产品要求渠道状态列表更直观，并支持按渠道查看会话。

## 验证

- `flutter analyze` 无问题；
- channel / status / chat 等测试通过；
- `flutter build web` 成功；
- 截图见 docs/assets/app-v1-status.png、app-v1-status-dark.png、app-v1-channel-conversations.png。
