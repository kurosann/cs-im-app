/// 应用级配置。纯前端阶段默认使用 Mock 数据。
abstract final class AppConfig {
  /// 后端地址，接入时通过 --dart-define=CS_IM_API_BASE=... 注入。
  static const String apiBaseUrl = String.fromEnvironment(
    'CS_IM_API_BASE',
    defaultValue: '',
  );

  /// V1 纯前端阶段保持 true；接入后端时传 --dart-define=CS_IM_USE_MOCK=false。
  static const bool useMockData = bool.fromEnvironment(
    'CS_IM_USE_MOCK',
    defaultValue: true,
  );

  static const String appVersion = '0.1.0';
}
