enum TranslationProvider {
  auto,
  google,
  tencent,
  baidu,
  youdao,
  deepl,
  volcengine,
  caiyun,
  transmart,
  papago,
  cnki,
  mymemory,
  libretranslate,
  chatgptFree,
}

extension TranslationProviderX on TranslationProvider {
  String get label => switch (this) {
    TranslationProvider.auto => '自动（推荐）',
    TranslationProvider.google => 'Google 翻译',
    TranslationProvider.tencent => '腾讯翻译君',
    TranslationProvider.baidu => '百度翻译',
    TranslationProvider.youdao => '有道翻译',
    TranslationProvider.deepl => 'DeepL',
    TranslationProvider.volcengine => '火山翻译',
    TranslationProvider.caiyun => '彩云小译',
    TranslationProvider.transmart => '腾讯交互翻译',
    TranslationProvider.papago => 'Papago',
    TranslationProvider.cnki => 'CNKI 学术翻译',
    TranslationProvider.mymemory => 'MyMemory',
    TranslationProvider.libretranslate => 'LibreTranslate',
    TranslationProvider.chatgptFree => 'ChatGPT 免费',
  };
}
