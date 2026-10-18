# 2026-10-17 值守 Mock 数据扩充至 30 条

## 变更内容

- `mockConversations` 从 7 条扩充至 30 条；
- 状态分布：待人工 10 条、人工处理中 10 条、AI 已处理 10 条；
- 覆盖 WhatsApp、Telegram、Instagram、X、Facebook、Meta、Messenger、TikTok、Discord、LINE、Teams、Zalo 共 12 个平台；
- 新增中文、英文、日文、越南文等消息样本，并补充未读、未回复、负责人和转发去向；
- 新增会话自动生成一条 Mock 客户消息，点击进入聊天页不会出现空白会话；
- 同步更新仓库数量、筛选列表、渠道会话数量相关测试。

## 原因

产品要求值守页列表展示更多数据，用于验证长列表滚动、筛选和不同渠道状态展示。

## 验证

- `flutter analyze` 通过；
- `test/app_store_test.dart`、`test/widget_test.dart`、`test/channel_test.dart` 通过；
- 状态页相关测试通过；
- `flutter build web --release --no-web-resources-cdn` 通过；
- 截图见 `docs/assets/app-v1-duty.png`。