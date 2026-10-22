import 'dart:convert';

import 'package:http/http.dart' as http;

class ImApiException implements Exception {
  ImApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

/// Talks to cs-im-server's admin JSON envelope: `{code, data}` or `{code, message}`.
class ImApiClient {
  ImApiClient({
    required String baseUrl,
    required this.token,
    http.Client? client,
  }) : baseUrl = _normalizeBase(baseUrl),
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final String baseUrl;
  String token;
  final http.Client _client;
  final bool _ownsClient;

  static String _normalizeBase(String baseUrl) {
    final String trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      return 'http://127.0.0.1:19091';
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _send(
      'POST',
      path,
      body: body,
      authenticated: authenticated,
    ).timeout(timeout);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    if (authenticated && token.trim().isEmpty) {
      throw ImApiException('缺少访问 Token');
    }
    final Uri uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final http.Request request = http.Request(method, uri);
    if (authenticated) {
      request.headers['Authorization'] = 'Bearer ${token.trim()}';
    }
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.StreamedResponse streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 15));
    final String raw = await streamed.stream.bytesToString();
    return _decode(streamed.statusCode, raw);
  }

  dynamic _decode(int statusCode, String raw) {
    dynamic body;
    if (raw.trim().isEmpty) {
      body = <String, dynamic>{};
    } else {
      try {
        body = jsonDecode(raw);
      } on FormatException {
        throw ImApiException('服务端返回了无法解析的响应', statusCode: statusCode);
      }
    }
    final Map<String, dynamic>? payload = body is Map<String, dynamic>
        ? body
        : body is Map
        ? Map<String, dynamic>.from(body)
        : null;
    final String? code = payload?['code']?.toString();
    final String message = payload?['message']?.toString() ?? '请求失败';
    if (statusCode >= 400 || (code != null && code != 'OK')) {
      throw ImApiException(message, statusCode: statusCode, code: code);
    }
    if (payload != null && payload.containsKey('data')) {
      return payload['data'];
    }
    return payload ?? body;
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

List<Map<String, dynamic>> asJsonMaps(dynamic data) {
  if (data is! List) {
    return const <Map<String, dynamic>>[];
  }
  return data
      .whereType<Map>()
      .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, dynamic> asJsonMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw ImApiException('服务端返回了无法识别的数据');
}
