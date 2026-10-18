import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/translation_language.dart';
import '../models/translation_provider.dart';
import '../utils/text_encoding.dart';
import 'translation_service.dart';

/// 机器翻译实现（迁移自 vane-api-server / vane-im-flutter）：
/// - 自动：按可用性顺序尝试全部翻译源，取第一个成功结果；
/// - 指定翻译源：只请求该源。
class MachineTranslationService implements TranslationService {
  MachineTranslationService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _requestTimeout = Duration(seconds: 8);

  /// 自动模式优先使用跨域友好的源，避免网页端长时间等待。
  static const List<TranslationProvider> _autoChain = [
    TranslationProvider.google,
    TranslationProvider.mymemory,
    TranslationProvider.libretranslate,
    TranslationProvider.tencent,
    TranslationProvider.youdao,
    TranslationProvider.transmart,
    TranslationProvider.deepl,
    TranslationProvider.volcengine,
    TranslationProvider.caiyun,
    TranslationProvider.papago,
    TranslationProvider.baidu,
    TranslationProvider.cnki,
    TranslationProvider.chatgptFree,
  ];

  static const String _tencentGuid = 'oqdgX0SIwhvM0TmqzTHghWBvfk22';
  static const String _youdaoKey = 'fsdsogkndfokasodnaso';
  static const String _youdaoAesKey =
      r'ydsecret://query/key/B*RGygVywfNBwpmBaZg*WT7SIOUP2T0C9WHMZN39j^DAdaZhAnxvGcCY6VYFwnHl';
  static const String _youdaoAesIv =
      r'ydsecret://query/iv/C@lZe2YzHtZ2CYgaXKSVfsb7Y4QWHjITPPZ0nQp87fBeJ!Iv6v^6fvi2WN@bYpJ4';
  static const String _cnkiKey = '95bae0e3871c9834';
  static const String _ua =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36';

  String _cnkiToken = '';

  @override
  Future<String> translate({
    required String text,
    required TranslationLanguage source,
    required TranslationLanguage target,
    TranslationProvider provider = TranslationProvider.auto,
  }) async {
    final String input = text.trim();
    if (input.isEmpty) {
      return '';
    }
    final String sourceLang = _normalizeWebLang(source.code);
    final String targetLang = target == TranslationLanguage.auto
        ? _autoTarget(input)
        : _normalizeWebLang(target.code);
    final List<TranslationProvider> chain = provider == TranslationProvider.auto
        ? _autoChain
        : <TranslationProvider>[provider];
    Object? lastError;
    for (final TranslationProvider item in chain) {
      try {
        final String translated = switch (item) {
          TranslationProvider.google => await _google(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.tencent => await _tencent(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.baidu => await _baidu(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.youdao => await _youdao(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.deepl => await _deepl(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.volcengine => await _volcengine(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.caiyun => await _caiyun(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.transmart => await _transmart(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.papago => await _papago(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.cnki => await _cnki(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.mymemory => await _myMemory(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.libretranslate => await _libreTranslate(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.chatgptFree => await _freeChatGpt(
            input,
            sourceLang,
            targetLang,
          ),
          TranslationProvider.auto => throw StateError('invalid provider'),
        };
        final String cleaned = _clean(
          normalizeTranslatedText(translated.trim()),
        );
        if (cleaned.isNotEmpty && !containsReplacementCharacter(cleaned)) {
          return cleaned;
        }
        if (containsReplacementCharacter(cleaned)) {
          throw const FormatException(
            'translation contains invalid characters',
          );
        }
      } catch (error) {
        lastError = error;
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    throw Exception('empty translation');
  }

  String _autoTarget(String text) {
    final String inferred = _inferSource(text);
    return inferred == 'zh' ? 'en' : 'zh-CN';
  }

  Future<String> _get(Uri uri, {Map<String, String>? headers}) async {
    final http.Response response = await _client
        .get(uri, headers: headers)
        .timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes);
  }

  Future<String> _google(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final Uri uri = Uri.https(
      'translate.googleapis.com',
      '/translate_a/single',
      {
        'client': 'gtx',
        'sl': _webLang(sourceLang),
        'tl': _webLang(targetLang),
        'dt': 't',
        'dj': '1',
        'q': text,
      },
    );
    final Object? data = jsonDecode(await _get(uri));
    if (data is Map) {
      final Object? sentences = data['sentences'];
      if (sentences is List) {
        final StringBuffer buffer = StringBuffer();
        for (final Object? sentence in sentences) {
          if (sentence is Map) {
            buffer.write(_str(sentence['trans']));
          }
        }
        return buffer.toString();
      }
    }
    return '';
  }

  Future<String> _tencent(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final String source = _tencentLang(sourceLang, text, infer: true);
    final String target = _tencentLang(targetLang, text, infer: false);
    final Uri uri = Uri.https('wxapp.translator.qq.com', '/api/translate', {
      'source': 'auto',
      'target': 'auto',
      'sourceText': text,
      'platform': 'WeChat_APP',
      'candidateLangs': '$source|$target',
      'guid': _tencentGuid,
    });
    final Object? data = jsonDecode(await _get(uri));
    return data is Map ? _str(data['targetText']) : '';
  }

  Future<String> _baidu(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final String from = _baiduLang(sourceLang);
    final String to = _baiduLang(targetLang) == 'auto'
        ? 'en'
        : _baiduLang(targetLang);
    final http.Response home = await _client
        .get(
          Uri.parse('https://fanyi.baidu.com/'),
          headers: {
            'accept-language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
            'user-agent': _ua,
          },
        )
        .timeout(_requestTimeout);
    final String html = utf8.decode(home.bodyBytes);
    final String cookie = home.headers['set-cookie'] ?? '';
    final String? gtk = RegExp(r'window\.gtk\s*=\s*"([\d.]+)"')
        .firstMatch(html)
        ?.group(1);
    final String? token = RegExp(r"token:\s*'(\w+)'")
        .firstMatch(html)
        ?.group(1);
    if (gtk == null || token == null) {
      throw StateError('baidu: missing token');
    }
    final String form = Uri(
      queryParameters: {
        'from': from,
        'to': to,
        'query': text,
        'transtype': 'realtime',
        'simple_means_flag': '3',
        'sign': _createBaiduSign(text, gtk),
        'token': token,
      },
    ).query;
    final http.Response response = await _client
        .post(
          Uri.parse('https://fanyi.baidu.com/v2transapi?from=$from&to=$to'),
          headers: {
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'cookie': cookie,
            'referer': 'https://fanyi.baidu.com/',
            'user-agent': _ua,
          },
          body: form,
        )
        .timeout(_requestTimeout);
    final Object? data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map) {
      final Object? result = data['trans_result'];
      if (result is Map) {
        final Object? rows = result['data'];
        if (rows is List) {
          return rows
              .whereType<Map>()
              .map((Map row) => _str(row['dst']))
              .where((String value) => value.isNotEmpty)
              .join('\n');
        }
      }
    }
    return '';
  }

  Future<String> _youdao(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final int mystic = DateTime.now().millisecondsSinceEpoch;
    final String sign = _md5(
      'client=fanyideskweb&mysticTime=$mystic&product=webfanyi&key=$_youdaoKey',
    );
    final http.Response response = await _client
        .post(
          Uri.parse('https://dict.youdao.com/webtranslate'),
          headers: {
            'accept': 'application/json',
            if (!kIsWeb) 'referer': 'https://fanyi.youdao.com/',
            if (!kIsWeb) 'user-agent': _ua,
          },
          body: {
            'i': text,
            'from': _reverseLang(_webLang(sourceLang)).toUpperCase(),
            'to': _reverseLang(_webLang(targetLang)).toUpperCase(),
            'domain': '0',
            'dictResult': 'true',
            'keyid': 'webfanyi',
            'sign': sign,
            'client': 'fanyideskweb',
            'product': 'webfanyi',
            'appVersion': '1.0.0',
            'vendor': 'web',
            'pointParam': 'client,mysticTime,product',
            'mysticTime': '$mystic',
            'keyfrom': 'fanyi.web',
          },
        )
        .timeout(_requestTimeout);
    return _youdaoText(
      jsonDecode(_decryptYoudao(utf8.decode(response.bodyBytes))),
    );
  }

  Future<String> _deepl(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final String source = _normalizeDeepLLang(sourceLang, 'auto');
    final String target = _normalizeDeepLLang(targetLang, 'ZH-HANS');
    final String body = _createDeepLBody(text, source, target);
    final http.Response response = await _client
        .post(
          Uri.parse('https://www2.deepl.com/jsonrpc'),
          headers: {
            'accept': 'application/json',
            'content-type': 'application/json',
          },
          body: body,
        )
        .timeout(_requestTimeout);
    final Object? data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map) {
      final Object? result = data['result'];
      if (result is Map) {
        final Object? texts = result['texts'];
        if (texts is List && texts.isNotEmpty && texts.first is Map) {
          return _str((texts.first as Map)['text']);
        }
      }
    }
    return '';
  }

  Future<String> _volcengine(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    String source = _volcengineLang(sourceLang);
    if (source == 'auto') {
      source = _volcengineLang(_inferSource(text));
    }
    final String target = _volcengineLang(targetLang) == 'auto'
        ? 'en'
        : _volcengineLang(targetLang);
    final http.Response response = await _client
        .post(
          Uri.parse('https://translate.volcengine.com/crx/translate/v1'),
          headers: {
            'content-type': 'application/json',
            'origin': 'chrome-extension://klgfhbdadaspgppeadghjjemk',
            'user-agent': _ua,
          },
          body: jsonEncode({
            'source_language': source,
            'target_language': target,
            'text': text,
          }),
        )
        .timeout(_requestTimeout);
    final Object? data = jsonDecode(utf8.decode(response.bodyBytes));
    return data is Map ? _str(data['translation']) : '';
  }

  Future<String> _caiyun(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final String from = _caiyunLang(sourceLang);
    String to = _caiyunLang(targetLang);
    if (to == 'auto') {
      to = 'en';
    }
    final http.Response response = await _client
        .post(
          Uri.parse('https://interpreter.cyapi.cn/v1/translator'),
          headers: {
            'content-type': 'application/json',
            'x-authorization': 'token ssdj273ksdiwi923bsd9',
            'user-agent':
                'caiyunInterpreter/5 CFNetwork/1404.0.5 Darwin/22.3.0',
          },
          body: jsonEncode({
            'source': text,
            'detect': from == 'auto',
            'os_type': 'ios',
            'device_id': 'F1F902F7-1780-4C88-848D-71F35D88A602',
            'trans_type': '${from}2$to',
            'media': 'text',
            'request_id': (Random().nextInt(99999) + 100000) * 1000,
            'user_id': '',
            'dict': true,
          }),
        )
        .timeout(_requestTimeout);
    final Object? data = jsonDecode(utf8.decode(response.bodyBytes));
    return data is Map ? _str(data['target']) : '';
  }

  Future<String> _transmart(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final http.Response response = await _client
        .post(
          Uri.parse('https://yi.qq.com/api/imt'),
          headers: {
            'content-type': 'application/json',
            if (!kIsWeb) 'referer': 'https://yi.qq.com/zh-CN/index',
            if (!kIsWeb) 'user-agent': _ua,
          },
          body: jsonEncode({
            'header': {
              'fn': 'auto_translation',
              'client_key': 'browser-${DateTime.now().millisecondsSinceEpoch}',
            },
            'type': 'plain',
            'model_category': 'normal',
            'source': {
              'lang': _transmartLang(sourceLang, fallback: 'auto'),
              'text_list': [text],
            },
            'target': {'lang': _transmartLang(targetLang, fallback: 'EN')},
          }),
        )
        .timeout(_requestTimeout);
    final Object? data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map) {
      final Object? rows = data['auto_translation'];
      if (rows is List) {
        return rows.whereType<String>().join();
      }
    }
    return '';
  }

  Future<String> _papago(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    String source = _papagoLang(sourceLang);
    if (source == 'auto') {
      final http.Response detect = await _client
          .post(
            Uri.parse('https://api.papago-chrome.com/v2/translate/detect'),
            headers: _papagoHeaders(),
            body: text,
          )
          .timeout(_requestTimeout);
      final Object? data = jsonDecode(utf8.decode(detect.bodyBytes));
      if (data is Map) {
        source = _str(data['langCode']);
      }
      if (source.isEmpty) {
        source = 'auto';
      }
    }
    String target = _papagoLang(targetLang);
    if (target == 'auto') {
      target = source == 'ko' ? 'en' : 'ko';
    }
    final http.Response response = await _client
        .post(
          Uri.parse('https://api.papago-chrome.com/v2/translate/openapi'),
          headers: _papagoHeaders(),
          body: jsonEncode({'source': source, 'target': target, 'text': text}),
        )
        .timeout(_requestTimeout);
    final Object? data = jsonDecode(utf8.decode(response.bodyBytes));
    return data is Map ? _str(data['translatedText']) : '';
  }

  Map<String, String> _papagoHeaders() => {
    'accept': 'application/json, text/javascript, */*; q=0.01',
    'content-type': 'application/json; charset=UTF-8',
    'origin': 'chrome-extension://enddgifdbfoefnelepppgaabobdfbcpe',
    'user-agent': _ua,
  };

  Future<String> _cnki(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final String encrypted = _encryptCnki(text);
    String token = _cnkiToken;
    if (token.isEmpty) {
      token = await _fetchCnkiToken();
    }
    Map<String, dynamic> data = await _cnkiTranslate(token, encrypted);
    if (_isCode401(data['code'])) {
      _cnkiToken = '';
      token = await _fetchCnkiToken();
      data = await _cnkiTranslate(token, encrypted);
    }
    final Object? body = data['data'];
    final String translated = body is Map ? _str(body['mResult']) : '';
    return translated.replaceAll(RegExp(r'\([^()]*智联招聘[^()]*\)'), '').trim();
  }

  Future<String> _fetchCnkiToken() async {
    final http.Response response = await _client
        .get(
          Uri.parse('https://dict.cnki.net/fyzs-front-api/getToken'),
          headers: {
            'referer': 'https://dict.cnki.net/index',
            'user-agent': _ua,
          },
        )
        .timeout(_requestTimeout);
    final Object? data = jsonDecode(utf8.decode(response.bodyBytes));
    final Object? tokenData = data is Map ? data['data'] : null;
    final String token = _firstString(tokenData);
    if (token.isEmpty) {
      throw StateError('cnki: missing token');
    }
    _cnkiToken = token;
    return token;
  }

  Future<Map<String, dynamic>> _cnkiTranslate(
    String token,
    String encrypted,
  ) async {
    final http.Response response = await _client
        .post(
          Uri.parse(
            'https://dict.cnki.net/fyzs-front-api/translate/literalTranslation',
          ),
          headers: {
            'content-type': 'application/json;charset=UTF-8',
            'origin': 'https://dict.cnki.net',
            'referer': 'https://dict.cnki.net/index',
            'token': token,
            'user-agent': _ua,
          },
          body: jsonEncode({'words': encrypted, 'translateType': null}),
        )
        .timeout(_requestTimeout);
    return (jsonDecode(utf8.decode(response.bodyBytes)) as Map)
        .cast<String, dynamic>();
  }

  Future<String> _myMemory(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    String source = _webLang(sourceLang);
    if (source == 'auto') {
      source = _inferSource(text);
    }
    if (source == 'zh') {
      source = 'zh-CN';
    }
    String target = _webLang(targetLang);
    if (target == 'zh') {
      target = 'zh-CN';
    }
    final Uri uri = Uri.https('api.mymemory.translated.net', '/get', {
      'q': text,
      'langpair': '$source|$target',
    });
    final Object? data = jsonDecode(await _get(uri));
    if (data is Map) {
      final Object? response = data['responseData'];
      if (response is Map) {
        return _str(response['translatedText']);
      }
    }
    return '';
  }

  Future<String> _libreTranslate(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    String source = sourceLang.toLowerCase();
    if (source == 'auto') {
      source = _inferSource(text);
    }
    final String target = targetLang.toLowerCase();
    final String body = jsonEncode({
      'q': text,
      'source': source,
      'target': target,
      'format': 'text',
    });
    Object? lastError;
    for (final String base in const [
      'https://translate.fedilab.app',
      'https://translate.disroot.org',
    ]) {
      try {
        final http.Response response = await _client
            .post(
              Uri.parse('$base/translate'),
              headers: {
                'accept': 'application/json',
                'content-type': 'application/json',
                'user-agent': _ua,
              },
              body: body,
            )
            .timeout(_requestTimeout);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final String contentType =
              response.headers['content-type']?.toLowerCase() ?? '';
          if (contentType.contains('application/json')) {
            final Object? data = jsonDecode(utf8.decode(response.bodyBytes));
            if (data is Map) {
              final String translated = _str(data['translatedText']);
              if (translated.isNotEmpty) {
                return translated;
              }
            }
          }
        }
        lastError = StateError('libretranslate: HTTP ${response.statusCode}');
      } catch (error) {
        lastError = error;
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    return '';
  }

  Future<String> _freeChatGpt(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final String prompt = '请将以下$sourceLang内容翻译成$targetLang，只输出译文，不要解释：\n$text';
    final http.Response response = await _client
        .post(
          Uri.parse('http://www.saviorthedistant.com/talk/askQuestion'),
          headers: {
            'content-type': 'application/json',
            'user-agent':
                'ChatWithAiRobot/5.3.0 (iPhone; iOS 16.3.1; Scale/3.00)',
          },
          body: jsonEncode({'question': prompt}),
        )
        .timeout(_requestTimeout);
    final Object? data = jsonDecode(utf8.decode(response.bodyBytes));
    return data is Map ? _firstString(data['data']) : '';
  }

  String _createDeepLBody(String text, String sourceLang, String targetLang) {
    final String effectiveTarget =
        (targetLang == 'ZH-HANT' || targetLang == 'ZH-HANS')
        ? 'ZH'
        : targetLang;
    final int id = (Random().nextInt(99999) + 100000) * 1000;
    final int iCount = 'i'.allMatches(text).length;
    final int timestamp = iCount == 0
        ? DateTime.now().millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch -
              (DateTime.now().millisecondsSinceEpoch % (iCount + 1)) +
              (iCount + 1);
    String body = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'LMT_handle_texts',
      'id': id,
      'params': {
        'texts': [
          {'text': text, 'requestAlternatives': 3},
        ],
        'splitting': 'newlines',
        'lang': {
          'source_lang_user_selected': sourceLang,
          'target_lang': effectiveTarget,
        },
        'timestamp': timestamp,
        if (targetLang == 'ZH-HANT' || targetLang == 'ZH-HANS')
          'commonJobParams': {'regionalVariant': targetLang},
      },
    });
    final String methodReplacement = ((id + 5) % 29 == 0 || (id + 3) % 13 == 0)
        ? '"method":"'
        : '"method": "';
    if (methodReplacement == '"method": "') {
      body = body.replaceFirst('"method":"', '"method": "');
    } else {
      body = body.replaceFirst('"method":"', '"method" : "');
    }
    return body;
  }

  String _normalizeDeepLLang(String value, String fallback) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    final String lower = trimmed.toLowerCase();
    if (lower == 'zh-cn' || lower == 'zh-hans') return 'ZH-HANS';
    if (lower == 'zh-tw' || lower == 'zh-hant') return 'ZH-HANT';
    if (lower.startsWith('en-')) return 'EN';
    if (lower.startsWith('pt-')) return 'PT';
    return switch (lower) {
      'de' => 'DE',
      'en' => 'EN',
      'es' => 'ES',
      'fr' => 'FR',
      'it' => 'IT',
      'ja' => 'JA',
      'ko' => 'KO',
      'nl' => 'NL',
      'pl' => 'PL',
      'pt' => 'PT',
      'ru' => 'RU',
      'zh' => 'ZH',
      'sv' => 'SV',
      'auto' => 'auto',
      _ => trimmed.toUpperCase(),
    };
  }

  String _baiduLang(String lang) {
    final String value = _reverseLang(_webLang(lang));
    return switch (value) {
      'auto' => 'auto',
      'zh' => 'zh',
      'ja' => 'jp',
      'cht' => 'cht',
      _ => value,
    };
  }

  String _caiyunLang(String lang) {
    final String value = _reverseLang(_webLang(lang));
    return switch (value) {
      'auto' => 'auto',
      'zh' || 'cht' => 'zh',
      _ => value,
    };
  }

  String _volcengineLang(String lang) {
    final String value = _reverseLang(_webLang(lang));
    return switch (value) {
      'auto' => 'auto',
      'zh' => 'zh',
      'cht' => 'zh-Hant',
      _ => value,
    };
  }

  String _papagoLang(String lang) {
    final String value = _reverseLang(_webLang(lang));
    return switch (value) {
      'zh' => 'zh-CN',
      'cht' => 'zh-TW',
      'auto' => 'auto',
      _ => value,
    };
  }

  String _tencentLang(String lang, String text, {required bool infer}) {
    final String value = _reverseLang(_webLang(lang));
    if (value == 'cht') {
      return 'zh-TW';
    }
    if (value == 'auto') {
      return infer ? _inferSource(text) : 'zh';
    }
    return value;
  }

  String _transmartLang(String lang, {required String fallback}) {
    final String value = _reverseLang(_webLang(lang));
    if (value == 'auto') {
      return fallback;
    }
    if (value == 'zh' || value == 'cht') {
      return 'ZH';
    }
    return value.toUpperCase();
  }

  String _webLang(String value) => _normalizeWebLang(value);

  String _normalizeWebLang(String value) {
    final String lang = value.trim();
    if (lang.isEmpty) {
      return 'auto';
    }
    final String lower = lang.toLowerCase();
    if (lower == 'zh-cn' || lower == 'zh-hans') return 'zh';
    if (lower == 'zh-tw' || lower == 'zh-hant') return 'zh-TW';
    if (lower.startsWith('en-')) return 'en';
    if (lower.startsWith('pt-')) return 'pt';
    return lang;
  }

  String _reverseLang(String value) {
    final String lang = _normalizeWebLang(value).toLowerCase();
    return switch (lang) {
      'zh' => 'zh',
      'zh-tw' => 'cht',
      'ja' => 'ja',
      'ko' => 'ko',
      'auto' => 'auto',
      _ => lang,
    };
  }

  String _inferSource(String text) {
    for (final int char in text.runes) {
      if (char >= 0x4E00 && char <= 0x9FFF) return 'zh';
      if (char >= 0x3040 && char <= 0x30FF) return 'ja';
      if (char >= 0xAC00 && char <= 0xD7AF) return 'ko';
      if (char >= 0x0400 && char <= 0x04FF) return 'ru';
      if (char >= 0x0600 && char <= 0x06FF) return 'ar';
      if (char >= 0x0E00 && char <= 0x0E7F) return 'th';
      if (char >= 0x0590 && char <= 0x05FF) return 'he';
    }
    return 'en';
  }

  String _createBaiduSign(String text, String gtk) {
    String shortText = text;
    final List<int> runes = text.runes.toList();
    final bool hasAstral = runes.any((int r) => r > 0xFFFF);
    if (!hasAstral && runes.length > 30) {
      final int n = runes.length;
      final int mid = n ~/ 2;
      shortText =
          String.fromCharCodes(runes.sublist(0, 10)) +
          String.fromCharCodes(runes.sublist(mid - 5, mid + 5)) +
          String.fromCharCodes(runes.sublist(n - 10));
    }
    final List<String> parts = gtk.split('.');
    final int first = parts.isNotEmpty ? int.tryParse(parts[0].trim()) ?? 0 : 0;
    final int second = parts.length > 1
        ? int.tryParse(parts[1].trim()) ?? 0
        : 0;
    int value = first;
    for (final int byte in utf8.encode(shortText)) {
      value = _tokenTransform(value + byte, '+-a^+6');
    }
    value = _tokenTransform(value, '+-3^+b+-f');
    value ^= second;
    value %= 1000000;
    return '$value.${value ^ first}';
  }

  int _tokenTransform(int value, String pattern) {
    for (int i = 0; i + 2 < pattern.length; i += 3) {
      final int shift = pattern.codeUnitAt(i + 2) >= 97
          ? pattern.codeUnitAt(i + 2) - 87
          : pattern.codeUnitAt(i + 2) - 48;
      final int shiftValue = pattern[i + 1] == '+'
          ? value >> shift
          : (value << shift) & 0xFFFFFFFF;
      if (pattern[i] == '+') {
        value = (value + shiftValue) & 0xFFFFFFFF;
      } else {
        value ^= shiftValue;
      }
    }
    return value;
  }

  String _encryptCnki(String text) {
    final Key key = Key(utf8.encode(_cnkiKey));
    final Encrypter encrypter = Encrypter(AES(key, mode: AESMode.ecb));
    final String encrypted = encrypter.encrypt(text).base64;
    return encrypted.replaceAll('/', '_').replaceAll('+', '-');
  }

  bool _isCode401(Object? value) {
    if (value is num) {
      return value.toInt() == 401;
    }
    return value?.toString() == '401';
  }

  String _md5(String value) => md5.convert(utf8.encode(value)).toString();

  String _decryptYoudao(String payload) {
    final Key key = Key(
      Uint8List.fromList(md5.convert(utf8.encode(_youdaoAesKey)).bytes),
    );
    final IV iv = IV(
      Uint8List.fromList(md5.convert(utf8.encode(_youdaoAesIv)).bytes),
    );
    String normalized = payload
        .trim()
        .replaceAll('-', '+')
        .replaceAll('_', '/');
    final int remainder = normalized.length % 4;
    if (remainder != 0) {
      normalized += '=' * (4 - remainder);
    }
    return Encrypter(AES(key, mode: AESMode.cbc)).decrypt64(normalized, iv: iv);
  }

  String _youdaoText(Object? payload) {
    if (payload is! Map) {
      return '';
    }
    final Object? rows = payload['translateResult'];
    if (rows is List) {
      final StringBuffer buffer = StringBuffer();
      for (final Object? row in rows) {
        if (row is List) {
          for (final Object? item in row) {
            if (item is Map) {
              buffer.write(_str(item['tgt']));
            }
          }
        } else if (row is Map) {
          buffer.write(_str(row['tgt']));
        }
      }
      final String text = buffer.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    final Object? translation = payload['translation'];
    if (translation is List) {
      final List<String> parts = [
        for (final Object? item in translation)
          if (item is String && item.trim().isNotEmpty) item.trim(),
      ];
      if (parts.isNotEmpty) {
        return parts.join('\n');
      }
    }
    return '';
  }

  String _str(Object? value) => value?.toString().trim() ?? '';

  String _firstString(Object? value) {
    if (value is String) {
      return value.trim();
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    if (value is Map) {
      for (final Object? key in const ['text', 'content', 'data', 'result']) {
        final String found = _firstString(value[key]);
        if (found.isNotEmpty) {
          return found;
        }
      }
    }
    if (value is List) {
      for (final Object? item in value) {
        final String found = _firstString(item);
        if (found.isNotEmpty) {
          return found;
        }
      }
    }
    return '';
  }

  String _clean(String value) =>
      value.replaceFirst(RegExp(r'^[\s，,。.;；:：]+'), '').trim();
}
