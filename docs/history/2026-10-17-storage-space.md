# 2026-10-17 存储空间与存储协议

## 变更内容

- 「我的 → 基础设置」新增「存储空间」入口；
- 存储空间页展示本地缓存总量、图片/视频/语音/其他分类占用与 512 MB 上限；
- 新增《存储协议》（草案），说明本地缓存内容、用途、加密与保护、第三方边界、清理影响、自动清理与联系方式；
- 支持清理本地缓存，清理不影响服务端消息与客户资料；
- 「清理本地缓存」使用红色危险操作按钮，清空后显示置灰的「本地缓存已清空」；
- V1 缓存统计与清理为 Mock 状态，后续接入真实缓存目录统计和文件删除。

## 原因

产品要求在基础设置中提供本地存储管理，并向用户透明说明缓存内容、存储边界与隐私保护方式。

## 验证

- `flutter analyze` 通过；
- `flutter test test/settings_test.dart` 通过；
- `flutter build web --release --no-web-resources-cdn` 通过；
- 截图见 `docs/assets/app-v1-storage.png`、`docs/assets/app-v1-storage-agreement.png`。