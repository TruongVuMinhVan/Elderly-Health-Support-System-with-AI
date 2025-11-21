/**
 * Landing page component for non-authenticated users
 */

import React from "react";
import Link from "next/link";
import {
  HeartIcon,
  ChartBarIcon,
  ClockIcon,
  ChatBubbleLeftRightIcon,
  ShieldCheckIcon,
  UserGroupIcon,
} from "@heroicons/react/24/outline";

const features = [
  {
    name: "Theo dõi sức khỏe",
    description:
      "Ghi nhận và theo dõi các chỉ số sức khỏe quan trọng như huyết áp, đường huyết, nhịp tim.",
    icon: HeartIcon,
  },
  {
    name: "Biểu đồ trực quan",
    description:
      "Xem biểu đồ thay đổi sức khỏe theo thời gian để hiểu rõ tình trạng của bạn.",
    icon: ChartBarIcon,
  },
  {
    name: "Nhắc nhở thông minh",
    description:
      "Nhận nhắc nhở uống thuốc và lịch khám bệnh đúng giờ, không bao giờ quên.",
    icon: ClockIcon,
  },
  {
    name: "Tư vấn AI",
    description:
      "Chatbot AI thông minh tư vấn sức khỏe 24/7, luôn sẵn sàng hỗ trợ bạn.",
    icon: ChatBubbleLeftRightIcon,
  },
  {
    name: "Bảo mật cao",
    description:
      "Thông tin sức khỏe được bảo vệ an toàn với công nghệ mã hóa tiên tiến.",
    icon: ShieldCheckIcon,
  },
  {
    name: "Dễ sử dụng",
    description:
      "Giao diện thân thiện, phù hợp với người cao tuổi, dễ dàng sử dụng.",
    icon: UserGroupIcon,
  },
];

const stats = [
  { name: "Người dùng tin tưởng", value: "1,000+" },
  { name: "Chỉ số sức khỏe được theo dõi", value: "50,000+" },
  { name: "Lời nhắc đã gửi", value: "100,000+" },
  { name: "Tư vấn AI", value: "24/7" },
];

const LandingPage: React.FC = () => {
  return (
    <div className="bg-white">
      {/* Hero section */}
      <div className="relative isolate px-6 pt-14 lg:px-8">
        <div className="absolute inset-x-0 -top-40 -z-10 transform-gpu overflow-hidden blur-3xl sm:-top-80">
          <div className="relative left-[calc(50%-11rem)] aspect-[1155/678] w-[36.125rem] -translate-x-1/2 rotate-[30deg] bg-gradient-to-tr from-primary-400 to-primary-600 opacity-30 sm:left-[calc(50%-30rem)] sm:w-[72.1875rem]" />
        </div>

        <div className="mx-auto max-w-4xl py-32 sm:py-48 lg:py-56">
          <div className="text-center">
            <h1 className="text-4xl font-bold tracking-tight text-elderly-text sm:text-6xl">
              Hệ thống chăm sóc sức khỏe{" "}
              <span className="text-primary-600">người cao tuổi</span>
            </h1>
            <p className="mt-6 text-lg leading-8 text-elderly-text-light max-w-2xl mx-auto">
              Hệ thống hỗ trợ theo dõi và chăm sóc sức khỏe toàn diện, giúp
              người cao tuổi và gia đình quản lý sức khỏe một cách dễ dàng và
              hiệu quả.
            </p>
            <div className="mt-10 flex items-center justify-center gap-x-6">
              <Link href="/auth/register" className="btn btn-primary btn-lg">
                Đăng ký miễn phí
              </Link>
              <Link href="/auth/login" className="btn btn-outline btn-lg">
                Đăng nhập
              </Link>
            </div>
          </div>
        </div>

        <div className="absolute inset-x-0 top-[calc(100%-13rem)] -z-10 transform-gpu overflow-hidden blur-3xl sm:top-[calc(100%-30rem)]">
          <div className="relative left-[calc(50%+3rem)] aspect-[1155/678] w-[36.125rem] -translate-x-1/2 bg-gradient-to-tr from-primary-400 to-primary-600 opacity-30 sm:left-[calc(50%+36rem)] sm:w-[72.1875rem]" />
        </div>
      </div>

      {/* Features section */}
      <div id="features" className="py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:text-center">
            <h2 className="text-base font-semibold leading-7 text-primary-600">
              Tính năng nổi bật
            </h2>
            <p className="mt-2 text-3xl font-bold tracking-tight text-elderly-text sm:text-4xl">
              Mọi thứ bạn cần để chăm sóc sức khỏe
            </p>
            <p className="mt-6 text-lg leading-8 text-elderly-text-light">
              Hệ thống được thiết kế đặc biệt cho người cao tuổi với giao diện
              đơn giản, tính năng toàn diện và hỗ trợ 24/7.
            </p>
          </div>

          <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
            <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-16 lg:max-w-none lg:grid-cols-3">
              {features.map((feature) => (
                <div key={feature.name} className="flex flex-col">
                  <dt className="flex items-center gap-x-3 text-base font-semibold leading-7 text-elderly-text">
                    <feature.icon className="h-5 w-5 flex-none text-primary-600" />
                    {feature.name}
                  </dt>
                  <dd className="mt-4 flex flex-auto flex-col text-base leading-7 text-elderly-text-light">
                    <p className="flex-auto">{feature.description}</p>
                  </dd>
                </div>
              ))}
            </dl>
          </div>
        </div>
      </div>

      {/* Stats section */}
      <div className="bg-primary-50 py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:max-w-none">
            <div className="text-center">
              <h2 className="text-3xl font-bold tracking-tight text-elderly-text sm:text-4xl">
                Được tin tưởng bởi hàng nghìn người dùng
              </h2>
              <p className="mt-4 text-lg leading-8 text-elderly-text-light">
                Hệ thống đã giúp nhiều gia đình chăm sóc sức khỏe người thân
                hiệu quả
              </p>
            </div>
            <dl className="mt-16 grid grid-cols-1 gap-0.5 overflow-hidden rounded-2xl text-center sm:grid-cols-2 lg:grid-cols-4">
              {stats.map((stat) => (
                <div key={stat.name} className="flex flex-col bg-white p-8">
                  <dt className="text-sm font-semibold leading-6 text-elderly-text-light">
                    {stat.name}
                  </dt>
                  <dd className="order-first text-3xl font-bold tracking-tight text-primary-600">
                    {stat.value}
                  </dd>
                </div>
              ))}
            </dl>
          </div>
        </div>
      </div>

      {/* CTA section */}
      <div className="bg-primary-600">
        <div className="px-6 py-24 sm:px-6 sm:py-32 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-bold tracking-tight text-white sm:text-4xl">
              Sẵn sàng bắt đầu chăm sóc sức khỏe?
            </h2>
            <p className="mx-auto mt-6 max-w-xl text-lg leading-8 text-primary-100">
              Đăng ký ngay hôm nay để trải nghiệm hệ thống chăm sóc sức khỏe
              thông minh và toàn diện.
            </p>
            <div className="mt-10 flex items-center justify-center gap-x-6">
              <Link
                href="/auth/register"
                className="rounded-lg bg-white px-6 py-3 text-lg font-semibold text-primary-600 shadow-sm hover:bg-primary-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white transition-colors"
              >
                Đăng ký miễn phí
              </Link>
              <Link
                href="/auth/login"
                className="text-lg font-semibold leading-6 text-white hover:text-primary-100 transition-colors"
              >
                Đã có tài khoản? Đăng nhập <span aria-hidden="true">→</span>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LandingPage;
