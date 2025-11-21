import React from 'react';

interface AIMessageProps {
  content: string;
  timestamp: Date;
}

const AIMessage: React.FC<AIMessageProps> = ({ content, timestamp }) => {
  // Format AI response with proper line breaks and structure
  const formatContent = (text: string) => {
    // Split by common patterns and format
    const formatted = text
      // Replace ** with bold formatting
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      // Replace * at start of line with bullet points
      .replace(/^\* /gm, '• ')
      // Add line breaks for better readability
      .replace(/\. \*/g, '.\n\n•')
      // Format medical advice sections
      .replace(/Chào bác\/cô!/g, '<strong>Chào bác/cô!</strong>')
      .replace(/Nên tránh:/g, '\n<strong>🚫 Nên tránh:</strong>')
      .replace(/Để giảm/g, '\n<strong>💡 Để giảm')
      .replace(/Uống nhiều/g, '\n<strong>💧 Uống nhiều')
      .replace(/Sức khỏe/g, '\n<strong>🏥 Sức khỏe')
      .replace(/Ngâm keo/g, '\n<strong>🌿 Ngâm keo')
      .replace(/Thức ăn/g, '\n<strong>🍎 Thức ăn')
      .replace(/Khói thuốc/g, '\n<strong>🚭 Khói thuốc')
      .replace(/Trong trường hợp/g, '\n<strong>⚠️ Trong trường hợp')
      .replace(/Chúc bác\/cô/g, '\n<strong>🌟 Chúc bác/cô');

    return formatted;
  };

  return (
    <div className="bg-gradient-to-r from-blue-50 to-green-50 dark:from-blue-900/20 dark:to-green-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 shadow-sm transition-colors">
      <div className="flex items-start space-x-3">
        <div className="flex-shrink-0">
          <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-green-500 rounded-full flex items-center justify-center">
            <span className="text-white text-sm font-bold">AI</span>
          </div>
        </div>
        <div className="flex-1 min-w-0">
          <div 
            className="text-gray-800 dark:text-gray-200 leading-relaxed whitespace-pre-line"
            dangerouslySetInnerHTML={{ __html: formatContent(content) }}
          />
          <div className="mt-3 pt-2 border-t border-blue-100 dark:border-blue-800">
            <p className="text-xs text-blue-600 dark:text-blue-400 flex items-center">
              <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clipRule="evenodd" />
              </svg>
              {timestamp.toLocaleTimeString("vi-VN", {
                hour: "2-digit",
                minute: "2-digit",
              })}
            </p>
          </div>
          <div className="mt-2 text-xs text-gray-500 dark:text-yellow-300 bg-yellow-50 dark:bg-yellow-900/30 border border-yellow-200 dark:border-yellow-800 rounded p-2">
            <strong>⚠️ Lưu ý:</strong> Đây chỉ là tư vấn sơ bộ. Vui lòng tham khảo ý kiến bác sĩ chuyên khoa để được chẩn đoán và điều trị chính xác.
          </div>
        </div>
      </div>
    </div>
  );
};

export default AIMessage;
