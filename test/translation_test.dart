import 'package:cs_im_app/models/translation_language.dart';
import 'package:cs_im_app/models/translation_provider.dart';
import 'package:cs_im_app/utils/text_encoding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('语言列表与 vane-im-flutter 对齐', () {
    expect(TranslationLanguage.values.length, 22);
    expect(TranslationLanguage.zhCN.code, 'zh-CN');
    expect(TranslationLanguage.zhTW.code, 'zh-TW');
    expect(TranslationLanguage.en.label, 'English');
    expect(TranslationLanguage.vi.label, 'Tiếng Việt');
  });

  test('翻译结果可解码 HTML 实体并修复常见乱码', () {
    expect(normalizeTranslatedText('&#20320;&#22909;'), '你好');
    expect(normalizeTranslatedText('&#x4F60;&#x597D;'), '你好');
    expect(normalizeTranslatedText('ä½\u00A0å¥½'), '你好');
    expect(normalizeTranslatedText('æµ‹è¯•'), '测试');
    expect(normalizeTranslatedText('Hello 你好'), 'Hello 你好');
    expect(containsReplacementCharacter('你\uFFFD好'), isTrue);
  });
  test('翻译源列表与 vane-im-flutter 对齐', () {
    expect(TranslationProvider.values.length, 14);
    expect(TranslationProvider.tencent.label, '腾讯翻译君');
    expect(TranslationProvider.youdao.label, '有道翻译');
    expect(TranslationProvider.google.label, 'Google 翻译');
    expect(TranslationProvider.mymemory.label, 'MyMemory');
    expect(TranslationProvider.transmart.label, '腾讯交互翻译');
    expect(TranslationProvider.baidu.label, '百度翻译');
    expect(TranslationProvider.deepl.label, 'DeepL');
    expect(TranslationProvider.volcengine.label, '火山翻译');
    expect(TranslationProvider.caiyun.label, '彩云小译');
    expect(TranslationProvider.papago.label, 'Papago');
    expect(TranslationProvider.cnki.label, 'CNKI 学术翻译');
    expect(TranslationProvider.libretranslate.label, 'LibreTranslate');
    expect(TranslationProvider.chatgptFree.label, 'ChatGPT 免费');
  });
}
