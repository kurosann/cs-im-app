# 2026-10-17 悬浮毛玻璃输入区

## 变更内容

- 移除底部白色输入栏背景与分割线；
- 输入框 + 发送按钮改为悬浮毛玻璃胶囊（BackdropFilter），覆盖在消息列表上；
- 消息列表底部增加留白，避免内容被输入区遮挡；
- 输入框左侧新增「+」附件按钮，点击弹出抽屉：图片 / 视频 / 文件；
- V1 选择后添加示例媒体消息（图片、视频、文件气泡）；
- ChatMessage 增加 file 类型与文件卡片展示；ChatRepository/AppStore 增加 sendAttachment；
- 新增附件流程测试与文档。

## 原因

产品要求输入区改为悬浮毛玻璃，并支持选择文件、图片、视频上传。

## 验证

- `flutter analyze` / `flutter test` / `flutter build web` 通过；
- 截图见 docs/assets/app-v1-floating-composer.png、app-v1-attachment-sheet.png。
