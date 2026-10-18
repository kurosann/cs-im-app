# 2026-10-17 草稿译文收起

## 变更内容

- 草稿译文卡片新增「收起译文」小图标；
- 点击「使用译文」后卡片收起，且不再触发反向翻译；
- 发送消息后卡片保持收起；
- 手动收起后再次输入时自动展开；
- 更新边写边译测试与文档。

## 原因

产品要求草稿译文在使用、发送后收起，并支持用户手动收起。

## 验证

- `flutter analyze` / `flutter test` / `flutter build web` 通过；
- 截图见 docs/assets/app-v1-draft-translation.png。
