import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/chat_repository.dart';
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

  SharedPreferences? _preferences;
  int _filterIndex = 0;
  bool _loading = true;
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _translationEnabled = false;
  TranslationProvider _translationProvider = TranslationProvider.auto;
  TranslationLanguage _translationSource = TranslationLanguage.auto;
  TranslationLanguage _translationTarget = TranslationLanguage.auto;

  bool get loading => _loading;
  int get filterIndex => _filterIndex;
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get translationEnabled => _translationEnabled;
  TranslationProvider get translationProvider => _translationProvider;
  TranslationLanguage get translationSource => _translationSource;
  TranslationLanguage get translationTarget => _translationTarget;

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

  Future<void> init() async {
    try {
      await _loadSettings();
      final List<Conversation> conversations = await _repository
          .fetchConversations();
      _conversations
        ..clear()
        ..addAll(conversations);
      _messages.clear();
      for (final Conversation conversation in conversations) {
        _messages[conversation.id] = List.of(
          await _repository.fetchMessages(conversation.id),
        );
      }
      _channels
        ..clear()
        ..addAll(await _repository.fetchChannels());
      _forwardChannels
        ..clear()
        ..addAll(await _repository.fetchForwardChannels());
      _profile = await _repository.fetchProfile();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> translateText({
    required String text,
    required TranslationLanguage source,
    required TranslationLanguage target,
    TranslationProvider provider = TranslationProvider.auto,
  }) => _translationService.translate(
    text: text,
    source: source,
    target: target,
    provider: provider,
  );

  Future<String> translateDraft({
    required String text,
    required TranslationLanguage source,
    required TranslationLanguage target,
    required TranslationProvider provider,
  }) => _translationService.translate(
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
    await _repository.markRead(conversationId);
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
    } catch (_) {
      // 测试环境或平台存储不可用时保持默认值，不影响页面启动。
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
