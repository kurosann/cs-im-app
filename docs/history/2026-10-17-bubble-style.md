# 2026-10-17 气泡与译文样式对齐 V2 原型

## 变更内容

- 来消息气泡：白底 + slate-200 描边 + 轻阴影；AI 消息保留 AI 标签；
- 我方气泡：深墨底白字；
- 译文样式：气泡内原文下方，虚线分隔 + 灰色小字（移除「译」标签）；
- 消息区背景改为 slate-50，头部/翻译条/输入区保持白色；
- 新增 `dart_test.yaml`（concurrency: 1），解决 widget 测试并行偶发 "did not complete"。

## 原因

按 V2 聊天室原型调整气泡与译文视觉。

## 验证

- `flutter analyze` / `flutter test`（10 个用例）/ `flutter build web` 通过；
- 截图见 docs/assets/app-v1-translation.png。
