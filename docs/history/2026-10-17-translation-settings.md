# 2026-10-17 翻译设置抽屉

## 变更内容

- 翻译入口从头部下方工具条移到聊天页头部「…」左侧（文A 图标）；
- 点击翻译图标弹出设置抽屉：翻译开关、翻译源、目标语言；
- 翻译源：自动（推荐）/ MyMemory / Google 翻译；自动按 MyMemory → Google 依次回落；
- 目标语言：自动 / 中文 / 英语；
- TranslationService 增加 provider 参数，AppStore.translateDraft 透传；
- 更新翻译测试与文档。

## 原因

产品要求把翻译源与目标语言选项收进翻译图标，点击后以底部抽屉设置。

## 验证

- `flutter analyze` / `flutter test`（12 个用例）/ `flutter build web` 通过；
- 截图见 docs/assets/app-v1-translation-settings.png。
