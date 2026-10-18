# 2026-10-17 聊天页悬浮圆角毛玻璃 header

## 变更内容

- 聊天页 header 改为悬浮圆角毛玻璃条（BackdropFilter + 半透明白底 + 描边 + 轻阴影）；
- 移除 header 中的目标语言「自动」胶囊，目标语言只在翻译设置抽屉内选择；
- 消息列表延伸到 header 下方并增加顶部留白，滚动时可从毛玻璃下方穿过；
- 保留翻译图标与「…」按钮；
- 更新截图与文档。

## 原因

产品要求去掉 header 中的语言下拉，并将 header 做成圆形毛玻璃效果。

## 验证

- `flutter analyze` / 逐文件 `flutter test` / `flutter build web` 通过；
- 截图见 docs/assets/app-v1-chat.png、app-v1-translation.png、app-v1-draft-translation.png。
