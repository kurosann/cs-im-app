import '../config/app_config.dart';
import 'chat_repository.dart';
import 'mock_chat_repository.dart';
import 'remote/remote_chat_repository.dart';

ChatRepository createChatRepository() {
  if (AppConfig.useMockData) {
    return MockChatRepository();
  }
  return RemoteChatRepository(baseUrl: AppConfig.apiBaseUrl);
}
