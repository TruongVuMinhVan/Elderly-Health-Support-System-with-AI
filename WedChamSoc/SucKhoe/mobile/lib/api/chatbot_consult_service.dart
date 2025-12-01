import 'api_client.dart';

class ChatbotConsultService {
  ChatbotConsultService(this._api);

  final ApiClient _api;

  /// Chatbot tư vấn sơ bộ - không cần đăng nhập
  /// Gửi tin nhắn triệu chứng và nhận tư vấn
  Future<ConsultResponse> sendConsultMessage(String content, {String? sessionId}) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/chat/consult',
      body: {
        'content': content,
        if (sessionId != null) 'session_id': sessionId,
      },
      requireAuth: false, // Không cần đăng nhập
    );
    return ConsultResponse.fromJson(data);
  }

  /// Xóa lịch sử conversation (privacy)
  Future<void> clearConversation(String sessionId) async {
    await _api.delete<void>(
      '/chat/consult/$sessionId',
      requireAuth: false,
    );
  }
}

class ConsultResponse {
  final String message;
  final List<SuggestedDisease> suggestedDiseases;
  final String recommendation;
  final bool shouldSeeDoctor;
  final String sessionId;

  ConsultResponse({
    required this.message,
    required this.suggestedDiseases,
    required this.recommendation,
    required this.shouldSeeDoctor,
    required this.sessionId,
  });

  factory ConsultResponse.fromJson(Map<String, dynamic> json) {
    return ConsultResponse(
      message: json['message'] as String,
      suggestedDiseases: (json['suggested_diseases'] as List<dynamic>?)
              ?.map((e) => SuggestedDisease.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendation: json['recommendation'] as String,
      shouldSeeDoctor: json['should_see_doctor'] as bool? ?? false,
      sessionId: json['session_id'] as String,
    );
  }
}

class SuggestedDisease {
  final String diseaseName;
  final double matchScore;
  final List<String> matchedSymptoms;

  SuggestedDisease({
    required this.diseaseName,
    required this.matchScore,
    required this.matchedSymptoms,
  });

  factory SuggestedDisease.fromJson(Map<String, dynamic> json) {
    return SuggestedDisease(
      diseaseName: json['disease_name'] as String,
      matchScore: (json['match_score'] as num).toDouble(),
      matchedSymptoms: (json['matched_symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

