import React, { useState, useEffect } from "react";
import { withAuth } from "@/lib/auth";
import Layout from "@/components/Layout/Layout";
import { schedulesApi } from "@/lib/api";
import AddScheduleModal from "@/components/Schedules/AddScheduleModal";
import {
  CalendarIcon,
  ClockIcon,
  PlusIcon,
  PencilIcon,
  TrashIcon,
  MapPinIcon,
  PhoneIcon,
} from "@heroicons/react/24/outline";

interface Schedule {
  id: number;
  title: string;
  description?: string;
  schedule_type: string;
  scheduled_datetime: string;
  location?: string;
  doctor_name?: string;
  is_completed: boolean;
  created_at: string;
}

const SchedulesPage: React.FC = () => {
  const [schedules, setSchedules] = useState<Schedule[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingSchedule, setEditingSchedule] = useState<Schedule | null>(null);
  const [filterType, setFilterType] = useState<string>("all");

  const scheduleTypes = [
    { value: "all", label: "Tất cả", color: "bg-gray-100 text-gray-800" },
    {
      value: "medical_checkup",
      label: "Khám bệnh",
      color: "bg-blue-100 text-blue-800",
    },
    {
      value: "medication_reminder",
      label: "Nhắc uống thuốc",
      color: "bg-green-100 text-green-800",
    },
    {
      value: "exercise",
      label: "Tập thể dục",
      color: "bg-purple-100 text-purple-800",
    },
    { value: "other", label: "Khác", color: "bg-yellow-100 text-yellow-800" },
  ];

  useEffect(() => {
    loadSchedules();
  }, [filterType]);

  async function loadSchedules() {
    try {
      setIsLoading(true);
      setError(null);

      const params: any = { limit: 50 };
      if (filterType !== "all") {
        params.schedule_type = filterType;
      }

      const data = await schedulesApi.getSchedules(params);
      setSchedules(data);
    } catch (err: any) {
      console.error("Error loading schedules:", err);
      setError("Không thể tải danh sách lịch hẹn");
    } finally {
      setIsLoading(false);
    }
  }

  const handleDelete = async (id: number) => {
    if (!confirm("Bạn có chắc chắn muốn xóa lịch hẹn này?")) return;

    try {
      await schedulesApi.deleteSchedule(id);
      await loadSchedules();
    } catch (err: any) {
      console.error("Error deleting schedule:", err);
      setError("Không thể xóa lịch hẹn");
    }
  };

  const handleAdd = () => {
    setEditingSchedule(null);
    setShowAddForm(true);
  };

  const handleEdit = (schedule: Schedule) => {
    setEditingSchedule(schedule);
    setShowAddForm(true);
  };

  const getTypeConfig = (type: string) => {
    return scheduleTypes.find((t) => t.value === type) || scheduleTypes[0];
  };

  const isPast = (scheduledAt: string) => {
    return new Date(scheduledAt) < new Date();
  };

  const isToday = (scheduledAt: string) => {
    const today = new Date();
    const scheduleDate = new Date(scheduledAt);
    return today.toDateString() === scheduleDate.toDateString();
  };

  const isUpcoming = (scheduledAt: string) => {
    const scheduleDate = new Date(scheduledAt);
    const now = new Date();
    return scheduleDate > now;
  };

  if (isLoading) {
    return (
      <Layout title="Lịch hẹn">
        <div className="p-6">
          <div className="flex items-center justify-center min-h-96">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
          </div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout title="Lịch hẹn">
      <div className="p-6">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-3xl font-bold text-elderly-text">
            Lịch hẹn & Nhắc nhở
          </h1>
          <button
            onClick={handleAdd}
            className="btn btn-primary flex items-center space-x-2"
          >
            <PlusIcon className="h-5 w-5" />
            <span>Thêm lịch hẹn</span>
          </button>
        </div>

        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-red-800 text-sm">{error}</p>
            <button
              onClick={loadSchedules}
              className="mt-2 text-red-600 hover:text-red-800 text-sm underline"
            >
              Thử lại
            </button>
          </div>
        )}

        {/* Filter Tabs */}
        <div className="mb-6">
          <div className="flex flex-wrap gap-2">
            {scheduleTypes.map((type) => (
              <button
                key={type.value}
                onClick={() => setFilterType(type.value)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  filterType === type.value
                    ? type.color
                    : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                }`}
              >
                {type.label}
              </button>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* Today's Schedule */}
          <div className="card">
            <h2 className="text-xl font-semibold mb-4 flex items-center">
              <CalendarIcon className="h-5 w-5 mr-2 text-primary-600" />
              Lịch hôm nay
            </h2>
            <div className="space-y-3">
              {schedules.filter((s) => isToday(s.scheduled_datetime)).length >
              0 ? (
                schedules
                  .filter((s) => isToday(s.scheduled_datetime))
                  .map((schedule) => {
                    const typeConfig = getTypeConfig(schedule.schedule_type);
                    return (
                      <div
                        key={schedule.id}
                        className={`p-3 border rounded-lg ${typeConfig.color}`}
                      >
                        <div className="flex justify-between items-start">
                          <div className="flex-1">
                            <h3 className="font-medium">{schedule.title}</h3>
                            {schedule.doctor_name && (
                              <p className="text-sm opacity-75">
                                <PhoneIcon className="h-3 w-3 inline mr-1" />
                                {schedule.doctor_name}
                              </p>
                            )}
                            {schedule.location && (
                              <p className="text-sm opacity-75">
                                <MapPinIcon className="h-3 w-3 inline mr-1" />
                                {schedule.location}
                              </p>
                            )}
                          </div>
                          <span className="font-medium">
                            {new Date(
                              schedule.scheduled_datetime
                            ).toLocaleTimeString("vi-VN", {
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                          </span>
                        </div>
                      </div>
                    );
                  })
              ) : (
                <div className="text-center py-6">
                  <p className="text-gray-500">Không có lịch hẹn nào hôm nay</p>
                </div>
              )}
            </div>
          </div>

          {/* Upcoming Reminders */}
          <div className="card">
            <h2 className="text-xl font-semibold mb-4 flex items-center">
              <ClockIcon className="h-5 w-5 mr-2 text-primary-600" />
              Nhắc nhở sắp tới
            </h2>
            <div className="space-y-3">
              {schedules
                .filter(
                  (s) =>
                    isUpcoming(s.scheduled_datetime) &&
                    !isToday(s.scheduled_datetime)
                )
                .slice(0, 5).length > 0 ? (
                schedules
                  .filter(
                    (s) =>
                      isUpcoming(s.scheduled_datetime) &&
                      !isToday(s.scheduled_datetime)
                  )
                  .slice(0, 5)
                  .map((schedule) => {
                    const typeConfig = getTypeConfig(schedule.schedule_type);
                    return (
                      <div
                        key={schedule.id}
                        className={`p-3 border rounded-lg ${typeConfig.color}`}
                      >
                        <div className="flex justify-between items-start">
                          <div className="flex-1">
                            <h3 className="font-medium">{schedule.title}</h3>
                            {schedule.doctor_name && (
                              <p className="text-sm opacity-75">
                                {schedule.doctor_name}
                              </p>
                            )}
                          </div>
                          <span className="font-medium text-sm">
                            {new Date(
                              schedule.scheduled_datetime
                            ).toLocaleDateString("vi-VN")}
                          </span>
                        </div>
                      </div>
                    );
                  })
              ) : (
                <div className="text-center py-6">
                  <p className="text-gray-500">Không có nhắc nhở sắp tới</p>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* All Schedules */}
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Tất cả lịch hẹn</h2>
          {schedules.length > 0 ? (
            <div className="space-y-4">
              {schedules.map((schedule) => {
                const typeConfig = getTypeConfig(schedule.schedule_type);
                const scheduleDate = new Date(schedule.scheduled_datetime);
                const isOverdue =
                  isPast(schedule.scheduled_datetime) && !schedule.is_completed;

                return (
                  <div
                    key={schedule.id}
                    className={`p-4 border rounded-lg ${
                      isOverdue
                        ? "bg-red-50 border-red-200"
                        : isToday(schedule.scheduled_datetime)
                        ? "bg-blue-50 border-blue-200"
                        : "bg-white border-gray-200"
                    }`}
                  >
                    <div className="flex justify-between items-start">
                      <div className="flex-1">
                        <div className="flex items-center space-x-3 mb-2">
                          <h3 className="text-lg font-semibold">
                            {schedule.title}
                          </h3>
                          <span
                            className={`px-2 py-1 rounded-full text-xs ${typeConfig.color}`}
                          >
                            {typeConfig.label}
                          </span>
                          {isOverdue && (
                            <span className="px-2 py-1 rounded-full text-xs bg-red-100 text-red-800">
                              Quá hạn
                            </span>
                          )}
                          {schedule.is_completed && (
                            <span className="px-2 py-1 rounded-full text-xs bg-green-100 text-green-800">
                              Hoàn thành
                            </span>
                          )}
                        </div>

                        {schedule.description && (
                          <p className="text-gray-600 mb-2">
                            {schedule.description}
                          </p>
                        )}

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-gray-600">
                          <div>
                            <p>
                              <CalendarIcon className="h-4 w-4 inline mr-1" />
                              {scheduleDate.toLocaleDateString("vi-VN")} -{" "}
                              {scheduleDate.toLocaleTimeString("vi-VN", {
                                hour: "2-digit",
                                minute: "2-digit",
                              })}
                            </p>
                            {schedule.location && (
                              <p>
                                <MapPinIcon className="h-4 w-4 inline mr-1" />
                                {schedule.location}
                              </p>
                            )}
                          </div>
                          <div>
                            {schedule.doctor_name && (
                              <p>👨‍⚕️ {schedule.doctor_name}</p>
                            )}
                          </div>
                        </div>
                      </div>

                      <div className="flex space-x-2 ml-4">
                        <button
                          onClick={() => handleEdit(schedule)}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg"
                          title="Chỉnh sửa"
                        >
                          <PencilIcon className="h-5 w-5" />
                        </button>
                        <button
                          onClick={() => handleDelete(schedule.id)}
                          className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
                          title="Xóa"
                        >
                          <TrashIcon className="h-5 w-5" />
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="text-center py-12">
              <div className="text-6xl mb-4">📅</div>
              <h3 className="text-xl font-semibold text-elderly-text mb-2">
                Chưa có lịch hẹn nào
              </h3>
              <p className="text-elderly-text-light mb-6">
                Hãy thêm lịch hẹn đầu tiên để bắt đầu theo dõi
              </p>
              <button onClick={handleAdd} className="btn btn-primary">
                Thêm lịch hẹn đầu tiên
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Add/Edit Schedule Modal */}
      <AddScheduleModal
        isOpen={showAddForm}
        onClose={() => {
          setShowAddForm(false);
          setEditingSchedule(null);
        }}
        onSuccess={loadSchedules}
        editingSchedule={editingSchedule}
      />
    </Layout>
  );
};

export default withAuth(SchedulesPage);
