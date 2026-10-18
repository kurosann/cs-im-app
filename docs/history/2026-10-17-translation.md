# 2026-10-17 聊天页翻译

## 变更内容

- 聊天页头部下方新增翻译工具条：深色「文A」圆形按钮 + 目标语言胶囊；
- 目标语言支持「自动 / 中文 / 英语」，通过底部抽屉选择；
- 开启翻译后，消息气泡在原文下方展示译文（带「译」标记与分隔线）；
- ChatMessage 增加 translatedText / translatedLanguage 字段，Mock 数据覆盖 7 个会话的译文；
- 新增翻译相关 widget 测试（开关、语言切换）。

## 原因

参考 V2 聊天室原型，为 V1 聊天页补充基础翻译能力。

## 验证

- `flutter analyze` / `flutter test` / `flutter build web` 通过；
- 截图见 docs/assets/app-v1-translation.png。
