import React, { useState } from "react";
import { XMarkIcon } from "@heroicons/react/24/outline";
import { healthApi } from "@/lib/api";

interface AddHealthRecordModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  selectedType?: string;
}

const healthTypes = [
  {
    type: "blood_pressure",
    name: "Huyết áp",
    unit: "mmHg",
    placeholder: "120/80",
    icon: "❤️",
    fields: ["systolic_pressure", "diastolic_pressure"],
  },
  {
    type: "blood_sugar",
    name: "Đường huyết",
    unit: "mg/dL",
    placeholder: "100",
    icon: "🩸",
    fields: ["blood_sugar"],
  },
  {
    type: "weight",
    name: "Cân nặng",
    unit: "kg",
    placeholder: "65.5",
    icon: "⚖️",
    fields: ["weight"],
  },
  {
    type: "heart_rate",
    name: "Nhịp tim",
    unit: "bpm",
    placeholder: "72",
    icon: "💓",
    fields: ["heart_rate"],
  },
  {
    type: "temperature",
    name: "Nhiệt độ",
    unit: "°C",
    placeholder: "36.5",
    icon: "🌡️",
    fields: ["temperature"],
  },
];

// Utility function to get local datetime string
const getLocalDateTimeString = () => {
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
};

const AddHealthRecordModal: React.FC<AddHealthRecordModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
  selectedType = "",
}) => {
  const [formData, setFormData] = useState({
    record_type: selectedType,
    systolic_pressure: "",
    diastolic_pressure: "",
    blood_sugar: "",
    weight: "",
    heart_rate: "",
    temperature: "",
    notes: "",
    recorded_at: getLocalDateTimeString(),
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  React.useEffect(() => {
    if (selectedType) {
      setFormData((prev) => ({ ...prev, record_type: selectedType }));
    }
  }, [selectedType]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.record_type) {
      setError("Vui lòng chọn loại chỉ số");
      return;
    }

    try {
      setIsSubmitting(true);
      setError(null);

      // Prepare data based on record type
      const submitData: any = {
        record_type: formData.record_type,
        notes: formData.notes || undefined,
        recorded_at: formData.recorded_at,
      };

      // Add specific fields based on type
      if (formData.record_type === "blood_pressure") {
        if (!formData.systolic_pressure || !formData.diastolic_pressure) {
          setError("Vui lòng nhập đầy đủ huyết áp tâm thu và tâm trương");
          return;
        }
        submitData.systolic_pressure = parseInt(formData.systolic_pressure);
        submitData.diastolic_pressure = parseInt(formData.diastolic_pressure);
      } else if (formData.record_type === "blood_sugar") {
        if (!formData.blood_sugar) {
          setError("Vui lòng nhập chỉ số đường huyết");
          return;
        }
        submitData.blood_sugar = parseFloat(formData.blood_sugar);
      } else if (formData.record_type === "weight") {
        if (!formData.weight) {
          setError("Vui lòng nhập cân nặng");
          return;
        }
        submitData.weight = parseFloat(formData.weight);
      } else if (formData.record_type === "heart_rate") {
        if (!formData.heart_rate) {
          setError("Vui lòng nhập nhịp tim");
          return;
        }
        submitData.heart_rate = parseInt(formData.heart_rate);
      } else if (formData.record_type === "temperature") {
        if (!formData.temperature) {
          setError("Vui lòng nhập nhiệt độ");
          return;
        }
        submitData.temperature = parseFloat(formData.temperature);
      }

      await healthApi.createRecord(submitData);

      // Reset form
      setFormData({
        record_type: "",
        systolic_pressure: "",
        diastolic_pressure: "",
        blood_sugar: "",
        weight: "",
        heart_rate: "",
        temperature: "",
        notes: "",
        recorded_at: getLocalDateTimeString(),
      });

      onSuccess();
      onClose();
    } catch (err: any) {
      console.error("Error creating health record:", err);
      setError(err.response?.data?.detail || "Có lỗi xảy ra khi lưu dữ liệu");
    } finally {
      setIsSubmitting(false);
    }
  };

  const getSelectedTypeConfig = () => {
    return healthTypes.find((t) => t.type === formData.record_type);
  };

  const renderInputFields = () => {
    const typeConfig = getSelectedTypeConfig();
    if (!typeConfig) return null;

    if (formData.record_type === "blood_pressure") {
      return (
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-1">
              Tâm thu *
            </label>
            <input
              type="number"
              value={formData.systolic_pressure}
              onChange={(e) =>
                setFormData({ ...formData, systolic_pressure: e.target.value })
              }
              placeholder="120"
              className="input w-full"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-1">
              Tâm trương *
            </label>
            <input
              type="number"
              value={formData.diastolic_pressure}
              onChange={(e) =>
                setFormData({ ...formData, diastolic_pressure: e.target.value })
              }
              placeholder="80"
              className="input w-full"
              required
            />
          </div>
        </div>
      );
    }

    const fieldName = typeConfig.fields[0];
    return (
      <div>
        <label className="block text-sm font-medium text-elderly-text mb-2">
          Giá trị * ({typeConfig.unit})
        </label>
        <input
          type="number"
          step={
            fieldName === "weight" ||
            fieldName === "temperature" ||
            fieldName === "blood_sugar"
              ? "0.1"
              : "1"
          }
          value={formData[fieldName as keyof typeof formData]}
          onChange={(e) =>
            setFormData({ ...formData, [fieldName]: e.target.value })
          }
          placeholder={typeConfig.placeholder}
          className="input w-full"
          required
        />
      </div>
    );
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-semibold text-elderly-text">
            Ghi nhận sức khỏe mới
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

          {/* Health Type Selection */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Loại chỉ số *
            </label>
            <select
              value={formData.record_type}
              onChange={(e) =>
                setFormData({ ...formData, record_type: e.target.value })
              }
              className="input w-full"
              required
            >
              <option value="">Chọn loại chỉ số</option>
              {healthTypes.map((type) => (
                <option key={type.type} value={type.type}>
                  {type.icon} {type.name} ({type.unit})
                </option>
              ))}
            </select>
          </div>

          {/* Value Input Fields */}
          {renderInputFields()}

          {/* Date Time */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Thời gian ghi nhận
            </label>
            <input
              type="datetime-local"
              value={formData.recorded_at}
              onChange={(e) =>
                setFormData({ ...formData, recorded_at: e.target.value })
              }
              className="input w-full"
            />
          </div>

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium text-elderly-text mb-2">
              Ghi chú
            </label>
            <textarea
              value={formData.notes}
              onChange={(e) =>
                setFormData({ ...formData, notes: e.target.value })
              }
              placeholder="Ghi chú thêm (tùy chọn)"
              className="input w-full h-20 resize-none"
            />
          </div>

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
              {isSubmitting ? "Đang lưu..." : "Lưu"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddHealthRecordModal;
