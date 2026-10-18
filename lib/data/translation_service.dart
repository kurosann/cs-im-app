import '../models/translation_language.dart';
import '../models/translation_provider.dart';

/// 机器翻译边界。V1 使用公共翻译源；接入后端后替换实现即可。
abstract interface class TranslationService {
  Future<String> translate({
    required String text,
    required TranslationLanguage source,
    required TranslationLanguage target,
    TranslationProvider provider = TranslationProvider.auto,
  });
}
