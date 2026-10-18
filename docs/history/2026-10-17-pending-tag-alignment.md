# 2026-10-17 未回复标签居中

## 变更内容

- 「未回复」标签改为固定 20px 高度；
- 使用 `Alignment.center` 与 `TextAlign.center` 保证文字水平、垂直居中；
- 中文文本行高设置为 `height: 1`，消除 Noto Sans SC 行高导致的视觉偏移；
- 左右内边距调整为 8px。

## 原因

Noto Sans SC 的默认行高较大，导致标签文字在胶囊内看起来偏上/偏下。

## 验证

- `flutter analyze` 通过；
- 值守页测试通过；
- `flutter build web --release --no-web-resources-cdn` 通过；
- 截图见 `docs/assets/app-v1-duty.png`、`docs/assets/app-v1-duty-dark.png`。