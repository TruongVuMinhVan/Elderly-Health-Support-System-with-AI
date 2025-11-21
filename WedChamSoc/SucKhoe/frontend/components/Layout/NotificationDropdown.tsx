import React, { useState, useEffect } from "react";
import { Menu, Transition } from "@headlessui/react";
import { BellIcon, CalendarIcon, BeakerIcon } from "@heroicons/react/24/outline";
import { schedulesApi } from "@/lib/api";
import { Schedule } from "@/types";
import { format } from "date-fns";
import Link from "next/link";

interface NotificationDropdownProps {
  notificationsCount: number;
}

const NotificationDropdown: React.FC<NotificationDropdownProps> = ({
  notificationsCount,
}) => {
  const [notifications, setNotifications] = useState<Schedule[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadNotifications();
    // Refresh every 5 minutes
    const interval = setInterval(loadNotifications, 5 * 60 * 1000);
    return () => clearInterval(interval);
  }, []);

  const loadNotifications = async () => {
    try {
      setIsLoading(true);
      // Get upcoming schedules as notifications
      const upcomingSchedules = await schedulesApi.getSchedules({
        upcoming_only: true,
        limit: 10,
      });
      setNotifications(upcomingSchedules || []);
    } catch (error) {
      console.error("Error loading notifications:", error);
      setNotifications([]);
    } finally {
      setIsLoading(false);
    }
  };

  const getNotificationIcon = (scheduleType: string) => {
    switch (scheduleType) {
      case "medication":
        return BeakerIcon;
      case "appointment":
      case "checkup":
        return CalendarIcon;
      default:
        return BellIcon;
    }
  };

  const getNotificationColor = (scheduleType: string) => {
    switch (scheduleType) {
      case "medication":
        return "text-green-600 dark:text-green-400";
      case "appointment":
        return "text-blue-600 dark:text-blue-400";
      case "checkup":
        return "text-orange-600 dark:text-orange-400";
      default:
        return "text-gray-600 dark:text-gray-400";
    }
  };

  const formatNotificationTime = (datetime: string) => {
    try {
      const date = new Date(datetime);
      const now = new Date();
      const diffInHours = (date.getTime() - now.getTime()) / (1000 * 60 * 60);

      if (diffInHours < 0) {
        return "Đã qua";
      } else if (diffInHours < 1) {
        const minutes = Math.floor(diffInHours * 60);
        return minutes > 0 ? `Trong ${minutes} phút` : "Sắp tới";
      } else if (diffInHours < 24) {
        return `Trong ${Math.floor(diffInHours)} giờ`;
      } else if (diffInHours < 48) {
        return "Ngày mai";
      } else {
        return format(date, "dd/MM/yyyy HH:mm");
      }
    } catch {
      return datetime;
    }
  };

  return (
    <Menu as="div" className="relative">
      <Menu.Button className="relative p-2 text-elderly-text dark:text-dark-text hover:bg-elderly-hover-bg dark:hover:bg-dark-hover-bg rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 transition-colors">
        <BellIcon className="h-6 w-6 text-elderly-text dark:text-dark-text" />
        {notificationsCount > 0 && (
          <span className="absolute -top-1 -right-1 h-5 w-5 bg-red-500 text-white text-xs rounded-full flex items-center justify-center font-medium">
            {notificationsCount > 9 ? "9+" : notificationsCount}
          </span>
        )}
      </Menu.Button>

      <Transition
        enter="transition ease-out duration-100"
        enterFrom="transform opacity-0 scale-95"
        enterTo="transform opacity-100 scale-100"
        leave="transition ease-in duration-75"
        leaveFrom="transform opacity-100 scale-100"
        leaveTo="transform opacity-0 scale-95"
      >
        <Menu.Items className="absolute right-0 z-50 mt-2 w-80 origin-top-right rounded-lg bg-white dark:bg-dark-card-bg shadow-lg ring-1 ring-black ring-opacity-5 dark:ring-dark-border focus:outline-none max-h-96 overflow-y-auto">
          <div className="p-4 border-b border-elderly-border dark:border-dark-border">
            <h3 className="text-lg font-semibold text-elderly-text dark:text-dark-text">
              Thông báo
            </h3>
          </div>

          <div className="py-2">
            {isLoading ? (
              <div className="px-4 py-8 text-center text-elderly-text-light dark:text-dark-text-light">
                Đang tải...
              </div>
            ) : notifications.length === 0 ? (
              <div className="px-4 py-8 text-center text-elderly-text-light dark:text-dark-text-light">
                <BellIcon className="h-12 w-12 mx-auto mb-2 opacity-50 text-elderly-text-light dark:text-dark-text-light" />
                <p>Không có thông báo nào</p>
              </div>
            ) : (
              notifications.map((notification) => {
                const Icon = getNotificationIcon(notification.schedule_type);
                const iconColor = getNotificationColor(notification.schedule_type);

                return (
                  <Menu.Item key={notification.id}>
                    {({ active }) => (
                      <Link
                        href="/schedules"
                        className={cn(
                          "flex items-start px-4 py-3 text-sm transition-colors",
                          active
                            ? "bg-elderly-hover-bg dark:bg-dark-hover-bg"
                            : "bg-transparent"
                        )}
                      >
                        <div className="flex-shrink-0 mt-1">
                          <Icon className={`h-5 w-5 ${iconColor}`} />
                        </div>
                        <div className="ml-3 flex-1 min-w-0">
                          <p className="text-sm font-medium text-elderly-text dark:text-dark-text">
                            {notification.title}
                          </p>
                          <p className="text-xs text-elderly-text-light dark:text-dark-text-light mt-1">
                            {formatNotificationTime(notification.scheduled_datetime)}
                          </p>
                          {notification.location && (
                            <p className="text-xs text-elderly-text-light dark:text-dark-text-light mt-1">
                              📍 {notification.location}
                            </p>
                          )}
                        </div>
                      </Link>
                    )}
                  </Menu.Item>
                );
              })
            )}
          </div>

          {notifications.length > 0 && (
            <div className="p-2 border-t border-elderly-border dark:border-dark-border">
              <Link
                href="/schedules"
                className="block w-full text-center px-4 py-2 text-sm font-medium text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 rounded-lg hover:bg-elderly-hover-bg dark:hover:bg-dark-hover-bg transition-colors"
              >
                Xem tất cả
              </Link>
            </div>
          )}
        </Menu.Items>
      </Transition>
    </Menu>
  );
};

function cn(...classes: (string | boolean | undefined)[]): string {
  return classes.filter(Boolean).join(" ");
}

export default NotificationDropdown;

