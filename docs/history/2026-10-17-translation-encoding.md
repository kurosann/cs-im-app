# 2026-10-17 翻译结果中文乱码处理

## 变更内容

- 新增 `lib/utils/text_encoding.dart`，统一清洗第三方翻译服务返回文本；
- 支持 HTML 数字实体与常用命名实体解码；
- 支持修复 UTF-8 被错误按 Latin-1 或 CP1252 解码后产生的中文乱码；
- 过滤控制字符；如果结果仍包含 U+FFFD 替换字符，则判定为异常并回退到下一个翻译源；
- 翻译服务所有 provider 共用该清洗逻辑；
- 新增 `test/translation_test.dart` 乱码修复用例。

## 原因

不同第三方翻译接口可能返回 HTML 实体或错误编码文本，导致中文偶尔显示为乱码。

## 验证

- `flutter analyze` 通过；
- `test/translation_test.dart` 3 个用例通过；
- `flutter build web --release --no-web-resources-cdn` 通过。