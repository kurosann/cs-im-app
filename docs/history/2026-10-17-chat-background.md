# 2026-10-17 浅色聊天背景调整

## 变更内容

- 聊天页新增语义色 `chatBackground`；
- 浅色主题消息区背景由 `#F8FAFC` 调整为 `#EDEDED`；
- 深色主题聊天背景保持 `#020617` 不变；
- 悬浮毛玻璃头部与输入区、白色消息气泡在新背景下继续保留层次。

## 原因

白色气泡与页面底色对比过弱，产品要求浅色聊天背景稍微加深。

## 验证

- `flutter analyze` 通过；
- `flutter build web --release --no-web-resources-cdn` 通过；
- 截图见 `docs/assets/app-v1-chat.png`。