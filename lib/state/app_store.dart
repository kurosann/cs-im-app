import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/chat_repository.dart';
import '../data/remote/remote_chat_repository.dart';
import '../models/channel_status.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/forward_channel_status.dart';
import '../models/operator_profile.dart';
import '../data/translation_service.dart';
import '../models/translation_language.dart';
import '../models/translation_provider.dart';

class AppStore extends ChangeNotifier {
  AppStore(
    this._repository,
    this._translationService, {
    this.persistenceEnabled = true,
  });

  final ChatRepository _repository;
  final TranslationService _translationService;
  final bool persistenceEnabled;

  static const List<String> filters = ['全部', '待人工', 'AI', '人工'];

  static const int _mb = 1024 * 1024;

  final Map<String, int> _cacheUsage = <String, int>{
    '图片缓存': 86 * _mb,
    '视频缓存': 32 * _mb,
    '语音缓存': 6 * _mb,
    '其他': 4 * _mb,
  };

  final List<Conversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messages = {};
  final List<ChannelStatus> _channels = [];
  final List<ForwardChannelStatus> _forwardChannels = [];
  OperatorProfile? _profile;

  static const String _themeModeKey = 'settings.theme_mode';
  static const String _notificationsKey = 'settings.notifications';
  static const String _translationEnabledKey = 'settings.translation_enabled';
  static const String _translationProviderKey = 'settings.translation_provider';
  static const String _translationSourceKey = 'settings.translation_source';
  static const String _translationTargetKey = 'settings.translation_target';
  static const String _translationLatencyCheckAtKey =
      'settings.translation_latency_check_at';
  static const String _translationLatencyResultsKey =
      'settings.translation_latency_results';
  static const Duration _translationLatencyCheckInterval = Duration(
    minutes: 30,
  );
  static const int _translationLatencyConcurrency = 3;

  SharedPreferences? _preferences;
  int _filterIndex = 0;
  bool _loading = true;
  bool _refreshing = false;
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _translationEnabled = false;
  TranslationProvider _translationProvider = TranslationProvider.auto;
  TranslationLanguage _translationSource = TranslationLanguage.auto;
  TranslationLanguage _translationTarget = TranslationLanguage.auto;
  DateTime? _lastTranslationLatencyCheckAt;
  final Map<TranslationProvider, Duration?> _translationProviderLatencies = {};
  final Set<TranslationProvider> _testedTranslationProviders = {};
  final Set<TranslationProvider> _testingTranslationProviders = {};
  bool _checkingTranslationProviderLatencies = false;
  bool _disposed = false;

  bool get loading => _loading;
  int get filterIndex => _filterIndex;
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get translationEnabled => _translationEnabled;
  TranslationProvider get translationProvider => _translationProvider;
  TranslationLanguage get translationSource => _translationSource;
  TranslationLanguage get translationTarget => _translationTarget;
  Map<TranslationProvider, Duration?> get translationProviderLatencies =>
      Map.unmodifiable(_translationProviderLatencies);
  Set<TranslationProvider> get testedTranslationProviders =>
      Set.unmodifiable(_testedTranslationProviders);
  Set<TranslationProvider> get testingTranslationProviders =>
      Set.unmodifiable(_testingTranslationProviders);
  bool get checkingTranslationProviderLatencies =>
      _checkingTranslationProviderLatencies;

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  List<ChannelStatus> get channels => List.unmodifiable(_channels);

  Map<String, int> get cacheUsage => Map.unmodifiable(_cacheUsage);
  int get cacheBytes =>
      _cacheUsage.values.fold<int>(0, (int sum, int value) => sum + value);
  List<ForwardChannelStatus> get forwardChannels =>
      List.unmodifiable(_forwardChannels);
  OperatorProfile? get profile => _profile;

  int get waitingCount => _conversations
      .where((Conversation c) => c.status == ConversationStatus.waiting)
      .length;
  int get handlingCount => _conversations
      .where((Conversation c) => c.status == ConversationStatus.human)
      .length;
  int get aiHandledCount => _conversations
      .where((Conversation c) => c.status == ConversationStatus.ai)
      .length;

  List<Conversation> get filteredConversations {
    return switch (_filterIndex) {
      1 =>
        _conversations
            .where((Conversation c) => c.status == ConversationStatus.waiting)
            .toList(),
      2 =>
        _conversations
            .where((Conversation c) => c.status == ConversationStatus.ai)
            .toList(),
      3 =>
        _conversations
            .where((Conversation c) => c.status == ConversationStatus.human)
            .toList(),
      _ => List.unmodifiable(_conversations),
    };
  }

  Future<void> connect({required String account, required String token}) async {
    final ChatRepository repository = _repository;
    if (repository is RemoteChatRepository) {
      await repository.connect(account: account, token: token);
    }
  }

  Future<void> init() async {
    try {
      await _loadSettings();
      await _loadWorkspace();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_loading || _refreshing) {
      return;
    }
    _refreshing = true;
    try {
      await _loadWorkspace();
      notifyListeners();
    } catch (_) {
      // Keep the last successful snapshot when the server blips.
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _loadWorkspace() async {
    final List<Conversation> conversations = await _repository
        .fetchConversations();
    final Map<String, List<ChatMessage>> messages =
        <String, List<ChatMessage>>{};
    for (final Conversation conversation in conversations) {
      messages[conversation.id] = List.of(
        await _repository.fetchMessages(conversation.id),
      );
    }
    final List<ChannelStatus> channels = await _repository.fetchChannels();
    final List<ForwardChannelStatus> forwardChannels = await _repository
        .fetchForwardChannels();
    final OperatorProfile profile = await _repository.fetchProfile();
    _conversations
      ..clear()
      ..addAll(conversations);
    _messages
      ..clear()
      ..addAll(messages);
    _channels
      ..clear()
      ..addAll(channels);
    _forwardChannels
      ..clear()
      ..addAll(forwardChannels);
    _profile = profile;
  }

  @override
  void dispose() {
    _disposed = true;
    final ChatRepository repository = _repository;
    if (repository is RemoteChatRepository) {
      repository.close();
    }
    super.dispose();
  }

  Future<String> translateText({
    required String text,
    required TranslationLanguage source,
    required TranslationLanguage target,
    TranslationProvider provider = TranslationProvider.auto,
  }) => _translateWithFallback(
    text: text,
    source: source,
    target: target,
    provider: provider,
  );

  static const Duration _localTranslationTimeout = Duration(seconds: 3);
  static const Duration _backendTranslationTimeout = Duration(seconds: 10);

  Future<String> _translateWithFallback({
    required String text,
    required TranslationLanguage source,
    required TranslationLanguage target,
    required TranslationProvider provider,
  }) async {
    final bool backendFirst = _shouldUseBackendFirst(provider);
    final TranslationProvider localProvider = _localProviderFor(provider);
    if (backendFirst) {
      try {
        return await _repository
            .translate(text: text, source: source, target: target)
            .timeout(_backendTranslationTimeout);
      } catch (_) {
        return _translationService
            .translate(
              text: text,
              source: source,
              target: target,
              provider: localProvider,
            )
            .timeout(_localTranslationTimeout);
      }
    }

    try {
      return await _translationService
          .translate(
            text: text,
            source: source,
            target: target,
            provider: localProvider,
          )
          .timeout(_localTranslationTimeout);
    } catch (_) {
      return _repository
          .translate(text: text, source: source, target: target)
          .timeout(_backendTranslationTimeout);
    }
  }

  bool _shouldUseBackendFirst(TranslationProvider provider) {
    if (provider == TranslationProvider.auto) {
      if (_testedTranslationProviders.isEmpty) {
        return false;
      }
      return !_testedTranslationProviders.any((TranslationProvider tested) {
        final Duration? latency = _translationProviderLatencies[tested];
        return latency != null && latency <= _localTranslationTimeout;
      });
    }
    if (!_testedTranslationProviders.contains(provider)) {
      return false;
    }
    final Duration? latency = _translationProviderLatencies[provider];
    return latency == null || latency > _localTranslationTimeout;
  }

  TranslationProvider _localProviderFor(TranslationProvider provider) {
    if (provider != TranslationProvider.auto) {
      return provider;
    }
    TranslationProvider? fastestProvider;
    Duration? fastestLatency;
    for (final TranslationProvider tested in _testedTranslationProviders) {
      final Duration? latency = _translationProviderLatencies[tested];
      if (latency == null || latency > _localTranslationTimeout) {
        continue;
      }
      if (fastestLatency == null || latency < fastestLatency) {
        fastestProvider = tested;
        fastestLatency = latency;
      }
    }
    return fastestProvider ?? TranslationProvider.auto;
  }

  Future<void> _measureTranslationProviderLatency(
    TranslationProvider provider,
  ) async {
    Duration? latency;
    try {
      latency = await _translationService.measureProviderLatency(provider);
    } catch (_) {
      latency = null;
    }
    _translationProviderLatencies[provider] = latency;
    _testedTranslationProviders.add(provider);
    _testingTranslationProviders.remove(provider);
  }

  Future<void> checkTranslationProviderLatenciesIfDue() async {
    if (_checkingTranslationProviderLatencies || _disposed) {
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime? lastCheck = _lastTranslationLatencyCheckAt;
    if (lastCheck != null &&
        now.difference(lastCheck) < _translationLatencyCheckInterval) {
      if (_testedTranslationProviders.isEmpty &&
          !_checkingTranslationProviderLatencies) {
        _checkingTranslationProviderLatencies = true;
        _testingTranslationProviders
          ..clear()
          ..addAll(
            TranslationProvider.values.where(
              (TranslationProvider provider) =>
                  provider != TranslationProvider.auto,
            ),
          );
        notifyListeners();
        await _runTranslationProviderLatencyChecks();
      }
      return;
    }

    _lastTranslationLatencyCheckAt = now;
    _checkingTranslationProviderLatencies = true;
    _testingTranslationProviders
      ..clear()
      ..addAll(
        TranslationProvider.values.where(
          (TranslationProvider provider) =>
              provider != TranslationProvider.auto,
        ),
      );
    notifyListeners();

    final SharedPreferences? preferences = _preferences;
    if (persistenceEnabled && preferences != null) {
      try {
        await preferences.setInt(
          _translationLatencyCheckAtKey,
          now.millisecondsSinceEpoch,
        );
      } catch (_) {
        // A storage failure should not stop this network check.
      }
    }

    await _runTranslationProviderLatencyChecks();
  }

  Future<void> _runTranslationProviderLatencyChecks() async {
    final List<TranslationProvider> providers = TranslationProvider.values
        .where(
          (TranslationProvider provider) =>
              provider != TranslationProvider.auto,
        )
        .toList();
    int nextProviderIndex = 0;

    Future<void> runNextProbe() async {
      while (nextProviderIndex < providers.length) {
        final TranslationProvider provider = providers[nextProviderIndex++];
        await _measureTranslationProviderLatency(provider);
      }
    }

    await Future.wait<void>(
      List<Future<void>>.generate(
        _translationLatencyConcurrency,
        (_) => runNextProbe(),
      ),
    );
    _checkingTranslationProviderLatencies = false;
    if (!_disposed) {
      notifyListeners();
    }
    await _persistTranslationProviderLatencies();
  }

  Future<void> _persistTranslationProviderLatencies() async {
    if (!persistenceEnabled || _preferences == null) {
      return;
    }
    final Map<String, int> values = <String, int>{
      for (final TranslationProvider provider in _testedTranslationProviders)
        provider.name:
            _translationProviderLatencies[provider]?.inMicroseconds ?? -1,
    };
    try {
      await _preferences!.setString(
        _translationLatencyResultsKey,
        jsonEncode(values),
      );
    } catch (_) {
      // Latencies are temporary UI data; storage failure is non-fatal.
    }
  }

  Future<String> translateDraft({
    required String text,
    required TranslationLanguage source,
    required TranslationLanguage target,
    required TranslationProvider provider,
  }) => _translateWithFallback(
    text: text,
    source: source,
    target: target,
    provider: provider,
  );

  Conversation conversationById(String id) =>
      _conversations.firstWhere((Conversation c) => c.id == id);

  List<ChatMessage> messagesOf(String conversationId) =>
      List.unmodifiable(_messages[conversationId] ?? const <ChatMessage>[]);

  Future<void> clearCache() async {
    for (final String key in _cacheUsage.keys.toList()) {
      _cacheUsage[key] = 0;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await _persistString(_themeModeKey, mode.name);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (value == _notificationsEnabled) {
      return;
    }
    _notificationsEnabled = value;
    notifyListeners();
    await _persistBool(_notificationsKey, value);
  }

  Future<void> setTranslationEnabled(bool value) async {
    if (value == _translationEnabled) {
      return;
    }
    _translationEnabled = value;
    notifyListeners();
    await _persistBool(_translationEnabledKey, value);
  }

  Future<void> setTranslationProvider(TranslationProvider value) async {
    if (value == _translationProvider) {
      return;
    }
    _translationProvider = value;
    notifyListeners();
    await _persistString(_translationProviderKey, value.name);
  }

  Future<void> setTranslationSource(TranslationLanguage value) async {
    if (value == _translationSource) {
      return;
    }
    _translationSource = value;
    notifyListeners();
    await _persistString(_translationSourceKey, value.code);
  }

  Future<void> setTranslationTarget(TranslationLanguage value) async {
    if (value == _translationTarget) {
      return;
    }
    _translationTarget = value;
    notifyListeners();
    await _persistString(_translationTargetKey, value.code);
  }

  void setFilter(int index) {
    if (index == _filterIndex) {
      return;
    }
    _filterIndex = index;
    notifyListeners();
  }

  Future<void> sendAttachment(
    String conversationId, {
    required ChatMessageType type,
    String? mediaAsset,
    int? durationSeconds,
    String text = '',
  }) async {
    final ChatMessage message = await _repository.sendAttachment(
      conversationId: conversationId,
      type: type,
      mediaAsset: mediaAsset,
      durationSeconds: durationSeconds,
      text: text,
    );
    _messages.putIfAbsent(conversationId, () => <ChatMessage>[]).add(message);
    final int index = _conversations.indexWhere(
      (Conversation c) => c.id == conversationId,
    );
    if (index >= 0) {
      final String summary = text.trim().isNotEmpty
          ? text.trim()
          : switch (type) {
              ChatMessageType.image => '[图片]',
              ChatMessageType.video => '[视频]',
              ChatMessageType.audio => '[语音]',
              ChatMessageType.file => '[文件]',
              ChatMessageType.text => '',
            };
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: summary,
        time: message.time,
        unreadCount: 0,
        needsReply: false,
      );
    }
    notifyListeners();
  }

  Future<void> markRead(String conversationId) async {
    final int index = _conversations.indexWhere(
      (Conversation c) => c.id == conversationId,
    );
    if (index < 0 || _conversations[index].unreadCount == 0) {
      return;
    }
    _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
    notifyListeners();
    try {
      await _repository.markRead(conversationId);
    } catch (_) {
      // Local unread is already cleared; the server status can retry later.
    }
  }

  Future<void> sendMessage(String conversationId, String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final ChatMessage message = await _repository.sendMessage(
      conversationId: conversationId,
      text: trimmed,
    );
    _messages.putIfAbsent(conversationId, () => <ChatMessage>[]).add(message);
    final int index = _conversations.indexWhere(
      (Conversation c) => c.id == conversationId,
    );
    if (index >= 0) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: trimmed,
        time: message.time,
        unreadCount: 0,
        needsReply: false,
      );
    }
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    if (!persistenceEnabled) {
      return;
    }
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      _preferences = preferences;
      final String? themeName = preferences.getString(_themeModeKey);
      if (themeName != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (ThemeMode value) => value.name == themeName,
          orElse: () => ThemeMode.system,
        );
      }
      _notificationsEnabled =
          preferences.getBool(_notificationsKey) ?? _notificationsEnabled;
      _translationEnabled =
          preferences.getBool(_translationEnabledKey) ?? _translationEnabled;
      final String? providerName = preferences.getString(
        _translationProviderKey,
      );
      if (providerName != null) {
        _translationProvider = TranslationProvider.values.firstWhere(
          (TranslationProvider value) => value.name == providerName,
          orElse: () => TranslationProvider.auto,
        );
      }
      _translationSource = _languageFromCode(
        preferences.getString(_translationSourceKey),
        _translationSource,
      );
      _translationTarget = _languageFromCode(
        preferences.getString(_translationTargetKey),
        _translationTarget,
      );
      final int? translationLatencyCheckAt = preferences.getInt(
        _translationLatencyCheckAtKey,
      );
      if (translationLatencyCheckAt != null) {
        _lastTranslationLatencyCheckAt = DateTime.fromMillisecondsSinceEpoch(
          translationLatencyCheckAt,
        );
      }
      final String? translationLatencyResults = preferences.getString(
        _translationLatencyResultsKey,
      );
      if (translationLatencyResults != null) {
        _restoreTranslationProviderLatencies(translationLatencyResults);
      }
    } catch (_) {
      // 测试环境或平台存储不可用时保持默认值，不影响页面启动。
    }
  }

  void _restoreTranslationProviderLatencies(String encoded) {
    try {
      final Object? decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        return;
      }
      for (final MapEntry<Object?, Object?> entry in decoded.entries) {
        TranslationProvider? provider;
        for (final TranslationProvider candidate
            in TranslationProvider.values) {
          if (candidate.name == entry.key) {
            provider = candidate;
            break;
          }
        }
        if (provider != null && entry.value is int) {
          final int microseconds = entry.value as int;
          _translationProviderLatencies[provider] = microseconds < 0
              ? null
              : Duration(microseconds: microseconds);
          _testedTranslationProviders.add(provider);
        }
      }
    } catch (_) {
      // Ignore stale or malformed latency cache entries.
    }
  }

  TranslationLanguage _languageFromCode(
    String? code,
    TranslationLanguage fallback,
  ) {
    if (code == null) {
      return fallback;
    }
    return TranslationLanguage.values.firstWhere(
      (TranslationLanguage value) => value.code == code,
      orElse: () => fallback,
    );
  }

  Future<void> _persistString(String key, String value) async {
    if (!persistenceEnabled) {
      return;
    }
    final SharedPreferences? preferences = _preferences;
    if (preferences != null) {
      await preferences.setString(key, value);
    }
  }

  Future<void> _persistBool(String key, bool value) async {
    if (!persistenceEnabled) {
      return;
    }
    final SharedPreferences? preferences = _preferences;
    if (preferences != null) {
      await preferences.setBool(key, value);
    }
  }
}
