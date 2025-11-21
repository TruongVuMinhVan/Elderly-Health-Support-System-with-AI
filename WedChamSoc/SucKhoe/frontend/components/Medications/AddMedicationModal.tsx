import React, { useState, useEffect } from "react";
import { XMarkIcon } from "@heroicons/react/24/outline";
import { medicationsApi } from "@/lib/api";

interface AddMedicationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  editingMedication?: any;
}

const AddMedicationModal: React.FC<AddMedicationModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
  editingMedication,
}) => {
  const [formData, setFormData] = useState({
    medication_name: "",
    dosage: "",
    frequency: "",
    instructions: "",
    start_date: "",
    end_date: "",
    is_active: true,
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isEditing = !!editingMedication;

  useEffect(() => {
    if (editingMedication) {
      setFormData({
        medication_name: editingMedication.medication_name || "",
        dosage: editingMedication.dosage || "",
        frequency: editingMedication.frequency || "",
        instructions: editingMedication.instructions || "",
        start_date: editingMedication.start_date || "",
        end_date: editingMedication.end_date || "",
        is_active: editingMedication.is_active ?? true,
      });
    } else {
      setFormData({
        medication_name: "",
        dosage: "",
        frequency: "",
        instructions: "",
        start_date: "",
        end_date: "",
        is_active: true,
      });
    }
  }, [editingMedication]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.medication_name.trim()) {
      setError("Vui lòng nhập tên thuốc");
      return;
    }

    try {
      setIsSubmitting(true);
      setError(null);

      const submitData = {
        ...formData,
        start_date: formData.start_date || undefined,
        end_date: formData.end_date || undefined,
      };

      if (isEditing) {
        await medicationsApi.updateMedication(editingMedication.id, submitData);
      } else {
        await medicationsApi.createMedication(submitData);
      }

      // Reset form
      setFormData({
        medication_name: "",
        dosage: "",
        frequency: "",
        instructions: "",
        start_date: "",
        end_date: "",
        is_active: true,
      });

      onSuccess();
      onClose();
    } catch (err: any) {
      console.error("Error saving medication:", err);
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
            {isEditing ? "Chỉnh sửa thuốc" : "Thêm thuốc mới"}
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

          {/* Medication Name */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Tên thuốc *
            </label>
            <input
              type="text"
              value={formData.medication_name}
              onChange={(e) =>
                setFormData({ ...formData, medication_name: e.target.value })
              }
              placeholder="Ví dụ: Paracetamol"
              className="input w-full"
              required
            />
          </div>

          {/* Dosage */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Liều lượng
            </label>
            <input
              type="text"
              value={formData.dosage}
              onChange={(e) =>
                setFormData({ ...formData, dosage: e.target.value })
              }
              placeholder="Ví dụ: 500mg"
              className="input w-full"
            />
          </div>

          {/* Frequency */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Tần suất sử dụng
            </label>
            <select
              value={formData.frequency}
              onChange={(e) =>
                setFormData({ ...formData, frequency: e.target.value })
              }
              className="input w-full"
            >
              <option value="">Chọn tần suất</option>
              <option value="1 lần/ngày">1 lần/ngày</option>
              <option value="2 lần/ngày">2 lần/ngày</option>
              <option value="3 lần/ngày">3 lần/ngày</option>
              <option value="Khi cần thiết">Khi cần thiết</option>
              <option value="Khác">Khác</option>
            </select>
          </div>

          {/* Instructions */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Hướng dẫn sử dụng
            </label>
            <textarea
              value={formData.instructions}
              onChange={(e) =>
                setFormData({ ...formData, instructions: e.target.value })
              }
              placeholder="Ví dụ: Uống sau bữa ăn"
              className="input w-full h-20 resize-none"
            />
          </div>

          {/* Date Range */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-elderly-text mb-2">
                Ngày bắt đầu
              </label>
              <input
                type="date"
                value={formData.start_date}
                onChange={(e) =>
                  setFormData({ ...formData, start_date: e.target.value })
                }
                className="input w-full"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-elderly-text mb-2">
                Ngày kết thúc
              </label>
              <input
                type="date"
                value={formData.end_date}
                onChange={(e) =>
                  setFormData({ ...formData, end_date: e.target.value })
                }
                className="input w-full"
              />
            </div>
          </div>

          {/* Active Status */}
          {isEditing && (
            <div className="flex items-center">
              <input
                type="checkbox"
                id="is_active"
                checked={formData.is_active}
                onChange={(e) =>
                  setFormData({ ...formData, is_active: e.target.checked })
                }
                className="mr-2"
              />
              <label htmlFor="is_active" className="text-sm text-elderly-text">
                Đang sử dụng
              </label>
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

export default AddMedicationModal;
