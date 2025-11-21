import React, { useState, useEffect } from "react";
import { XMarkIcon } from "@heroicons/react/24/outline";
import { schedulesApi } from "@/lib/api";
import { ScheduleType } from "@/types";

interface AddScheduleModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  editingSchedule?: any;
}

const AddScheduleModal: React.FC<AddScheduleModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
  editingSchedule,
}) => {
  const [formData, setFormData] = useState({
    title: "",
    description: "",
    appointment_date: "",
    appointment_time: "",
    location: "",
    doctor_name: "",
    appointment_type: "",
    status: "scheduled",
    reminder_minutes: 30,
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isEditing = !!editingSchedule;

  useEffect(() => {
    if (editingSchedule) {
      // Convert datetime to separate date and time
      const scheduledDateTime = new Date(editingSchedule.scheduled_datetime);
      const date = scheduledDateTime.toISOString().split("T")[0];
      const time = scheduledDateTime.toTimeString().slice(0, 5);

      setFormData({
        title: editingSchedule.title || "",
        description: editingSchedule.description || "",
        appointment_date: date,
        appointment_time: time,
        location: editingSchedule.location || "",
        doctor_name: editingSchedule.doctor_name || "",
        appointment_type: editingSchedule.appointment_type || "",
        status: editingSchedule.status || "scheduled",
        reminder_minutes: editingSchedule.reminder_minutes || 30,
      });
    } else {
      setFormData({
        title: "",
        description: "",
        appointment_date: "",
        appointment_time: "",
        location: "",
        doctor_name: "",
        appointment_type: "",
        status: "scheduled",
        reminder_minutes: 30,
      });
    }
  }, [editingSchedule]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.title.trim()) {
      setError("Vui lòng nhập tiêu đề lịch hẹn");
      return;
    }

    if (!formData.appointment_date || !formData.appointment_time) {
      setError("Vui lòng chọn ngày và giờ hẹn");
      return;
    }

    try {
      setIsSubmitting(true);
      setError(null);

      // Combine date and time into datetime
      const scheduledDateTime = `${formData.appointment_date}T${formData.appointment_time}:00`;

      const submitData = {
        title: formData.title,
        description: formData.description || undefined,
        scheduled_datetime: scheduledDateTime,
        location: formData.location || undefined,
        doctor_name: formData.doctor_name || undefined,
        schedule_type: "appointment" as ScheduleType, // Default to appointment type
        is_recurring: false,
        recurrence_pattern: undefined,
      };

      if (isEditing) {
        await schedulesApi.updateSchedule(editingSchedule.id, submitData);
      } else {
        await schedulesApi.createSchedule(submitData);
      }

      // Reset form
      setFormData({
        title: "",
        description: "",
        appointment_date: "",
        appointment_time: "",
        location: "",
        doctor_name: "",
        appointment_type: "",
        status: "scheduled",
        reminder_minutes: 30,
      });

      onSuccess();
      onClose();
    } catch (err: any) {
      console.error("Error saving schedule:", err);
      setError(err.response?.data?.detail || "Có lỗi xảy ra khi lưu dữ liệu");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-semibold text-elderly-text">
            {isEditing ? "Chỉnh sửa lịch hẹn" : "Thêm lịch hẹn mới"}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {error && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-red-800 text-sm">{error}</p>
            </div>
          )}

          {/* Title */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Tiêu đề *
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) =>
                setFormData({ ...formData, title: e.target.value })
              }
              placeholder="Ví dụ: Khám tim mạch"
              className="input w-full"
              required
            />
          </div>

          {/* Date and Time */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-elderly-text mb-2">
                Ngày hẹn *
              </label>
              <input
                type="date"
                value={formData.appointment_date}
                onChange={(e) =>
                  setFormData({ ...formData, appointment_date: e.target.value })
                }
                className="input w-full"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-elderly-text mb-2">
                Giờ hẹn *
              </label>
              <input
                type="time"
                value={formData.appointment_time}
                onChange={(e) =>
                  setFormData({ ...formData, appointment_time: e.target.value })
                }
                className="input w-full"
                required
              />
            </div>
          </div>

          {/* Doctor Name */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Tên bác sĩ
            </label>
            <input
              type="text"
              value={formData.doctor_name}
              onChange={(e) =>
                setFormData({ ...formData, doctor_name: e.target.value })
              }
              placeholder="Ví dụ: BS. Nguyễn Văn A"
              className="input w-full"
            />
          </div>

          {/* Appointment Type */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Loại hẹn
            </label>
            <select
              value={formData.appointment_type}
              onChange={(e) =>
                setFormData({ ...formData, appointment_type: e.target.value })
              }
              className="input w-full"
            >
              <option value="">Chọn loại hẹn</option>
              <option value="Khám tổng quát">Khám tổng quát</option>
              <option value="Khám chuyên khoa">Khám chuyên khoa</option>
              <option value="Tái khám">Tái khám</option>
              <option value="Xét nghiệm">Xét nghiệm</option>
              <option value="Chụp chiếu">Chụp chiếu</option>
              <option value="Khác">Khác</option>
            </select>
          </div>

          {/* Location */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Địa điểm
            </label>
            <input
              type="text"
              value={formData.location}
              onChange={(e) =>
                setFormData({ ...formData, location: e.target.value })
              }
              placeholder="Ví dụ: Bệnh viện Bạch Mai"
              className="input w-full"
            />
          </div>

          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Mô tả
            </label>
            <textarea
              value={formData.description}
              onChange={(e) =>
                setFormData({ ...formData, description: e.target.value })
              }
              placeholder="Ghi chú thêm về cuộc hẹn"
              className="input w-full h-20 resize-none"
            />
          </div>

          {/* Reminder */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Nhắc nhở trước (phút)
            </label>
            <select
              value={formData.reminder_minutes}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  reminder_minutes: parseInt(e.target.value),
                })
              }
              className="input w-full"
            >
              <option value={15}>15 phút</option>
              <option value={30}>30 phút</option>
              <option value={60}>1 giờ</option>
              <option value={120}>2 giờ</option>
              <option value={1440}>1 ngày</option>
            </select>
          </div>

          {/* Status (for editing) */}
          {isEditing && (
            <div>
              <label className="block text-sm font-medium text-elderly-text mb-2">
                Trạng thái
              </label>
              <select
                value={formData.status}
                onChange={(e) =>
                  setFormData({ ...formData, status: e.target.value })
                }
                className="input w-full"
              >
                <option value="scheduled">Đã lên lịch</option>
                <option value="completed">Đã hoàn thành</option>
                <option value="cancelled">Đã hủy</option>
                <option value="rescheduled">Đã dời lịch</option>
              </select>
            </div>
          )}

          {/* Submit Buttons */}
          <div className="flex space-x-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="btn btn-secondary flex-1"
              disabled={isSubmitting}
            >
              Hủy
            </button>
            <button
              type="submit"
              className="btn btn-primary flex-1"
              disabled={isSubmitting}
            >
              {isSubmitting ? "Đang lưu..." : isEditing ? "Cập nhật" : "Thêm"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddScheduleModal;
