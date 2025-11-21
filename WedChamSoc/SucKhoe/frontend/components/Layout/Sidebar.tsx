import React from "react";
import Link from "next/link";
import { useRouter } from "next/router";
import {
  HomeIcon,
  HeartIcon,
  BeakerIcon,
  CalendarIcon,
  ChatBubbleLeftRightIcon,
  UserIcon,
  Cog6ToothIcon,
} from "@heroicons/react/24/outline";
import { cn } from "@/lib/utils";

const navigation = [
  { name: "Trang chủ", href: "/", icon: HomeIcon },
  { name: "Sức khỏe", href: "/health", icon: HeartIcon },
  { name: "Thuốc", href: "/medications", icon: BeakerIcon },
  { name: "Lịch hẹn", href: "/schedules", icon: CalendarIcon },
  { name: "Tư vấn AI", href: "/chat", icon: ChatBubbleLeftRightIcon },
  { name: "Hồ sơ", href: "/profile", icon: UserIcon },
  { name: "Cài đặt", href: "/settings", icon: Cog6ToothIcon },
];

const Sidebar: React.FC = () => {
  const router = useRouter();

  return (
    <div className="flex flex-col h-full">
      <nav className="flex-1 px-4 py-6 space-y-2">
        {navigation.map((item) => {
          const isActive = router.pathname === item.href;
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                "flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-colors",
                isActive
                  ? "bg-primary-100 dark:bg-primary-900 text-primary-700 dark:text-primary-300"
                  : "text-elderly-text dark:text-dark-text hover:bg-elderly-hover-bg dark:hover:bg-dark-hover-bg hover:text-primary-600 dark:hover:text-primary-400"
              )}
            >
              <item.icon className="mr-3 h-5 w-5" />
              {item.name}
            </Link>
          );
        })}
      </nav>
    </div>
  );
};

export default Sidebar;
