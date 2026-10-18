# 2026-10-17 媒体消息气泡

## 变更内容

- ChatMessage 增加 type（text / image / video / audio）、mediaAsset、durationSeconds；
- 气泡支持：
  - 图片：圆角封面 + 全屏预览（可缩放）；
  - 视频：封面 + 播放按钮 + 时长，点击打开预览占位；
  - 语音：播放/暂停 + 波形 + 时长，模拟播放进度；
- Maya 演示会话新增订单截图、12 秒语音、8 秒视频三条消息；
- 新增 assets/media/（订单截图、视频封面）并登记 pubspec；
- 新增媒体气泡测试与文档说明。

## 原因

产品要求气泡支持语音、视频、图片展示。

## 验证

- `flutter analyze` / `flutter test` / `flutter build web` 通过；
- 截图见 docs/assets/app-v1-media-bubbles.png。
