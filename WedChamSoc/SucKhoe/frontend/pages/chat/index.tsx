import React, { useState, useEffect } from "react";
import { withAuth } from "@/lib/auth";
import Layout from "@/components/Layout/Layout";
import { PaperAirplaneIcon } from "@heroicons/react/24/outline";
import { chatApi } from "@/lib/api";
import { ChatSession, ChatMessage } from "@/types";
import AIMessage from "@/components/AIMessage";

const ChatPage: React.FC = () => {
  const [message, setMessage] = useState("");
  const [messages, setMessages] = useState<any[]>([]);
  const [currentSession, setCurrentSession] = useState<ChatSession | null>(
    null
  );
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Initialize chat session
  useEffect(() => {
    initializeChat();
  }, []);

  const initializeChat = async () => {
    try {
      setIsLoading(true);
      setError(null);

      // Try to get active session first
      let session = await chatApi.getActiveSession();

      // If no active session, create new one
      if (!session) {
        session = await chatApi.createSession();
      }

      setCurrentSession(session);

      // Load chat history if session has messages
      if (session.messages && session.messages.length > 0) {
        const formattedMessages = session.messages.map((msg) => ({
          id: msg.id,
          type: msg.message_type,
          content: msg.content,
          timestamp: new Date(msg.timestamp),
        }));
        setMessages(formattedMessages);
      } else {
        // Add welcome message
        setMessages([
          {
            id: 0,
            type: "assistant",
            content:
              "Xin chào! Tôi là trợ lý AI sức khỏe. Tôi có thể giúp bạn tư vấn về các vấn đề sức khỏe. Bạn cần hỗ trợ gì hôm nay?",
            timestamp: new Date(),
          },
        ]);
      }
    } catch (err: any) {
      console.error("Error initializing chat:", err);
      setError("Không thể khởi tạo phiên chat. Vui lòng thử lại.");
      // Fallback to offline mode
      setMessages([
        {
          id: 0,
          type: "assistant",
          content:
            "Xin chào! Tôi là trợ lý AI sức khỏe. Hiện tại đang có sự cố kết nối, nhưng tôi vẫn có thể hỗ trợ bạn với các câu trả lời cơ bản.",
          timestamp: new Date(),
        },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSendMessage = async () => {
    if (!message.trim() || isLoading) return;

    const userMessage = {
      id: Date.now(),
      type: "user",
      content: message,
      timestamp: new Date(),
    };

    // Add user message immediately
    setMessages((prev) => [...prev, userMessage]);
    const currentMessage = message;
    setMessage("");
    setIsLoading(true);
    setError(null);

    try {
      if (currentSession) {
        // Send message to API
        const response = await chatApi.sendMessage(
          currentSession.id,
          currentMessage
        );

        // Add AI response
        const aiMessage = {
          id: response.message.id,
          type: response.message.message_type,
          content: response.message.content,
          timestamp: new Date(response.message.timestamp),
        };

        setMessages((prev) => [...prev, aiMessage]);
      } else {
        throw new Error("No active chat session");
      }
    } catch (err: any) {
      console.error("Error sending message:", err);
      setError("Không thể gửi tin nhắn. Vui lòng thử lại.");

      // Add fallback response
      const fallbackResponse = {
        id: Date.now() + 1,
        type: "assistant",
        content:
          "Xin lỗi, tôi đang gặp sự cố kỹ thuật. Vui lòng thử lại sau hoặc liên hệ bác sĩ nếu cần hỗ trợ khẩn cấp.",
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, fallbackResponse]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Layout title="Tư vấn AI">
      <div className="flex flex-col h-screen bg-elderly-bg dark:bg-dark-bg transition-colors">
        <div className="p-6 border-b border-elderly-border dark:border-dark-border">
          <h1 className="text-3xl font-bold text-elderly-text dark:text-dark-text">
            Tư vấn AI sức khỏe
          </h1>
          <p className="text-elderly-text-light dark:text-dark-text-light mt-2">
            Đặt câu hỏi về sức khỏe và nhận tư vấn từ AI
          </p>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {error && (
            <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-4">
              <p className="text-red-800 dark:text-red-300 text-sm">{error}</p>
            </div>
          )}

          {messages.map((msg) => (
            <div
              key={msg.id}
              className={`flex ${
                msg.type === "user" ? "justify-end" : "justify-start"
              }`}
            >
              {msg.type === "user" ? (
                <div className="max-w-xs lg:max-w-md px-4 py-2 rounded-lg bg-primary-600 dark:bg-primary-700 text-white transition-colors">
                  <p>{msg.content}</p>
                  <p className="text-xs mt-1 text-primary-100 dark:text-primary-200">
                    {msg.timestamp.toLocaleTimeString("vi-VN", {
                      hour: "2-digit",
                      minute: "2-digit",
                    })}
                  </p>
                </div>
              ) : (
                <div className="max-w-2xl w-full">
                  <AIMessage content={msg.content} timestamp={msg.timestamp} />
                </div>
              )}
            </div>
          ))}

          {isLoading && (
            <div className="flex justify-start">
              <div className="max-w-xs lg:max-w-md px-4 py-2 rounded-lg bg-gray-100 dark:bg-dark-card-bg text-elderly-text dark:text-dark-text border border-gray-200 dark:border-dark-border">
                <div className="flex items-center space-x-2">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary-600 dark:border-primary-400"></div>
                  <p>Đang suy nghĩ...</p>
                </div>
              </div>
            </div>
          )}
        </div>

        <div className="p-6 border-t border-elderly-border dark:border-dark-border bg-white dark:bg-dark-card-bg transition-colors">
          <div className="flex space-x-4">
            <input
              type="text"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSendMessage()}
              placeholder="Nhập câu hỏi của bạn..."
              className="flex-1 form-input"
            />
            <button
              onClick={handleSendMessage}
              disabled={isLoading || !message.trim()}
              className="btn btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <PaperAirplaneIcon className="h-5 w-5" />
            </button>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default withAuth(ChatPage);
