import '../models/translation_language.dart';
import '../models/translation_provider.dart';
import 'translation_service.dart';

/// 测试用翻译实现：不发起网络请求。
class MockTranslationService implements TranslationService {
  const MockTranslationService();

  @override
  Future<String> translate({
    required String text,
    required TranslationLanguage source,
    required TranslationLanguage target,
    TranslationProvider provider = TranslationProvider.auto,
  }) async => '【${target.code}】$text';
}
