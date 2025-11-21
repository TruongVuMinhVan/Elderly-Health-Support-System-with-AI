import '../models/chat.dart';
import 'api_client.dart';

class ChatService {
  ChatService(this._api);

  final ApiClient _api;

  Future<ChatSessionModel> createSession() async {
    final data = await _api.post<Map<String, dynamic>>('/chat/sessions');
    return ChatSessionModel.fromJson(data);
  }

  Future<ChatSessionModel?> getActiveSession() async {
    final data = await _api.get<Map<String, dynamic>?>('/chat/sessions/active');
    if (data == null) return null;
    return ChatSessionModel.fromJson(data);
  }

  Future<ChatResponseModel> sendMessage(int sessionId, String content) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/chat/sessions/$sessionId/messages',
      body: {'content': content},
    );
    return ChatResponseModel.fromJson(data);
  }

  Future<List<ChatMessageModel>> getChatHistory(int sessionId) async {
    final data = await _api.get<List<dynamic>>('/chat/sessions/$sessionId/messages');
    return data
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> endSession(int sessionId) => _api.put<void>('/chat/sessions/$sessionId/end');
}


