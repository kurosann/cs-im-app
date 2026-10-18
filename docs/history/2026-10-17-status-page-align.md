# 2026-10-17 状态页对齐原型

## 变更内容

- 状态页按原型重做：标题 + 副标题、三项值守统计（待人工 / 处理中 / AI 已处理）、渠道状态列表（WhatsApp / Telegram / Messenger）；
- 移除原「客服状态卡 + 基础设置」设计；
- `ChatRepository` 增加 `fetchChannels`；`AppStore` 增加渠道状态与三项统计派生值；
- 底部导航对齐原型：白 90% 胶囊 + slate-200/70 边框。

## 原因

首版状态页与原型不符，走查时被发现。

## 验证

- `flutter analyze` / `flutter test` / `flutter build web` 通过；
- 状态页截图与原型对照一致（见 docs/assets/app-v1-status.png）。
