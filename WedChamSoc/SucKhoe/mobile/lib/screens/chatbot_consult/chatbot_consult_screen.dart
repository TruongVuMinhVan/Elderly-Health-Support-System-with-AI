import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/chatbot_consult_service.dart';
import '../../styles/theme.dart';

class ChatbotConsultScreen extends StatefulWidget {
  const ChatbotConsultScreen({super.key});

  @override
  State<ChatbotConsultScreen> createState() => _ChatbotConsultScreenState();
}

class _ChatbotConsultScreenState extends State<ChatbotConsultScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _service = ChatbotConsultService(ApiClient());

  String? _sessionId;
  List<ConsultMessage> _messages = [];
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages = [
        ConsultMessage(
          content:
              'Xin chào! Tôi là chatbot tư vấn sơ bộ về sức khỏe da liễu. Hãy mô tả các triệu chứng bạn đang gặp phải.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    // Add user message immediately
    final userMessage = ConsultMessage(
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages = [..._messages, userMessage];
      _isSending = true;
      _error = null;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Send message to API
      final response = await _service.sendConsultMessage(
        message,
        sessionId: _sessionId,
      );

      // Update session ID
      if (_sessionId == null) {
        _sessionId = response.sessionId;
      }

      // Add AI response
      setState(() {
        _messages = [
          ..._messages,
          ConsultMessage(
            content: response.message,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ];

        // Add suggested diseases if any
        if (response.suggestedDiseases.isNotEmpty) {
          final suggestionsText = response.suggestedDiseases
              .map((d) => '• ${d.diseaseName} (${(d.matchScore * 100).toStringAsFixed(0)}% khớp)')
              .join('\n');
          _messages.add(
            ConsultMessage(
              content: 'Các bệnh có thể:\n$suggestionsText',
              isUser: false,
              timestamp: DateTime.now(),
              isSuggestion: true,
            ),
          );
        }

        // Add recommendation
        if (response.recommendation.isNotEmpty) {
          _messages.add(
            ConsultMessage(
              content: response.recommendation,
              isUser: false,
              timestamp: DateTime.now(),
              isRecommendation: true,
              shouldSeeDoctor: response.shouldSeeDoctor,
            ),
          );
        }
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = 'Không thể gửi tin nhắn. Vui lòng thử lại.';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tư Vấn Sơ Bộ'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _sessionId = null;
                _messages = [];
              });
              _addWelcomeMessage();
            },
            tooltip: 'Bắt đầu lại',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Loading indicator
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Error message
          if (_error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.healthDanger.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.healthDanger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.healthDanger, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập triệu chứng...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _handleSendMessage,
                  icon: const Icon(Icons.send),
                  color: AppColors.primary,
                  iconSize: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ConsultMessage message) {
    final isUser = message.isUser;
    final isSuggestion = message.isSuggestion ?? false;
    final isRecommendation = message.isRecommendation ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.primary
                      : isSuggestion
                          ? AppColors.healthWarning.withOpacity(0.1)
                          : isRecommendation
                              ? (message.shouldSeeDoctor ?? false
                                  ? AppColors.healthDanger.withOpacity(0.1)
                                  : AppColors.healthNormal.withOpacity(0.1))
                              : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: isSuggestion || isRecommendation
                    ? Border.all(
                        color: isRecommendation && (message.shouldSeeDoctor ?? false)
                            ? AppColors.healthDanger
                            : AppColors.healthWarning,
                        width: 1,
                      )
                    : null,
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser 
                      ? Colors.white 
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: const Icon(Icons.person, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class ConsultMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool? isSuggestion;
  final bool? isRecommendation;
  final bool? shouldSeeDoctor;

  ConsultMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isSuggestion,
    this.isRecommendation,
    this.shouldSeeDoctor,
  });
}

