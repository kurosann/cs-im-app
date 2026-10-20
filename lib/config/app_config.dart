/// 应用级配置。纯前端阶段默认使用 Mock 数据。
abstract final class AppConfig {
  /// 后端地址。接入时通过 --dart-define=CS_IM_API_BASE=... 注入。
  static const String apiBaseUrl = String.fromEnvironment(
    'CS_IM_API_BASE',
    defaultValue: 'http://127.0.0.1:19091',
  );

  /// 纯前端阶段保持 true；接入后端时传 --dart-define=CS_IM_USE_MOCK=false。
  static const bool useMockData = bool.fromEnvironment(
    'CS_IM_USE_MOCK',
    defaultValue: true,
  );

  /// 可选。远程登录时预填访问 Token，密码栏仍可改。
  static const String accessToken = String.fromEnvironment(
    'CS_IM_ACCESS_TOKEN',
    defaultValue: '',
  );

  /// 可选。远程登录时预填值守账号，发送消息时作为 sender.id。
  static const String operatorId = String.fromEnvironment(
    'CS_IM_OPERATOR_ID',
    defaultValue: '',
  );

  static const String appVersion = '0.1.0';
}
