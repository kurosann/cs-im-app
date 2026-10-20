import 'translation_language.dart';

enum ChatSender { customer, agent, ai, system }

enum ChatMessageType { text, image, video, audio, file }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.time,
    this.type = ChatMessageType.text,
    this.mediaAsset,
    this.durationSeconds,
    this.translatedText,
    this.translatedLanguage,
  });

  final String id;
  final String text;
  final ChatSender sender;
  final String time;
  final ChatMessageType type;

  /// 媒体资源（当前为本地 asset；接入后端后替换为媒体 URL）。
  final String? mediaAsset;

  /// 语音 / 视频时长（秒）。
  final int? durationSeconds;

  /// Mock 阶段的译文；接入后端后由翻译接口返回。
  final String? translatedText;

  /// 译文语言，用于「自动 / 中文 / 英语」筛选。
  final TranslationLanguage? translatedLanguage;
}
