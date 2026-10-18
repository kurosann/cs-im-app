# 2026-10-17 输入框边写边译

## 变更内容

- 输入框监听 + 300ms 防抖，开启翻译后自动生成草稿译文；
- 新增「草稿译文」卡片：加载态、译文、上下箭头替换按钮、失败提示与隐私提示；
- 新增 `TranslationService` 抽象与 `MyMemoryTranslationService` 机器翻译实现（无需密钥）；
- 测试注入 `MockTranslationService`，新增边写边译用例；
- 参考 vane-im-flutter 的 300ms 防抖与草稿译文交互。

## 原因

产品要求输入框支持边写边译，并使用机器翻译。

## 验证

- `flutter analyze` / `flutter test` / `flutter build web` 通过；
- 截图见 docs/assets/app-v1-draft-translation.png。
