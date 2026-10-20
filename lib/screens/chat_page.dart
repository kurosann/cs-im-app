import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/platform_channel.dart';
import '../models/translation_language.dart';
import '../models/translation_provider.dart';
import '../state/app_scope.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/channel_avatar.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Map<String, String> _messageTranslations = <String, String>{};
  final Set<String> _translatingMessages = <String>{};
  final Set<String> _failedMessages = <String>{};
  String _translationConfigKey = '';
  String _messageListKey = '';
  int _translationGeneration = 0;

  Timer? _draftDebounce;
  String _draftTranslation = '';
  bool _translatingDraft = false;
  bool _draftTranslationFailed = false;
  bool _draftCollapsed = false;
  bool _skipNextDraftTranslation = false;
  int _draftRevision = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _controller.removeListener(_onDraftChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openTranslationSettings() {
    final AppStore store = AppScope.read(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return _TranslationSettingsSheet(
              enabled: store.translationEnabled,
              provider: store.translationProvider,
              source: store.translationSource,
              target: store.translationTarget,
              onToggle: (bool value) {
                store.setTranslationEnabled(value);
                setSheetState(() {});
                _onDraftChanged();
              },
              onSelectProvider: (TranslationProvider value) {
                store.setTranslationProvider(value);
                setSheetState(() {});
                _onDraftChanged();
              },
              onSelectSource: (TranslationLanguage value) {
                store.setTranslationSource(value);
                setSheetState(() {});
                _onDraftChanged();
              },
              onSelectTarget: (TranslationLanguage value) {
                store.setTranslationTarget(value);
                setSheetState(() {});
                _onDraftChanged();
              },
            );
          },
        );
      },
    );
  }

  void _onDraftChanged() {
    if (_skipNextDraftTranslation) {
      _skipNextDraftTranslation = false;
      return;
    }
    _draftDebounce?.cancel();
    final int revision = ++_draftRevision;
    final String input = _controller.text.trim();
    if (_draftCollapsed) {
      _draftCollapsed = false;
    }
    final AppStore store = AppScope.read(context);
    if (!store.translationEnabled || input.isEmpty) {
      if (_draftTranslation.isNotEmpty ||
          _translatingDraft ||
          _draftTranslationFailed) {
        setState(() {
          _draftTranslation = '';
          _translatingDraft = false;
          _draftTranslationFailed = false;
          _draftCollapsed = false;
        });
      }
      return;
    }
    setState(() {
      _translatingDraft = true;
      _draftTranslation = '';
      _draftTranslationFailed = false;
    });
    _draftDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final String translated = await store.translateDraft(
          text: input,
          source: store.translationSource,
          target: store.translationTarget,
          provider: store.translationProvider,
        );
        if (!mounted || revision != _draftRevision) {
          return;
        }
        setState(() {
          _draftTranslation = translated;
          _translatingDraft = false;
        });
      } catch (_) {
        if (!mounted || revision != _draftRevision) {
          return;
        }
        setState(() {
          _translatingDraft = false;
          _draftTranslationFailed = true;
        });
      }
    });
  }

  void _useDraftTranslation() {
    if (_draftTranslation.isEmpty) {
      return;
    }
    final String translated = _draftTranslation;
    _skipNextDraftTranslation = true;
    _draftDebounce?.cancel();
    _draftRevision++;
    setState(() {
      _draftTranslation = '';
      _translatingDraft = false;
      _draftTranslationFailed = false;
      _draftCollapsed = true;
    });
    _controller.value = TextEditingValue(
      text: translated,
      selection: TextSelection.collapsed(offset: translated.length),
    );
  }

  Future<void> _send() async {
    final String text = _controller.text;
    if (text.trim().isEmpty) {
      return;
    }
    _draftDebounce?.cancel();
    _draftRevision++;
    if (_draftTranslation.isNotEmpty ||
        _translatingDraft ||
        _draftTranslationFailed ||
        _draftCollapsed) {
      setState(() {
        _draftTranslation = '';
        _translatingDraft = false;
        _draftTranslationFailed = false;
        _draftCollapsed = false;
      });
    }
    try {
      await AppScope.read(context).sendMessage(widget.conversationId, text);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    _controller.clear();
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (BuildContext sheetContext) => _AttachmentSheet(
        onPick: (_AttachmentKind kind) {
          Navigator.of(sheetContext).pop();
          _sendMockAttachment(kind);
        },
      ),
    );
  }

  Future<void> _sendMockAttachment(_AttachmentKind kind) async {
    if (!AppConfig.useMockData) {
      await _sendRemoteAttachment(kind);
      return;
    }
    final AppStore store = AppScope.read(context);
    final ChatMessageType type;
    final String text;
    String? asset;
    int? duration;
    switch (kind) {
      case _AttachmentKind.image:
        type = ChatMessageType.image;
        text = '';
        asset = 'assets/media/order-screenshot.png';
      case _AttachmentKind.video:
        type = ChatMessageType.video;
        text = '';
        asset = 'assets/media/video-thumb.png';
        duration = 8;
      case _AttachmentKind.file:
        type = ChatMessageType.file;
        text = '售后资料.pdf';
    }
    await store.sendAttachment(
      widget.conversationId,
      type: type,
      mediaAsset: asset,
      durationSeconds: duration,
      text: text,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已添加示例${kind.label}')));
    _scrollToEnd();
  }

  Future<void> _sendRemoteAttachment(_AttachmentKind kind) async {
    final String? url = await _askMediaUrl(kind);
    if (url == null || !mounted) {
      return;
    }
    final ChatMessageType type = switch (kind) {
      _AttachmentKind.image => ChatMessageType.image,
      _AttachmentKind.video => ChatMessageType.video,
      _AttachmentKind.file => ChatMessageType.file,
    };
    try {
      await AppScope.read(context).sendAttachment(
        widget.conversationId,
        type: type,
        mediaAsset: url,
        text: type == ChatMessageType.file ? _fileNameFromUrl(url) : '',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已发送${kind.label}')));
    _scrollToEnd();
  }

  Future<String?> _askMediaUrl(_AttachmentKind kind) {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('发送${kind.label}'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'https://',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    final String url = controller.text.trim();
                    final Uri? parsed = Uri.tryParse(url);
                    if (parsed == null ||
                        (parsed.scheme != 'http' && parsed.scheme != 'https') ||
                        parsed.host.isEmpty) {
                      setDialogState(() {
                        errorText = '需要 http 或 https 地址';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(url);
                  },
                  child: const Text('发送'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _fileNameFromUrl(String url) {
    final String segment = Uri.parse(url).pathSegments
        .lastWhere((String item) => item.isNotEmpty, orElse: () => '文件');
    return Uri.decodeComponent(segment);
  }

  void _showCustomerSheet(Conversation conversation) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      isScrollControlled: true,
      builder: (BuildContext sheetContext) =>
          _CustomerInfoSheet(conversation: conversation),
    );
  }

  String? _translationFor(ChatMessage message) =>
      _messageTranslations[message.id];

  void _syncMessageTranslations(AppStore store, List<ChatMessage> messages) {
    final String configKey = [
      store.translationEnabled,
      store.translationProvider.name,
      store.translationSource.code,
      store.translationTarget.code,
    ].join('|');
    final String listKey = messages
        .map((ChatMessage message) => '${message.id}:${message.text}')
        .join('\u0001');
    final bool configChanged = configKey != _translationConfigKey;
    if (configChanged) {
      _translationConfigKey = configKey;
      _translationGeneration++;
      _messageTranslations.clear();
      _translatingMessages.clear();
      _failedMessages.clear();
      _messageListKey = '';
    }
    if (!store.translationEnabled) {
      _messageListKey = listKey;
      return;
    }
    if (!configChanged && listKey == _messageListKey) {
      return;
    }
    _messageListKey = listKey;
    final List<ChatMessage> pending = [
      for (final ChatMessage message in messages)
        if (message.sender != ChatSender.system &&
            message.type == ChatMessageType.text &&
            message.text.trim().isNotEmpty &&
            !_messageTranslations.containsKey(message.id) &&
            !_translatingMessages.contains(message.id) &&
            !_failedMessages.contains(message.id))
          message,
    ];
    if (pending.isEmpty) {
      return;
    }
    _translatingMessages.addAll(
      pending.map((ChatMessage message) => message.id),
    );
    final int generation = _translationGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _translationGeneration) {
        return;
      }
      _translateMessages(store, pending, generation);
    });
  }

  Future<void> _translateMessages(
    AppStore store,
    List<ChatMessage> messages,
    int generation,
  ) async {
    for (final ChatMessage message in messages) {
      if (!mounted || generation != _translationGeneration) {
        return;
      }
      try {
        final String translated = await store.translateText(
          text: message.text,
          source: store.translationSource,
          target: store.translationTarget,
          provider: store.translationProvider,
        );
        if (!mounted || generation != _translationGeneration) {
          return;
        }
        setState(() {
          _translatingMessages.remove(message.id);
          if (translated.trim().isEmpty) {
            _failedMessages.add(message.id);
          } else {
            _messageTranslations[message.id] = translated;
          }
        });
      } catch (_) {
        if (!mounted || generation != _translationGeneration) {
          return;
        }
        setState(() {
          _translatingMessages.remove(message.id);
          _failedMessages.add(message.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);
    final Conversation conversation = store.conversationById(
      widget.conversationId,
    );
    final List<ChatMessage> messages = store.messagesOf(widget.conversationId);
    _syncMessageTranslations(store, messages);
    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ColoredBox(
            color: AppColors.chatBackground,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListView.builder(
                    key: const ValueKey('chat-message-list'),
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.paddingOf(context).top + 76,
                      16,
                      180,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ChatMessage message = messages[index];
                      return _MessageBubble(
                        message: message,
                        translatedText: _translationFor(message),
                        translationLoading: _translatingMessages.contains(
                          message.id,
                        ),
                        translationFailed: _failedMessages.contains(message.id),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _ChatHeader(
                    conversation: conversation,
                    onBack: () => Navigator.of(context).pop(),
                    onMore: () => _showCustomerSheet(conversation),
                    translationEnabled: store.translationEnabled,
                    onTranslation: _openTranslationSettings,
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 4,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (store.translationEnabled &&
                            !_draftCollapsed &&
                            (_translatingDraft ||
                                _draftTranslation.isNotEmpty ||
                                _draftTranslationFailed))
                          _DraftTranslationCard(
                            translating: _translatingDraft,
                            translation: _draftTranslation,
                            failed: _draftTranslationFailed,
                            onUse: _useDraftTranslation,
                            onCollapse: () =>
                                setState(() => _draftCollapsed = true),
                          ),
                        if (store.translationEnabled &&
                            !_draftCollapsed &&
                            (_translatingDraft ||
                                _draftTranslation.isNotEmpty ||
                                _draftTranslationFailed))
                          const SizedBox(height: 8),
                        _Composer(
                          controller: _controller,
                          onSend: _send,
                          onAttach: _showAttachmentSheet,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.conversation,
    required this.onBack,
    required this.onMore,
    required this.translationEnabled,
    required this.onTranslation,
  });

  final Conversation conversation;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final bool translationEnabled;
  final VoidCallback onTranslation;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.chatBackground,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(
            children: [
              _HeaderCircleButton(
                tooltip: '返回',
                onTap: onBack,
                icon: Icons.arrow_back_ios_new_rounded,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: '打开客户信息',
                  child: InkWell(
                    key: const ValueKey('chat-contact-info'),
                    onTap: onMore,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          ChannelAvatar(conversation: conversation, size: 44),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              conversation.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderPillButton(
                      tooltip: '翻译设置',
                      onTap: onTranslation,
                      icon: Icons.translate_rounded,
                      active: translationEnabled,
                    ),
                    _HeaderPillButton(
                      tooltip: '客户信息',
                      onTap: onMore,
                      icon: Icons.more_horiz_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.tooltip,
    required this.onTap,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Icon(icon, size: 19, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

class _HeaderPillButton extends StatelessWidget {
  const _HeaderPillButton({
    required this.tooltip,
    required this.onTap,
    required this.icon,
    this.active = false,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 44,
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        splashRadius: 20,
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? AppColors.onAccent : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _TranslationSettingsSheet extends StatelessWidget {
  const _TranslationSettingsSheet({
    required this.enabled,
    required this.provider,
    required this.source,
    required this.target,
    required this.onToggle,
    required this.onSelectProvider,
    required this.onSelectSource,
    required this.onSelectTarget,
  });

  final bool enabled;
  final TranslationProvider provider;
  final TranslationLanguage source;
  final TranslationLanguage target;
  final ValueChanged<bool> onToggle;
  final ValueChanged<TranslationProvider> onSelectProvider;
  final ValueChanged<TranslationLanguage> onSelectSource;
  final ValueChanged<TranslationLanguage> onSelectTarget;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lavenderDeep,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '翻译设置',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '翻译',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '开启后展示消息译文，并启用边写边译',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: onToggle,
                    activeThumbColor: AppColors.onAccent,
                    activeTrackColor: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _FieldLabel('翻译源'),
              const SizedBox(height: 6),
              _ExpandableSelect<TranslationProvider>(
                key: const ValueKey('translation-provider-dropdown'),
                value: provider,
                items: TranslationProvider.values,
                labelOf: (TranslationProvider item) => item.label,
                onChanged: onSelectProvider,
              ),
              const SizedBox(height: 12),
              const _FieldLabel('源语言'),
              const SizedBox(height: 6),
              _ExpandableSelect<TranslationLanguage>(
                key: const ValueKey('translation-source-dropdown'),
                value: source,
                items: TranslationLanguage.values,
                labelOf: (TranslationLanguage item) => item.sourceLabel,
                onChanged: onSelectSource,
              ),
              const SizedBox(height: 12),
              const _FieldLabel('目标语言'),
              const SizedBox(height: 6),
              _ExpandableSelect<TranslationLanguage>(
                key: const ValueKey('translation-target-dropdown'),
                value: target,
                items: TranslationLanguage.values,
                labelOf: (TranslationLanguage item) => item.targetLabel,
                onChanged: onSelectTarget,
              ),
              const SizedBox(height: 12),
              Text(
                '译文由第三方机器翻译服务生成，请勿输入敏感信息。',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.inkSoft,
      ),
    );
  }
}

class _ExpandableSelect<T> extends StatefulWidget {
  const _ExpandableSelect({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  State<_ExpandableSelect<T>> createState() => _ExpandableSelectState<T>();
}

class _ExpandableSelectState<T> extends State<_ExpandableSelect<T>> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.labelOf(widget.value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: widget.items.length,
              itemBuilder: (BuildContext context, int index) {
                final T item = widget.items[index];
                final bool selected = item == widget.value;
                return InkWell(
                  onTap: () {
                    widget.onChanged(item);
                    setState(() => _expanded = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    color: selected ? AppColors.lavender : Colors.transparent,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.labelOf(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.ink,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    this.translatedText,
    this.translationLoading = false,
    this.translationFailed = false,
  });

  final ChatMessage message;
  final String? translatedText;
  final bool translationLoading;
  final bool translationFailed;

  @override
  Widget build(BuildContext context) {
    if (message.sender == ChatSender.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            message.text,
            style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
          ),
        ),
      );
    }
    final bool outgoing = message.sender == ChatSender.agent;
    if (message.type != ChatMessageType.text) {
      return _bubble(
        outgoing: outgoing,
        padding: const EdgeInsets.all(6),
        child: _mediaContent(context, outgoing),
      );
    }
    return _bubble(
      outgoing: outgoing,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: _textContent(outgoing),
    );
  }

  Widget _bubble({
    required bool outgoing,
    required EdgeInsetsGeometry padding,
    required Widget child,
  }) {
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        constraints: const BoxConstraints(maxWidth: 360),
        padding: padding,
        decoration: BoxDecoration(
          color: outgoing ? AppColors.solid : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: outgoing ? null : Border.all(color: AppColors.cardBorder),
          boxShadow: outgoing
              ? null
              : [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }

  Widget _textContent(bool outgoing) {
    final String? translation = translatedText;
    final Color textColor = outgoing ? AppColors.onSolid : AppColors.ink;
    final Color translationColor = outgoing
        ? AppColors.onSolid.withValues(alpha: 0.7)
        : AppColors.slate500;
    final Color timeColor = outgoing
        ? AppColors.onSolid.withValues(alpha: 0.45)
        : AppColors.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.sender == ChatSender.ai)
          Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: Text(
              'AI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.muted,
              ),
            ),
          ),
        Text(
          message.text,
          style: TextStyle(fontSize: 15, height: 1.45, color: textColor),
        ),
        if ((translation != null && translation.isNotEmpty) ||
            translationLoading ||
            translationFailed) ...[
          const SizedBox(height: 12),
          _DashedDivider(
            color: outgoing
                ? AppColors.onSolid.withValues(alpha: 0.25)
                : AppColors.cardBorder,
          ),
          const SizedBox(height: 10),
          Text(
            translationLoading
                ? '翻译中…'
                : translationFailed
                ? '翻译失败'
                : translation ?? '',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: translationFailed ? AppColors.danger : translationColor,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(message.time, style: TextStyle(fontSize: 11.5, color: timeColor)),
      ],
    );
  }

  Widget _mediaContent(BuildContext context, bool outgoing) {
    final Color textColor = outgoing ? Colors.white : AppColors.ink;
    final Color translationColor = outgoing
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.slate500;
    final Color timeColor = outgoing
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (message.type) {
          ChatMessageType.image => _imageContent(context),
          ChatMessageType.video => _videoContent(context),
          ChatMessageType.audio => _VoiceMessageBubble(
            message: message,
            outgoing: outgoing,
          ),
          ChatMessageType.file => _fileContent(outgoing),
          ChatMessageType.text => const SizedBox.shrink(),
        },
        if (message.text.isNotEmpty && message.type != ChatMessageType.file)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              message.text,
              style: TextStyle(fontSize: 14, height: 1.4, color: textColor),
            ),
          ),
        if (translatedText != null && translatedText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Text(
              translatedText!,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: translationColor,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
          child: Text(
            message.time,
            style: TextStyle(fontSize: 11, color: timeColor),
          ),
        ),
      ],
    );
  }

  Widget _fileContent(bool outgoing) {
    final Color textColor = outgoing ? Colors.white : AppColors.ink;
    final Color subColor = outgoing
        ? AppColors.onSolid.withValues(alpha: 0.6)
        : AppColors.muted;
    final Color background = outgoing
        ? AppColors.onSolid.withValues(alpha: 0.1)
        : AppColors.page;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: outgoing
                  ? AppColors.onSolid.withValues(alpha: 0.15)
                  : AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              size: 20,
              color: outgoing ? AppColors.onSolid : AppColors.inkSoft,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text.isEmpty ? '附件' : message.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PDF · 1.2 MB',
                  style: TextStyle(fontSize: 11, color: subColor),
                ),
              ],
            ),
          ),
          Icon(
            Icons.download_rounded,
            size: 18,
            color: outgoing
                ? AppColors.onSolid.withValues(alpha: 0.7)
                : AppColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _imageContent(BuildContext context) {
    final String? asset = message.mediaAsset;
    if (asset == null) {
      return const _MissingMedia();
    }
    return GestureDetector(
      key: ValueKey('image_${message.id}'),
      onTap: () => _openImagePreview(context, asset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(asset, width: 240, height: 168, fit: BoxFit.cover),
      ),
    );
  }

  Widget _videoContent(BuildContext context) {
    final String? asset = message.mediaAsset;
    final int duration = message.durationSeconds ?? 0;
    return GestureDetector(
      key: ValueKey('video_${message.id}'),
      onTap: asset == null ? null : () => _openVideoPreview(context, asset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 240,
          height: 135,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (asset != null)
                Image.asset(asset, fit: BoxFit.cover)
              else
                ColoredBox(color: AppColors.solid),
              const ColoredBox(color: Color(0x33000000)),
              Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openImagePreview(BuildContext context, String asset) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _openVideoPreview(BuildContext context, String asset) {
    final int duration = message.durationSeconds ?? 0;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) => Dialog(
        backgroundColor: AppColors.solid,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(asset, fit: BoxFit.cover),
                  const ColoredBox(color: Color(0x33000000)),
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                '视频消息 · ${_formatDuration(duration)} · 播放将在接入媒体服务后提供',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final int minutes = seconds ~/ 60;
  final int rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

class _MissingMedia extends StatelessWidget {
  const _MissingMedia();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.image_not_supported_outlined, color: AppColors.muted),
    );
  }
}

class _VoiceMessageBubble extends StatefulWidget {
  const _VoiceMessageBubble({required this.message, required this.outgoing});

  final ChatMessage message;
  final bool outgoing;

  @override
  State<_VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<_VoiceMessageBubble> {
  static const List<double> _waveHeights = [
    8,
    14,
    20,
    12,
    18,
    24,
    10,
    16,
    22,
    14,
    18,
    26,
    12,
    20,
    16,
    10,
    18,
    22,
    14,
    18,
    12,
    8,
  ];

  Timer? _timer;
  bool _playing = false;
  double _progress = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    final int durationMs = (widget.message.durationSeconds ?? 10) * 1000;
    setState(() {
      _playing = true;
      _progress = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 200), (Timer timer) {
      if (!mounted) {
        return;
      }
      setState(() {
        _progress += 200 / durationMs;
        if (_progress >= 1) {
          _progress = 1;
          _playing = false;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool outgoing = widget.outgoing;
    final Color activeColor = outgoing ? AppColors.onSolid : AppColors.ink;
    final Color inactiveColor = outgoing
        ? AppColors.onSolid.withValues(alpha: 0.24)
        : AppColors.lavenderDeep;
    final Color buttonColor = outgoing ? AppColors.onSolid : AppColors.solid;
    final Color iconColor = outgoing ? AppColors.solid : AppColors.onSolid;
    return Row(
      key: ValueKey('audio_${widget.message.id}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: buttonColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < _waveHeights.length; i++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: _waveHeights[i],
                    decoration: BoxDecoration(
                      color: i / _waveHeights.length <= _progress
                          ? activeColor
                          : inactiveColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _formatDuration(widget.message.durationSeconds ?? 10),
          style: TextStyle(
            fontSize: 12,
            color: outgoing
                ? AppColors.onSolid.withValues(alpha: 0.7)
                : AppColors.slate500,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const double dashWidth = 3;
    const double dashSpace = 3;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + dashWidth > size.width ? size.width : x + dashWidth, 0),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

enum _AttachmentKind { image, video, file }

extension _AttachmentKindX on _AttachmentKind {
  String get label => switch (this) {
    _AttachmentKind.image => '图片',
    _AttachmentKind.video => '视频',
    _AttachmentKind.file => '文件',
  };

  IconData get icon => switch (this) {
    _AttachmentKind.image => Icons.image_outlined,
    _AttachmentKind.video => Icons.videocam_outlined,
    _AttachmentKind.file => Icons.insert_drive_file_outlined,
  };
}

class _AttachmentSheet extends StatelessWidget {
  const _AttachmentSheet({required this.onPick});

  final ValueChanged<_AttachmentKind> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lavenderDeep,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '添加附件',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              for (final _AttachmentKind kind in _AttachmentKind.values)
                _AttachmentOption(kind: kind, onTap: () => onPick(kind)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({required this.kind, required this.onTap});

  final _AttachmentKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.page,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.lavender,
                shape: BoxShape.circle,
              ),
              child: Icon(kind.icon, size: 20, color: AppColors.inkSoft),
            ),
            const SizedBox(width: 12),
            Text(
              kind.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _CustomerInfoSheet extends StatelessWidget {
  const _CustomerInfoSheet({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lavenderDeep,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '客户信息',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ChannelAvatar(conversation: conversation, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          conversation.channel.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 12),
              _SheetInfoLine(
                label: '业务渠道',
                trailing: Text(conversation.channel.label, style: _valueStyle),
              ),
              const SizedBox(height: 10),
              _SheetInfoLine(
                label: '当前状态',
                trailing: _StatusPill(status: conversation.status),
              ),
              const SizedBox(height: 10),
              _SheetInfoLine(
                label: '负责人',
                trailing: Text(conversation.assignee, style: _valueStyle),
              ),
              const SizedBox(height: 16),
              const Text(
                '转发去向',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              if (conversation.forwardTargets.isEmpty)
                Text(
                  '未配置',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final String target in conversation.forwardTargets)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          target,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final TextStyle _valueStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: AppColors.ink,
);

class _SheetInfoLine extends StatelessWidget {
  const _SheetInfoLine({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.slate500)),
        const Spacer(),
        trailing,
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ConversationStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (status) {
      ConversationStatus.waiting => (AppColors.red50, AppColors.red600),
      ConversationStatus.human => (AppColors.blue50, AppColors.blue600),
      ConversationStatus.ai => (AppColors.emerald50, AppColors.emerald600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
  }
}

class _DraftTranslationCard extends StatelessWidget {
  const _DraftTranslationCard({
    required this.translating,
    required this.translation,
    required this.failed,
    required this.onUse,
    required this.onCollapse,
  });

  final bool translating;
  final String translation;
  final bool failed;
  final VoidCallback onUse;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate_rounded, size: 15, color: AppColors.inkSoft),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '草稿译文',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              if (translating)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              IconButton(
                onPressed: onCollapse,
                tooltip: '收起译文',
                splashRadius: 16,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 20,
                  color: AppColors.inkSoft,
                ),
              ),
              if (!translating && translation.isNotEmpty)
                IconButton(
                  onPressed: onUse,
                  tooltip: '使用译文',
                  splashRadius: 16,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.swap_vert_rounded,
                    size: 20,
                    color: AppColors.ink,
                  ),
                ),
            ],
          ),
          if (failed)
            Padding(
              padding: EdgeInsets.only(left: 23, top: 2),
              child: Text(
                '翻译失败，请重试',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            )
          else if (translation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(23, 2, 4, 0),
              child: SelectableText(
                translation,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.slate700,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: 23, top: 2),
            child: Text(
              '机器翻译，仅供参考',
              style: TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.frost,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.frostBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.frostShadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Semantics(
                button: true,
                label: '添加附件',
                child: Tooltip(
                  message: '添加附件',
                  child: GestureDetector(
                    onTap: onAttach,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 22,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: '输入消息…',
                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: '发送',
                child: GestureDetector(
                  onTap: onSend,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: AppColors.onAccent,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
