import 'dart:convert';

final RegExp _numericEntity = RegExp(r'&#(x?[0-9a-fA-F]+);');
final RegExp _cjk = RegExp(r'[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]');
final RegExp _mojibakeMarker = RegExp(r'[ÃÂäåæçèéêëìíîïñòóôõöùúûüýÿ]');
final RegExp _controlCharacter = RegExp(
  r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]',
);

const Map<String, String> _namedEntities = <String, String>{
  '&amp;': '&',
  '&apos;': "'",
  '&gt;': '>',
  '&lt;': '<',
  '&nbsp;': ' ',
  '&quot;': '"',
  '&#39;': "'",
};

/// 修正第三方翻译接口常见的文本编码问题。
///
/// - 解码 HTML 数字实体和常用命名实体；
/// - 尝试修复 UTF-8 字节被按 Latin-1 解码后产生的乱码；
/// - 移除控制字符，保留 U+FFFD 供上层判断是否需要回退到其它翻译源。
String normalizeTranslatedText(String input) {
  String value = input;
  value = value.replaceAllMapped(_numericEntity, (Match match) {
    final String raw = match.group(1) ?? '';
    final bool hexadecimal = raw.startsWith('x') || raw.startsWith('X');
    final int? codePoint = int.tryParse(
      hexadecimal ? raw.substring(1) : raw,
      radix: hexadecimal ? 16 : 10,
    );
    if (codePoint == null || codePoint <= 0 || codePoint > 0x10FFFF) {
      return match.group(0) ?? '';
    }
    return String.fromCharCode(codePoint);
  });
  for (final MapEntry<String, String> entry in _namedEntities.entries) {
    value = value.replaceAll(entry.key, entry.value);
  }
  value = _repairLatin1Mojibake(value);
  return value.replaceAll(_controlCharacter, '').trim();
}

bool containsReplacementCharacter(String value) => value.contains('\uFFFD');

String _repairLatin1Mojibake(String value) {
  if (!_mojibakeMarker.hasMatch(value)) {
    return value;
  }
  final List<int> bytes = <int>[];
  for (final int rune in value.runes) {
    final int? byte = _cp1252Reverse[rune] ?? (rune <= 0xFF ? rune : null);
    if (byte == null) {
      return value;
    }
    bytes.add(byte);
  }
  try {
    final String decoded = utf8.decode(bytes);
    if (_cjk.hasMatch(decoded) && !_cjk.hasMatch(value)) {
      return decoded;
    }
  } on FormatException {
    // 不是有效的 UTF-8 字节序列，保留原文。
  }
  return value;
}

const Map<int, int> _cp1252Reverse = <int, int>{
  0x20AC: 0x80,
  0x201A: 0x82,
  0x0192: 0x83,
  0x201E: 0x84,
  0x2026: 0x85,
  0x2020: 0x86,
  0x2021: 0x87,
  0x02C6: 0x88,
  0x2030: 0x89,
  0x0160: 0x8A,
  0x2039: 0x8B,
  0x0152: 0x8C,
  0x017D: 0x8E,
  0x2018: 0x91,
  0x2019: 0x92,
  0x201C: 0x93,
  0x201D: 0x94,
  0x2022: 0x95,
  0x2013: 0x96,
  0x2014: 0x97,
  0x02DC: 0x98,
  0x2122: 0x99,
  0x0161: 0x9A,
  0x203A: 0x9B,
  0x0153: 0x9C,
  0x017E: 0x9E,
  0x0178: 0x9F,
};
