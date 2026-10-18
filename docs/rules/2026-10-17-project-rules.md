# 2026-10-17 项目规则

## R1 视觉以原型为准

颜色、字号、间距、圆角优先取原型实测值（见 `../solution/2026-10-17-v1-mobile-solution.md`）；新增页面沿用同一套 token，不引入新品牌色。

## R2 Mock-first，不直连后端

- V1 阶段不发起自家后端请求；仅「边写边译」调用第三方机器翻译（Google / 腾讯 / 百度 / 有道 / DeepL / 火山 / 彩云 / 腾讯交互 / Papago / CNKI / MyMemory / LibreTranslate / ChatGPT 免费），并必须在界面提示用户请勿输入敏感信息；
- Widget 不得直接引用 mock 数据，必须经 `AppStore` → `ChatRepository`；
- mock 数据仅用于演示，不包含真实客户信息。

## R3 后端接入边界

- 新接口先加入 `ChatRepository` 抽象，再实现 `RemoteChatRepository`；
- UI 层调用方式保持不变；
- 接口字段与《cs-im-route 需求方案》保持一致，命名冲突时先更新方案文档。

## R4 文档分类

- 计划 → `docs/plan`；方案 → `docs/solution`；规则 → `docs/rules`；
- AI 产物 → `docs/ai`；变更 → `docs/history`；素材 → `docs/assets`；
- 文件名 `YYYY-MM-DD-short-name.md`；重大变更同步 `history/`。

## R5 质量门禁

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test -j 1   # 并行跑 widget 测试偶发卡住，固定串行
flutter build web   # 发布前
```

## R6 安全

不提交密钥、证书、真实客户数据；API 地址与开关通过 `--dart-define` 注入。
