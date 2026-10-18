# 2026-10-17 聊天页客户信息抽屉

## 变更内容

- 聊天页右上角「…」改为可点击，打开底部抽屉展示对方信息；
- 抽屉内容对齐原型客户信息面板：客户头像（含平台角标）、客户名称、业务渠道、当前状态、负责人、转发去向；
- Conversation 增加 assignee 与 forwardTargets 字段（Mock 数据已填充）；
- 追加 widget 测试覆盖抽屉内容。

## 原因

产品要求点击「…」查看对方信息。

## 验证

- `flutter analyze` / `flutter test`（9 个用例）/ `flutter build web` 通过；
- 截图见 docs/assets/app-v1-customer-sheet.png。
