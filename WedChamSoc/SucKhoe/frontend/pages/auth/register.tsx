import React, { useState } from "react";
import { useAuth } from "@/lib/auth";
import { useRouter } from "next/router";
import { useEffect } from "react";
import Layout from "@/components/Layout/Layout";
import Link from "next/link";
import toast from "react-hot-toast";
import {
  UserPlusIcon,
  HeartIcon,
  ShieldCheckIcon,
  CheckCircleIcon,
  EyeIcon,
  EyeSlashIcon,
  ClockIcon,
} from "@heroicons/react/24/outline";
import { authApi } from "@/lib/api";

const RegisterPage: React.FC = () => {
  const { user, isLoading, register } = useAuth();
  const router = useRouter();
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    confirmPassword: "",
    full_name: "",
    phone: "",
  });
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (user) {
      router.push("/");
    }
  }, [user, router]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.email || !formData.password || !formData.full_name) {
      toast.error("Vui lòng nhập đầy đủ thông tin bắt buộc");
      return;
    }

    if (formData.password !== formData.confirmPassword) {
      toast.error("Mật khẩu xác nhận không khớp");
      return;
    }

    if (formData.password.length < 6) {
      toast.error("Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }

    setIsSubmitting(true);
    try {
      const data = {
        email: formData.email,
        password: formData.password,
        full_name: formData.full_name,
        phone: formData.phone,
      };
      await authApi.register(data);
      toast.success("Đăng ký thành công!");
      router.push("/auth/login");
    } catch (error: any) {
      toast.error(error.response?.data?.detail || error.message || "Đăng ký thất bại");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return (
      <Layout showSidebar={false}>
        <div className="flex items-center justify-center min-h-screen">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
        </div>
      </Layout>
    );
  }

  if (user) {
    return null; // Will redirect
  }

  return (
    <Layout
      title="Đăng ký - Hệ thống sức khỏe người cao tuổi"
      showSidebar={false}
    >
      <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
        <div className="sm:mx-auto sm:w-full sm:max-w-md">
          <div className="flex justify-center">
            <HeartIcon className="h-12 w-12 text-primary-600" />
          </div>
          <h2 className="mt-6 text-center text-3xl font-bold text-elderly-text">
            Tạo tài khoản mới
          </h2>
          <p className="mt-2 text-center text-elderly-text-light">
            Bắt đầu hành trình chăm sóc sức khỏe của bạn
          </p>
        </div>

        <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
          <div className="bg-white py-8 px-4 shadow-soft sm:rounded-lg sm:px-10">
            {/* Benefits */}
            <div className="mb-8">
              <h3 className="text-lg font-medium text-elderly-text mb-4">
                Lợi ích khi đăng ký:
              </h3>
              <div className="space-y-3">
                <div className="flex items-start">
                  <CheckCircleIcon className="h-5 w-5 text-green-600 mt-0.5 mr-3 flex-shrink-0" />
                  <span className="text-elderly-text-light">
                    Theo dõi sức khỏe cá nhân hóa
                  </span>
                </div>
                <div className="flex items-start">
                  <CheckCircleIcon className="h-5 w-5 text-green-600 mt-0.5 mr-3 flex-shrink-0" />
                  <span className="text-elderly-text-light">
                    Nhắc nhở uống thuốc thông minh
                  </span>
                </div>
                <div className="flex items-start">
                  <CheckCircleIcon className="h-5 w-5 text-green-600 mt-0.5 mr-3 flex-shrink-0" />
                  <span className="text-elderly-text-light">
                    Tư vấn AI 24/7 miễn phí
                  </span>
                </div>
                <div className="flex items-start">
                  <CheckCircleIcon className="h-5 w-5 text-green-600 mt-0.5 mr-3 flex-shrink-0" />
                  <span className="text-elderly-text-light">
                    Báo cáo sức khỏe chi tiết
                  </span>
                </div>
              </div>
            </div>

            {/* Register Form */}
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label
                  htmlFor="full_name"
                  className="block text-sm font-medium text-elderly-text mb-2"
                >
                  Họ và tên <span className="text-red-500">*</span>
                </label>
                <input
                  id="full_name"
                  name="full_name"
                  type="text"
                  value={formData.full_name}
                  onChange={handleInputChange}
                  className="form-input w-full"
                  placeholder="Nhập họ và tên đầy đủ"
                  required
                />
              </div>

              <div>
                <label
                  htmlFor="email"
                  className="block text-sm font-medium text-elderly-text mb-2"
                >
                  Email <span className="text-red-500">*</span>
                </label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  className="form-input w-full"
                  placeholder="Nhập địa chỉ email"
                  required
                />
              </div>

              <div>
                <label
                  htmlFor="phone"
                  className="block text-sm font-medium text-elderly-text mb-2"
                >
                  Số điện thoại
                </label>
                <input
                  id="phone"
                  name="phone"
                  type="tel"
                  value={formData.phone}
                  onChange={handleInputChange}
                  className="form-input w-full"
                  placeholder="Nhập số điện thoại (tùy chọn)"
                />
              </div>

              <div>
                <label
                  htmlFor="password"
                  className="block text-sm font-medium text-elderly-text mb-2"
                >
                  Mật khẩu <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <input
                    id="password"
                    name="password"
                    type={showPassword ? "text" : "password"}
                    value={formData.password}
                    onChange={handleInputChange}
                    className="form-input w-full pr-12"
                    placeholder="Nhập mật khẩu (ít nhất 6 ký tự)"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute inset-y-0 right-0 pr-3 flex items-center"
                  >
                    {showPassword ? (
                      <EyeSlashIcon className="h-5 w-5 text-elderly-text-light" />
                    ) : (
                      <EyeIcon className="h-5 w-5 text-elderly-text-light" />
                    )}
                  </button>
                </div>
              </div>

              <div>
                <label
                  htmlFor="confirmPassword"
                  className="block text-sm font-medium text-elderly-text mb-2"
                >
                  Xác nhận mật khẩu <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <input
                    id="confirmPassword"
                    name="confirmPassword"
                    type={showConfirmPassword ? "text" : "password"}
                    value={formData.confirmPassword}
                    onChange={handleInputChange}
                    className="form-input w-full pr-12"
                    placeholder="Nhập lại mật khẩu"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute inset-y-0 right-0 pr-3 flex items-center"
                  >
                    {showConfirmPassword ? (
                      <EyeSlashIcon className="h-5 w-5 text-elderly-text-light" />
                    ) : (
                      <EyeIcon className="h-5 w-5 text-elderly-text-light" />
                    )}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full flex justify-center items-center py-4 px-4 border border-transparent rounded-lg shadow-sm text-lg font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSubmitting ? (
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2" />
                ) : (
                  <UserPlusIcon className="h-5 w-5 mr-2" />
                )}
                {isSubmitting ? "Đang đăng ký..." : "Đăng ký miễn phí"}
              </button>

              <div className="text-center">
                <span className="text-elderly-text-light">
                  Đã có tài khoản?{" "}
                </span>
                <Link
                  href="/auth/login"
                  className="font-medium text-primary-600 hover:text-primary-500"
                >
                  Đăng nhập ngay
                </Link>
              </div>
            </form>

            {/* Registration Steps */}
            <div className="mt-8 p-4 bg-green-50 border border-green-200 rounded-lg">
              <h4 className="text-sm font-medium text-green-800 mb-3">
                Quy trình đăng ký đơn giản:
              </h4>
              <div className="space-y-2">
                <div className="flex items-center text-sm text-green-700">
                  <span className="w-6 h-6 bg-green-600 text-white rounded-full flex items-center justify-center text-xs mr-3">
                    1
                  </span>
                  Nhập email và tạo mật khẩu
                </div>
                <div className="flex items-center text-sm text-green-700">
                  <span className="w-6 h-6 bg-green-600 text-white rounded-full flex items-center justify-center text-xs mr-3">
                    2
                  </span>
                  Xác thực email
                </div>
                <div className="flex items-center text-sm text-green-700">
                  <span className="w-6 h-6 bg-green-600 text-white rounded-full flex items-center justify-center text-xs mr-3">
                    3
                  </span>
                  Hoàn thành hồ sơ sức khỏe
                </div>
                <div className="flex items-center text-sm text-green-700">
                  <span className="w-6 h-6 bg-green-600 text-white rounded-full flex items-center justify-center text-xs mr-3">
                    4
                  </span>
                  Bắt đầu sử dụng
                </div>
              </div>
            </div>

            {/* Security & Privacy */}
            <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex">
                <ShieldCheckIcon className="h-5 w-5 text-blue-600 mt-0.5 mr-3 flex-shrink-0" />
                <div>
                  <h4 className="text-sm font-medium text-blue-800">
                    Bảo mật & Quyền riêng tư
                  </h4>
                  <p className="text-sm text-blue-700 mt-1">
                    Thông tin của bạn được mã hóa và bảo vệ theo tiêu chuẩn quốc
                    tế. Chúng tôi không bao giờ chia sẻ dữ liệu cá nhân với bên
                    thứ ba.
                  </p>
                </div>
              </div>
            </div>

            {/* Terms */}
            <div className="mt-6 text-center text-sm text-elderly-text-light">
              Bằng việc đăng ký, bạn đồng ý với{" "}
              <Link
                href="/terms"
                className="text-primary-600 hover:text-primary-500"
              >
                Điều khoản sử dụng
              </Link>{" "}
              và{" "}
              <Link
                href="/privacy"
                className="text-primary-600 hover:text-primary-500"
              >
                Chính sách bảo mật
              </Link>{" "}
              của chúng tôi.
            </div>
          </div>
        </div>

        {/* Why Choose Us */}
        <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
          <div className="bg-white rounded-lg shadow-soft p-6">
            <h3 className="text-lg font-medium text-elderly-text mb-4 text-center">
              Tại sao chọn chúng tôi?
            </h3>
            <div className="grid grid-cols-1 gap-4">
              <div className="text-center">
                <ClockIcon className="h-8 w-8 text-primary-600 mx-auto mb-2" />
                <div className="font-medium text-elderly-text">
                  Tiết kiệm thời gian
                </div>
                <div className="text-sm text-elderly-text-light">
                  Quản lý sức khỏe tự động
                </div>
              </div>
              <div className="text-center">
                <HeartIcon className="h-8 w-8 text-primary-600 mx-auto mb-2" />
                <div className="font-medium text-elderly-text">
                  Chăm sóc tốt hơn
                </div>
                <div className="text-sm text-elderly-text-light">
                  Theo dõi chính xác, tư vấn kịp thời
                </div>
              </div>
              <div className="text-center">
                <ShieldCheckIcon className="h-8 w-8 text-primary-600 mx-auto mb-2" />
                <div className="font-medium text-elderly-text">
                  An toàn tuyệt đối
                </div>
                <div className="text-sm text-elderly-text-light">
                  Bảo mật thông tin cao cấp
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default RegisterPage;
