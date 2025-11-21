import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/chat_service.dart';
import '../../models/chat.dart';
import '../../widgets/ai_message.dart';
import '../../widgets/chat/user_message_widget.dart';
import '../../widgets/chat/loading_message_widget.dart';
import '../auth/login_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService(ApiClient());
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  ChatSessionModel? _currentSession;
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to get active session first
      var session = await _chatService.getActiveSession();

      // If no active session, create new one
      session ??= await _chatService.createSession();

      setState(() {
        _currentSession = session;
      });

      // Load chat history if session has messages
      if (session != null && session.messages != null && session.messages!.isNotEmpty) {
        setState(() {
          _messages = session!.messages!;
        });
        _scrollToBottom();
      } else if (session != null) {
        // Add welcome message
        setState(() {
          _messages = [
            ChatMessageModel(
              id: 0,
              sessionId: session!.id,
              messageType: MessageType.assistant,
              content:
                  'Xin chào! Tôi là trợ lý AI sức khỏe. Tôi có thể giúp bạn tư vấn về các vấn đề sức khỏe. Bạn cần hỗ trợ gì hôm nay?',
              timestamp: DateTime.now().toIso8601String(),
            ),
          ];
        });
      }
    } on TokenExpiredException {
      _navigateToLogin();
    } catch (e) {
      setState(() {
        _error = 'Không thể khởi tạo phiên chat. Vui lòng thử lại.';
        // Fallback to offline mode
        _messages = [
          ChatMessageModel(
            id: 0,
            sessionId: 0,
            messageType: MessageType.assistant,
            content:
                'Xin chào! Tôi là trợ lý AI sức khỏe. Hiện tại đang có sự cố kết nối, nhưng tôi vẫn có thể hỗ trợ bạn với các câu trả lời cơ bản.',
            timestamp: DateTime.now().toIso8601String(),
          ),
        ];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending || _currentSession == null) return;

    // Add user message immediately
    final userMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      sessionId: _currentSession!.id,
      messageType: MessageType.user,
      content: message,
      timestamp: DateTime.now().toIso8601String(),
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
      final response = await _chatService.sendMessage(
        _currentSession!.id,
        message,
      );

      // Add AI response
      setState(() {
        _messages = [..._messages, response.message];
        _currentSession = response.session;
      });

      _scrollToBottom();
    } on TokenExpiredException {
      _navigateToLogin();
    } catch (e) {
      setState(() {
        _error = 'Không thể gửi tin nhắn. Vui lòng thử lại.';
        // Add fallback response
        if (_currentSession != null) {
          _messages = [
            ..._messages,
            ChatMessageModel(
              id: DateTime.now().millisecondsSinceEpoch + 1,
              sessionId: _currentSession!.id,
              messageType: MessageType.assistant,
              content:
                  'Xin lỗi, tôi đang gặp sự cố kỹ thuật. Vui lòng thử lại sau hoặc liên hệ bác sĩ nếu cần hỗ trợ khẩn cấp.',
              timestamp: DateTime.now().toIso8601String(),
            ),
          ];
        }
      });
      _scrollToBottom();
    } finally {
      setState(() {
        _isSending = false;
      });
    }
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

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tư vấn AI sức khỏe'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Error message
          if (_error != null)
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                    border: Border.all(
                      color: isDark ? Colors.red.shade800 : Colors.red.shade200,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: isDark ? Colors.red.shade300 : Colors.red.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: isDark ? Colors.red.shade300 : Colors.red.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _initializeChat,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _messages.length + (_isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isSending) {
                          // Loading indicator
                          return const LoadingMessageWidget();
                        }

                        final message = _messages[index];
                        return _buildMessage(message);
                      },
                    ),
                  ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi của bạn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _isSending || _messageController.text.trim().isEmpty
                          ? null
                          : _handleSendMessage,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessageModel message) {
    final isUser = message.messageType == MessageType.user;
    final timestamp = DateTime.parse(message.timestamp);

    if (isUser) {
      return UserMessageWidget(
        content: message.content,
        timestamp: message.timestamp,
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AIMessage(
          content: message.content,
          timestamp: timestamp,
        ),
      );
    }
  }
}

