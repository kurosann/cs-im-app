# 2026-10-17 底部导航独立悬浮

## 变更内容

- 底部导航从 `Column` 布局改为 `Stack` 覆盖层，不再单独占用底部高度；
- 导航条改为独立悬浮胶囊，使用 `BackdropFilter` 毛玻璃与半透明背景；
- 移除原本导航下方约一整条的厚背景区域；
- 深浅主题均使用同一套悬浮胶囊样式；
- 值守、状态、我的页面底部增加滚动留白，保证最后一条内容不被导航遮挡；
- 导航增加主题亮度 key，确保切换主题后文字颜色正确重建。

## 原因

产品要求导航栏独立悬浮、使用毛玻璃，并去掉底部很厚的背景条。

## 验证

- `flutter analyze` 通过；
- 值守页与状态页导航相关测试通过；
- `flutter build web --release --no-web-resources-cdn` 通过；
- 截图见 `docs/assets/app-v1-duty.png`、`docs/assets/app-v1-duty-dark.png`。