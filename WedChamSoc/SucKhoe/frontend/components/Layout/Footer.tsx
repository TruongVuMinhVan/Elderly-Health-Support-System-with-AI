import React from 'react';
import Link from 'next/link';

const Footer: React.FC = () => {
  return (
    <footer className="bg-white border-t border-elderly-border mt-auto">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="py-8">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div>
              <h3 className="text-lg font-semibold text-elderly-text mb-4">
                Hệ thống SứcKhỏe
              </h3>
              <p className="text-elderly-text-light">
                Chăm sóc sức khỏe người cao tuổi với công nghệ hiện đại và tình yêu thương.
              </p>
            </div>
            
            <div>
              <h3 className="text-lg font-semibold text-elderly-text mb-4">
                Liên kết hữu ích
              </h3>
              <ul className="space-y-2">
                <li>
                  <Link href="/about" className="text-elderly-text-light hover:text-primary-600">
                    Về chúng tôi
                  </Link>
                </li>
                <li>
                  <Link href="/privacy" className="text-elderly-text-light hover:text-primary-600">
                    Chính sách bảo mật
                  </Link>
                </li>
                <li>
                  <Link href="/terms" className="text-elderly-text-light hover:text-primary-600">
                    Điều khoản sử dụng
                  </Link>
                </li>
              </ul>
            </div>
            
            <div>
              <h3 className="text-lg font-semibold text-elderly-text mb-4">
                Hỗ trợ
              </h3>
              <ul className="space-y-2">
                <li>
                  <span className="text-elderly-text-light">
                    Hotline: 1900-1234
                  </span>
                </li>
                <li>
                  <span className="text-elderly-text-light">
                    Email: support@suckhoe.vn
                  </span>
                </li>
              </ul>
            </div>
          </div>
          
          <div className="mt-8 pt-8 border-t border-elderly-border">
            <p className="text-center text-elderly-text-light">
              © 2024 Hệ thống hỗ trợ sức khỏe người cao tuổi. Tất cả quyền được bảo lưu.
            </p>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
