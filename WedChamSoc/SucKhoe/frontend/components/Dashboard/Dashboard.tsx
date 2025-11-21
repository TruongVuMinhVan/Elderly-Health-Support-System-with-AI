import React, { useState, useEffect } from "react";
import { useAuth } from "@/lib/auth";
import {
  dashboardApi,
  healthApi,
  medicationsApi,
  schedulesApi,
} from "@/lib/api";
import {
  HeartIcon,
  BeakerIcon,
  CalendarIcon,
  ChartBarIcon,
} from "@heroicons/react/24/outline";

interface DashboardStats {
  healthRecords: number;
  activeMedications: number;
  upcomingSchedules: number;
  weeklyReports: number;
}

interface TodayReminder {
  id: string;
  title: string;
  time: string;
  type: "medication" | "appointment" | "health";
  color: string;
}

const Dashboard: React.FC = () => {
  const { user } = useAuth();
  const [stats, setStats] = useState<DashboardStats>({
    healthRecords: 0,
    activeMedications: 0,
    upcomingSchedules: 0,
    weeklyReports: 0,
  });
  const [todayReminders, setTodayReminders] = useState<TodayReminder[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setIsLoading(true);
      setError(null);

      // Load dashboard stats in parallel
      const [healthRecords, medications, schedules] = await Promise.all([
        healthApi.getRecords({ limit: 100 }).catch(() => []),
        medicationsApi.getMedications(true).catch(() => []),
        schedulesApi
          .getSchedules({ upcoming_only: true, limit: 10 })
          .catch(() => []),
      ]);

      // Calculate stats
      const now = new Date();
      const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      const weeklyHealthRecords = healthRecords.filter(
        (record: any) => new Date(record.recorded_at) >= weekAgo
      );

      setStats({
        healthRecords: healthRecords.length,
        activeMedications: medications.length,
        upcomingSchedules: schedules.length,
        weeklyReports: weeklyHealthRecords.length,
      });

      // Load today's reminders
      const today = new Date().toISOString().split("T")[0];
      const todaySchedules = schedules.filter((schedule: any) =>
        schedule.scheduled_at.startsWith(today)
      );

      const reminders: TodayReminder[] = [
        ...todaySchedules.map((schedule: any) => ({
          id: `schedule-${schedule.id}`,
          title: schedule.title,
          time: new Date(schedule.scheduled_at).toLocaleTimeString("vi-VN", {
            hour: "2-digit",
            minute: "2-digit",
          }),
          type: "appointment" as const,
          color: "bg-blue-50 border-blue-200 text-blue-800",
        })),
        // Add medication reminders (simplified - could be enhanced)
        ...medications.slice(0, 2).map((med: any, index: number) => ({
          id: `med-${med.id}`,
          title: `Uống ${med.name}`,
          time: index === 0 ? "8:00" : "20:00",
          type: "medication" as const,
          color: "bg-yellow-50 border-yellow-200 text-yellow-800",
        })),
      ];

      setTodayReminders(reminders.slice(0, 3)); // Limit to 3 reminders
    } catch (err: any) {
      console.error("Error loading dashboard data:", err);
      setError("Không thể tải dữ liệu dashboard");
    } finally {
      setIsLoading(false);
    }
  };

  const statsConfig = [
    {
      name: "Chỉ số sức khỏe",
      value: stats.healthRecords.toString(),
      icon: HeartIcon,
      color: "text-red-600 bg-red-100",
    },
    {
      name: "Thuốc đang dùng",
      value: stats.activeMedications.toString(),
      icon: BeakerIcon,
      color: "text-blue-600 bg-blue-100",
    },
    {
      name: "Lịch hẹn sắp tới",
      value: stats.upcomingSchedules.toString(),
      icon: CalendarIcon,
      color: "text-green-600 bg-green-100",
    },
    // {
    //   name: "Báo cáo tuần này",
    //   value: stats.weeklyReports.toString(),
    //   icon: ChartBarIcon,
    //   color: "text-purple-600 bg-purple-100",
    // },
  ];

  if (isLoading) {
    return (
      <div className="p-6">
        <div className="flex items-center justify-center min-h-96">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-elderly-text">
          Xin chào, {user?.full_name || "Bạn"}!
        </h1>
        <p className="text-elderly-text-light mt-2">
          Chào mừng bạn đến với hệ thống chăm sóc sức khỏe
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        {statsConfig.map((stat) => (
          <div key={stat.name} className="card">
            <div className="flex items-center">
              <div className={`p-3 rounded-lg ${stat.color}`}>
                <stat.icon className="h-6 w-6" />
              </div>
              <div className="ml-4">
                <p className="text-2xl font-bold text-elderly-text">
                  {stat.value}
                </p>
                <p className="text-elderly-text-light">{stat.name}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 lg:grid-cols-1 gap-6">
        {/* <div className="card">
          <h2 className="text-xl font-semibold text-elderly-text mb-4">
            Hành động nhanh
          </h2>
          <div className="space-y-3">
            <button
              onClick={() => (window.location.href = "/health")}
              className="w-full btn btn-primary text-left"
            >
              Ghi nhận chỉ số sức khỏe
            </button>
            <button
              onClick={() => (window.location.href = "/schedules")}
              className="w-full btn btn-secondary text-left"
            >
              Đặt lịch nhắc nhở
            </button>
            <button
              onClick={() => (window.location.href = "/chat")}
              className="w-full btn btn-secondary text-left"
            >
              Tư vấn với AI
            </button>
          </div>
        </div> */}

        <div className="card">
          <h2 className="text-xl font-semibold text-elderly-text mb-4">
            Nhắc nhở hôm nay
          </h2>
          <div className="space-y-3">
            {todayReminders.length > 0 ? (
              todayReminders.map((reminder) => (
                <div
                  key={reminder.id}
                  className={`p-3 border rounded-lg ${reminder.color}`}
                >
                  <p className="font-medium">{reminder.title}</p>
                  <p className="text-sm opacity-75">{reminder.time}</p>
                </div>
              ))
            ) : (
              <div className="p-3 bg-gray-50 border border-gray-200 rounded-lg">
                <p className="text-gray-600 text-center">
                  Không có nhắc nhở nào hôm nay
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
