# 2026-10-17 平台来源 logo 角标 & 移除 V1 徽标

## 变更内容

- 会话头像右下角新增平台来源 logo（WhatsApp / Telegram / Messenger 等）；
- 新增 `PlatformChannel` 模型（12 个内置平台）与 `ChannelAvatar` 组件；
- `Conversation` 增加 `channelLogoUrl` 字段：优先展示后台/后端上传的 logo，失败或为空时回退系统内置图标；
- 复制系统内置平台图标到 `assets/platform/` 并登记到 pubspec；
- 补充 Discord / Teams / LINE / Zalo 演示会话（Ryan / 陈晨 / Yuki / Ngọc），用于验证这 4 个平台的 logo 展示；
- 移除值守页头部的 V1 徽标；「我的 → 基础设置」版本号改为 0.1.0；
- 文档同步更新（solution / ai / plan）。

## 原因

产品要求隐藏 V1 标识，并在头像上直观看到客户来源平台；logo 需同时支持系统内置与后台/后端上传两种来源。

## 验证

- `flutter analyze` / `flutter test` / `flutter build web` 通过；
- 值守页截图更新：docs/assets/app-v1-duty.png。
