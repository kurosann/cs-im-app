# 2026-10-18 Mock 消息实时机器翻译

## 变更内容

- 聊天页不再直接展示 `ChatMessage.translatedText` 中的静态 Mock 译文；
- 翻译开启后，对当前会话所有文本消息调用 `MachineTranslationService`；
- 无预置译文的 Mock 会话（如小林）也会触发机器翻译；
- 新增消息翻译缓存、翻译中状态与失败状态；
- 翻译源 / 源语言 / 目标语言变化时，清空缓存并重新翻译；
- 新消息发送后自动加入翻译队列；
- 新增「无预置译文的 Mock 消息也调用机器翻译」测试。

## 验证

- `flutter analyze` 通过；
- 翻译设置测试、边写边译测试、Mock 消息机器翻译测试通过；
- Web 预览中「商品什么时候补货？」成功翻译为英文；
- `flutter build web --release --no-web-resources-cdn` 通过。