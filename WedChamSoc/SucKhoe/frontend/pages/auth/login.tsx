import React, { useState, useEffect, useRef } from "react";
import { useAuth } from "@/lib/auth";
import { useRouter } from "next/router";
import Layout from "@/components/Layout/Layout";
import Link from "next/link";
import toast from "react-hot-toast";
import { authApi, email2FaApi } from "@/lib/api";
import {
  UserIcon,
  LockClosedIcon,
  HeartIcon,
  ShieldCheckIcon,
  EyeIcon,
  EyeSlashIcon,
  KeyIcon,
  ArrowLeftIcon,
} from "@heroicons/react/24/outline";

const RESEND_COOLDOWN_SECONDS = 60; 

const LoginPage: React.FC = () => {
  // useAuth now provides login() and completeEmail2FA()
  const { user, isLoading, login, completeEmail2FA } = useAuth();
  const router = useRouter();

  // Basic login states
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // 2FA states
  const [loginStep, setLoginStep] = useState<"password" | "2fa">("password");
  const [twoFactorMethod, setTwoFactorMethod] = useState<"totp" | "email">("totp");
  const [tempToken, setTempToken] = useState("");
  const [twoFactorCode, setTwoFactorCode] = useState("");

  // Resend OTP / cooldown states
  const [resendCooldown, setResendCooldown] = useState<number>(0);
  const cooldownRef = useRef<number | null>(null);

  useEffect(() => {
    if (user) {
      router.push("/");
    }
  }, [user, router]);

  useEffect(() => {
    return () => {
      if (cooldownRef.current) {
        clearInterval(cooldownRef.current);
      }
    };
  }, []);

  const startCooldown = (seconds: number) => {
    if (cooldownRef.current) {
      clearInterval(cooldownRef.current);
    }
    setResendCooldown(seconds);
    cooldownRef.current = window.setInterval(() => {
      setResendCooldown((prev) => {
        if (prev <= 1) {
          if (cooldownRef.current) {
            clearInterval(cooldownRef.current);
            cooldownRef.current = null;
          }
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
  };

  // Step 1: Submit email/password using useAuth.login()
  const handlePasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!email || !password) {
      toast.error("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    setIsSubmitting(true);
    try {
      
      const result = await login(email, password);

      if ((result as any).status === "2fa_required") {
        const r = result as {
          status: "2fa_required";
          temp_token: string;
          method?: "totp" | "email";
        };

        setTempToken(r.temp_token);
        setTwoFactorMethod(r.method || "totp");
        setLoginStep("2fa");

        if (r.method === "email") {
          startCooldown(RESEND_COOLDOWN_SECONDS);
          toast.success("Một mã OTP đã được gửi đến email của bạn");
        } else {
          toast.success("Vui lòng nhập mã từ ứng dụng xác thực");
        }
        return;
      }

      toast.success("Đăng nhập thành công!");
      router.push("/");
    } catch (error: any) {
      console.error("Login error:", error);
      toast.error(error.response?.data?.detail || error.message || "Đăng nhập thất bại");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Resend OTP handler (only for email method)
  const handleResendOtp = async () => {
    if (!email) {
      toast.error("Không có email. Vui lòng quay lại và nhập email.");
      return;
    }
    if (resendCooldown > 0) {
      return;
    }

    setIsSubmitting(true);
    try {
      await email2FaApi.sendOtp(email);
      toast.success("Mã OTP đã được gửi lại. Vui lòng kiểm tra email.");
      startCooldown(RESEND_COOLDOWN_SECONDS);
    } catch (error: any) {
      console.error("Resend OTP error:", error);
      toast.error(error.response?.data?.detail || "Không thể gửi lại mã OTP. Thử lại sau.");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Step 2: Verify 2FA
  const handle2FASubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!twoFactorCode) {
      toast.error("Vui lòng nhập mã xác thực");
      return;
    }

    setIsSubmitting(true);
    try {
      if (twoFactorMethod === "email") {
        await completeEmail2FA(tempToken, email, twoFactorCode);
        toast.success("Đăng nhập thành công!");
        router.push("/");
      } else {
        const data = await authApi.verify2FA(tempToken, twoFactorCode);
        if (typeof window !== "undefined") {
          const token = (data as any).access_token;
          if (token) {
            const Cookies = require("js-cookie");
            Cookies.set("auth_token", token, { expires: 1 });
            window.location.href = "/";
            return;
          }
        }
        toast.success("Đăng nhập thành công!");
        router.push("/");
      }
    } catch (error: any) {
      console.error("2FA error:", error);
      toast.error(error.response?.data?.detail || "Mã xác thực không đúng hoặc đã hết hạn");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleBackToPassword = () => {
    setLoginStep("password");
    setTempToken("");
    setTwoFactorCode("");
    // clear cooldown
    if (cooldownRef.current) {
      clearInterval(cooldownRef.current);
      cooldownRef.current = null;
    }
    setResendCooldown(0);
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

  if (user) return null;

  return (
    <Layout title="Đăng nhập - Hệ thống sức khỏe người cao tuổi" showSidebar={false}>
      <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
        <div className="sm:mx-auto sm:w-full sm:max-w-md">
          <div className="flex justify-center">
            <HeartIcon className="h-12 w-12 text-primary-600" />
          </div>
          <h2 className="mt-6 text-center text-3xl font-bold text-elderly-text">
            Đăng nhập vào tài khoản
          </h2>
          <p className="mt-2 text-center text-elderly-text-light">
            Chăm sóc sức khỏe thông minh cho người cao tuổi
          </p>
        </div>

        <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
          <div className="bg-white py-8 px-4 shadow-soft sm:rounded-lg sm:px-10">
            {/* Login Step */}
            {loginStep === "password" ? (
              <form onSubmit={handlePasswordSubmit} className="space-y-4">
                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-elderly-text mb-2">
                    Email
                  </label>
                  <input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="form-input w-full"
                    placeholder="Nhập địa chỉ email"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="password" className="block text-sm font-medium text-elderly-text mb-2">
                    Mật khẩu
                  </label>
                  <div className="relative">
                    <input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="form-input w-full pr-12"
                      placeholder="Nhập mật khẩu"
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

                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full flex justify-center items-center py-4 px-4 border border-transparent rounded-lg shadow-sm text-lg font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isSubmitting ? (
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2" />
                  ) : (
                    <LockClosedIcon className="h-5 w-5 mr-2" />
                  )}
                  {isSubmitting ? "Đang đăng nhập..." : "Đăng nhập"}
                </button>

                <div className="text-center">
                  <span className="text-elderly-text-light">Chưa có tài khoản? </span>
                  <Link href="/auth/register" className="font-medium text-primary-600 hover:text-primary-500">
                    Đăng ký ngay
                  </Link>
                </div>
              </form>
            ) : (
              <form onSubmit={handle2FASubmit} className="space-y-4">
                <div className="text-center mb-6">
                  <div className="flex justify-center mb-4">
                    <KeyIcon className="h-12 w-12 text-primary-600" />
                  </div>
                  <h3 className="text-lg font-medium text-elderly-text">
                    {twoFactorMethod === "email" ? "Xác thực qua Email" : "Xác thực 2 bước"}
                  </h3>
                  <p className="text-elderly-text-light mt-2">
                    {twoFactorMethod === "email"
                      ? "Nhập mã OTP được gửi đến email của bạn"
                      : "Vui lòng nhập mã 6 số từ ứng dụng xác thực"}
                  </p>
                </div>

                <div>
                  <label htmlFor="twoFactorCode" className="block text-sm font-medium text-elderly-text mb-2">
                    Mã xác thực
                  </label>
                  <input
                    id="twoFactorCode"
                    type="text"
                    value={twoFactorCode}
                    onChange={(e) => setTwoFactorCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
                    className="form-input w-full text-center text-2xl tracking-widest"
                    placeholder="000000"
                    maxLength={6}
                    required
                  />
                </div>

                {/* Resend button (only visible for email method) */}
                {twoFactorMethod === "email" && (
                  <div className="flex items-center justify-between mt-2">
                    <div className="text-sm text-elderly-text-light">
                      {resendCooldown > 0 ? (
                        <>Bạn có thể gửi lại trong <strong>{resendCooldown}s</strong></>
                      ) : (
                        <>Bạn có thể gửi lại mã nếu không nhận được</>
                      )}
                    </div>
                    <button
                      type="button"
                      onClick={handleResendOtp}
                      disabled={resendCooldown > 0 || isSubmitting}
                      className={`text-sm font-medium ${
                        resendCooldown > 0 || isSubmitting ? "text-gray-400" : "text-primary-600 hover:text-primary-500"
                      }`}
                    >
                      {resendCooldown > 0 ? `Gửi lại (${resendCooldown}s)` : "Gửi lại mã"}
                    </button>
                  </div>
                )}

                <div className="space-y-3 mt-4">
                  <button
                    type="submit"
                    disabled={isSubmitting || twoFactorCode.length !== 6}
                    className="w-full flex justify-center items-center py-4 px-4 border border-transparent rounded-lg shadow-sm text-lg font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isSubmitting ? (
                      <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2" />
                    ) : (
                      <KeyIcon className="h-5 w-5 mr-2" />
                    )}
                    {isSubmitting ? "Đang xác thực..." : "Xác thực"}
                  </button>

                  <button
                    type="button"
                    onClick={handleBackToPassword}
                    className="w-full flex justify-center items-center py-3 px-4 border border-gray-300 rounded-lg shadow-sm text-lg font-medium text-elderly-text bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors"
                  >
                    <ArrowLeftIcon className="h-5 w-5 mr-2" />
                    Quay lại đăng nhập
                  </button>
                </div>
              </form>
            )}

            {/* Security Notice */}
            <div className="mt-8 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex">
                <ShieldCheckIcon className="h-5 w-5 text-blue-600 mt-0.5 mr-3 flex-shrink-0" />
                <div>
                  <h4 className="text-sm font-medium text-blue-800">Đăng nhập an toàn</h4>
                  <p className="text-sm text-blue-700 mt-1">
                    Chúng tôi sử dụng công nghệ bảo mật tiên tiến để bảo vệ
                    thông tin của bạn. Không bao giờ chia sẻ mật khẩu với người
                    khác.
                  </p>
                </div>
              </div>
            </div>

            {/* Help */}
            <div className="mt-6 text-center">
              <p className="text-sm text-elderly-text-light">
                Cần hỗ trợ?{" "}
                <Link
                  href="/help"
                  className="font-medium text-primary-600 hover:text-primary-500"
                >
                  Liên hệ với chúng tôi
                </Link>
              </p>
            </div>
          </div>
        </div>

        {/* Additional Info */}
        <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
          <div className="bg-white rounded-lg shadow-soft p-6">
            <h3 className="text-lg font-medium text-elderly-text mb-4 text-center">
              Dành cho người cao tuổi
            </h3>
            <div className="grid grid-cols-1 gap-4 text-center">
              <div>
                <div className="text-2xl font-bold text-primary-600">
                  Font chữ lớn
                </div>
                <div className="text-elderly-text-light">Dễ đọc, dễ nhìn</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-primary-600">
                  Đơn giản
                </div>
                <div className="text-elderly-text-light">
                  Giao diện thân thiện
                </div>
              </div>
              <div>
                <div className="text-2xl font-bold text-primary-600">24/7</div>
                <div className="text-elderly-text-light">Hỗ trợ mọi lúc</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default LoginPage;
