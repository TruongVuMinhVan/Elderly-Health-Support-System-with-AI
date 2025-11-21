import React from 'react';
import Layout from '@/components/Layout/Layout';
import Link from 'next/link';
import {
  PhoneIcon,
  EnvelopeIcon,
  QuestionMarkCircleIcon,
  BookOpenIcon,
  ChatBubbleLeftRightIcon,
} from '@heroicons/react/24/outline';

const HelpPage: React.FC = () => {
  const faqs = [
    {
      question: 'Làm thế nào để đăng ký tài khoản?',
      answer: 'Bạn có thể đăng ký bằng cách click vào nút "Đăng ký" ở góc trên bên phải, sau đó làm theo hướng dẫn để tạo tài khoản mới.',
    },
    {
      question: 'Tôi quên mật khẩu, phải làm sao?',
      answer: 'Tại trang đăng nhập, click vào "Quên mật khẩu?" và nhập email của bạn. Chúng tôi sẽ gửi link đặt lại mật khẩu.',
    },
    {
      question: 'Làm thế nào để ghi nhận chỉ số sức khỏe?',
      answer: 'Sau khi đăng nhập, vào mục "Sức khỏe" và chọn loại chỉ số bạn muốn ghi nhận (huyết áp, đường huyết, v.v.), sau đó nhập số liệu.',
    },
    {
      question: 'Tôi có thể đặt nhắc nhở uống thuốc không?',
      answer: 'Có, vào mục "Thuốc" để thêm thông tin thuốc, sau đó vào "Lịch hẹn" để đặt nhắc nhở uống thuốc theo giờ.',
    },
    {
      question: 'Thông tin của tôi có được bảo mật không?',
      answer: 'Tuyệt đối! Chúng tôi sử dụng công nghệ mã hóa tiên tiến và tuân thủ các tiêu chuẩn bảo mật quốc tế để bảo vệ thông tin của bạn.',
    },
  ];

  return (
    <Layout 
      title="Trợ giúp - Hệ thống sức khỏe người cao tuổi"
      showSidebar={false}
    >
      <div className="bg-white">
        {/* Header */}
        <div className="bg-primary-50 py-16">
          <div className="mx-auto max-w-7xl px-6 lg:px-8">
            <div className="text-center">
              <h1 className="text-4xl font-bold text-elderly-text">
                Trung tâm trợ giúp
              </h1>
              <p className="mt-4 text-lg text-elderly-text-light">
                Chúng tôi luôn sẵn sàng hỗ trợ bạn
              </p>
            </div>
          </div>
        </div>

        {/* Contact Options */}
        <div className="py-16">
          <div className="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 className="text-2xl font-bold text-elderly-text text-center mb-12">
              Liên hệ với chúng tôi
            </h2>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div className="card text-center">
                <PhoneIcon className="h-12 w-12 text-primary-600 mx-auto mb-4" />
                <h3 className="text-lg font-semibold text-elderly-text mb-2">
                  Hotline 24/7
                </h3>
                <p className="text-elderly-text-light mb-4">
                  Gọi ngay để được hỗ trợ trực tiếp
                </p>
                <a
                  href="tel:19001234"
                  className="text-primary-600 font-semibold text-xl"
                >
                  1900-1234
                </a>
              </div>

              <div className="card text-center">
                <EnvelopeIcon className="h-12 w-12 text-primary-600 mx-auto mb-4" />
                <h3 className="text-lg font-semibold text-elderly-text mb-2">
                  Email hỗ trợ
                </h3>
                <p className="text-elderly-text-light mb-4">
                  Gửi email, chúng tôi sẽ phản hồi trong 24h
                </p>
                <a
                  href="mailto:support@suckhoe.vn"
                  className="text-primary-600 font-semibold"
                >
                  support@suckhoe.vn
                </a>
              </div>

              <div className="card text-center">
                <ChatBubbleLeftRightIcon className="h-12 w-12 text-primary-600 mx-auto mb-4" />
                <h3 className="text-lg font-semibold text-elderly-text mb-2">
                  Chat trực tuyến
                </h3>
                <p className="text-elderly-text-light mb-4">
                  Chat với nhân viên hỗ trợ
                </p>
                <button className="btn btn-primary">
                  Bắt đầu chat
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* FAQ Section */}
        <div className="bg-gray-50 py-16">
          <div className="mx-auto max-w-4xl px-6 lg:px-8">
            <div className="text-center mb-12">
              <QuestionMarkCircleIcon className="h-12 w-12 text-primary-600 mx-auto mb-4" />
              <h2 className="text-2xl font-bold text-elderly-text">
                Câu hỏi thường gặp
              </h2>
              <p className="mt-4 text-elderly-text-light">
                Tìm câu trả lời cho những thắc mắc phổ biến
              </p>
            </div>

            <div className="space-y-6">
              {faqs.map((faq, index) => (
                <div key={index} className="card">
                  <h3 className="text-lg font-semibold text-elderly-text mb-3">
                    {faq.question}
                  </h3>
                  <p className="text-elderly-text-light leading-relaxed">
                    {faq.answer}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Quick Links */}
        <div className="py-16">
          <div className="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 className="text-2xl font-bold text-elderly-text text-center mb-12">
              Liên kết hữu ích
            </h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <Link href="/auth/register" className="card hover:shadow-card-hover transition-shadow">
                <BookOpenIcon className="h-8 w-8 text-primary-600 mb-3" />
                <h3 className="font-semibold text-elderly-text mb-2">
                  Hướng dẫn đăng ký
                </h3>
                <p className="text-elderly-text-light text-sm">
                  Cách tạo tài khoản mới
                </p>
              </Link>

              <Link href="/auth/login" className="card hover:shadow-card-hover transition-shadow">
                <BookOpenIcon className="h-8 w-8 text-primary-600 mb-3" />
                <h3 className="font-semibold text-elderly-text mb-2">
                  Hướng dẫn đăng nhập
                </h3>
                <p className="text-elderly-text-light text-sm">
                  Cách truy cập tài khoản
                </p>
              </Link>

              <div className="card">
                <BookOpenIcon className="h-8 w-8 text-primary-600 mb-3" />
                <h3 className="font-semibold text-elderly-text mb-2">
                  Video hướng dẫn
                </h3>
                <p className="text-elderly-text-light text-sm">
                  Xem video hướng dẫn chi tiết
                </p>
              </div>

              <div className="card">
                <BookOpenIcon className="h-8 w-8 text-primary-600 mb-3" />
                <h3 className="font-semibold text-elderly-text mb-2">
                  Tài liệu hướng dẫn
                </h3>
                <p className="text-elderly-text-light text-sm">
                  Tải về tài liệu PDF
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Emergency Contact */}
        <div className="bg-red-50 border-t-4 border-red-400 py-8">
          <div className="mx-auto max-w-4xl px-6 lg:px-8">
            <div className="text-center">
              <h3 className="text-lg font-semibold text-red-800 mb-2">
                Trường hợp khẩn cấp
              </h3>
              <p className="text-red-700 mb-4">
                Nếu bạn gặp tình huống khẩn cấp về sức khỏe, hãy gọi ngay:
              </p>
              <div className="flex justify-center space-x-8">
                <div>
                  <div className="text-2xl font-bold text-red-800">115</div>
                  <div className="text-red-600">Cấp cứu</div>
                </div>
                <div>
                  <div className="text-2xl font-bold text-red-800">113</div>
                  <div className="text-red-600">Công an</div>
                </div>
                <div>
                  <div className="text-2xl font-bold text-red-800">114</div>
                  <div className="text-red-600">Cứu hỏa</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default HelpPage;
