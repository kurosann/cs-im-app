# 2026-10-18 用户设置持久化

## 变更内容

- 引入 `shared_preferences`；
- `AppStore` 持久化主题模式、消息提醒开关、翻译开关、翻译源、源语言和目标语言；
- 设置修改后立即更新内存状态并异步写入本地存储；
- App 启动时恢复设置，翻译已开启时重新进入聊天会自动翻译消息；
- 测试环境通过 `persistenceEnabled: false` 隔离本地存储，避免测试相互影响；
- 新增设置持久化单元测试。

## 验证

- `flutter analyze` 通过；
- `用户设置持久化` 测试通过；
- 浏览器刷新后翻译开关与翻译设置仍能恢复；
- `flutter build web --release --no-web-resources-cdn` 通过。