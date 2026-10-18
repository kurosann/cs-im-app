# 2026-10-18 项目改名为 cs-im-app

## 变更内容

- 项目目录由 `cs-im-flutter` 改为 `cs-im-app`；
- Flutter 包名由 `cs_im_flutter` 改为 `cs_im_app`；
- 同步 Android namespace、applicationId、iOS Bundle Identifier、Kotlin 包路径和 IDE 模块文件名；
- 同步 iOS、Web 展示名称及测试中的 Dart 包导入；
- 清理并重新生成 Flutter 依赖与平台环境文件，移除旧绝对路径。

## 验证

- `flutter analyze` 通过；
- 翻译设置 UI 测试单独运行通过；
- 全量 `flutter test` 中部分聊天 UI 用例未完成并触发测试超时，需后续单独处理测试稳定性。
