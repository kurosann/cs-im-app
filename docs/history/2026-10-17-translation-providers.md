# 2026-10-17 翻译源与语言列表对齐 vane-im-flutter

## 变更内容

- 翻译设置改为三个内联展开选择：翻译源、源语言、目标语言（选项在抽屉内展开，不弹独立菜单，字体沿用页面样式）；
- 翻译源接入 vane-im-flutter / vane-im-server 全部实现（13 个）：Google、腾讯翻译君、百度、有道、DeepL、火山、彩云、腾讯交互、Papago、CNKI、MyMemory、LibreTranslate、ChatGPT 免费；
- 自动翻译源回落链（网页端优先可用源）：Google → MyMemory → LibreTranslate → 腾讯 → 有道 → 腾讯交互 → DeepL → 火山 → 彩云 → Papago → 百度 → CNKI → ChatGPT 免费；
- 源语言/目标语言与 vane-im-flutter 对齐：自动检测 + 21 种语言（简繁中文、英、日、韩、法、德、西、葡、俄、阿、印地、印尼、意、荷、波兰、土耳其、越南、泰、乌克兰、瑞典）；
- 引入 crypto / encrypt 依赖（有道签名与 AES 解密）；
- 更新翻译测试与文档。

## 说明

- 百度翻译网页版已接入（服务端同款网页接口）；Azure / 阿里云因需要密钥，服务端也刻意未开放。

## 验证

- `flutter analyze` / `flutter test` / `flutter build web` 通过；
- 截图见 docs/assets/app-v1-translation-settings.png。
