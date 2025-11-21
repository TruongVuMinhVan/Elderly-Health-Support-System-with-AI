import React, { useState, useEffect } from "react";
import { withAuth } from "@/lib/auth";
import Layout from "@/components/Layout/Layout";
import { medicationsApi } from "@/lib/api";
import type { Medication as ApiMedication } from "@/types";
import AddMedicationModal from "@/components/Medications/AddMedicationModal";
import {
  PlusIcon,
  PencilIcon,
  TrashIcon,
  ClockIcon,
} from "@heroicons/react/24/outline";

// Align with shared API type
type Medication = ApiMedication & {
  // adapt display name since API uses medication_name
  name?: string;
};

const MedicationsPage: React.FC = () => {
  const [medications, setMedications] = useState<Medication[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingMed, setEditingMed] = useState<Medication | null>(null);
  const [showInactive, setShowInactive] = useState(false);

  useEffect(() => {
    loadMedications();
  }, [showInactive]);

  const loadMedications = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const data = await medicationsApi.getMedications(!showInactive);
      // Map to include `name` for UI while preserving API shape
      const mapped = data.map((m: ApiMedication) => ({
        ...m,
        name: (m as any).name || m.medication_name,
      }));
      setMedications(mapped);
    } catch (err: any) {
      console.error("Error loading medications:", err);
      setError("Không thể tải danh sách thuốc");
    } finally {
      setIsLoading(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Bạn có chắc chắn muốn xóa thuốc này?")) return;

    try {
      await medicationsApi.deleteMedication(id);
      await loadMedications();
    } catch (err: any) {
      console.error("Error deleting medication:", err);
      setError("Không thể xóa thuốc");
    }
  };

  const handleAdd = () => {
    setEditingMed(null);
    setShowAddForm(true);
  };

  const handleEdit = (medication: Medication) => {
    setEditingMed(medication);
    setShowAddForm(true);
  };

  const getStatusColor = (medication: Medication) => {
    if (!medication.is_active) {
      return "bg-gray-100 text-gray-800";
    }

    if (medication.end_date) {
      const endDate = new Date(medication.end_date);
      const today = new Date();
      const daysLeft = Math.ceil(
        (endDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)
      );

      if (daysLeft <= 0) {
        return "bg-red-100 text-red-800";
      } else if (daysLeft <= 7) {
        return "bg-yellow-100 text-yellow-800";
      }
    }

    return "bg-green-100 text-green-800";
  };

  const getStatusText = (medication: Medication) => {
    if (!medication.is_active) {
      return "Đã ngừng";
    }

    if (medication.end_date) {
      const endDate = new Date(medication.end_date);
      const today = new Date();
      const daysLeft = Math.ceil(
        (endDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)
      );

      if (daysLeft <= 0) {
        return "Hết hạn";
      } else if (daysLeft <= 7) {
        return `Còn ${daysLeft} ngày`;
      }
    }

    return "Đang dùng";
  };

  if (isLoading) {
    return (
      <Layout title="Quản lý thuốc">
        <div className="p-6">
          <div className="flex items-center justify-center min-h-96">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
          </div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout title="Quản lý thuốc">
      <div className="p-6">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-3xl font-bold text-elderly-text">
            Quản lý thuốc
          </h1>
          <div className="flex space-x-4">
            {/* <button
              onClick={() => setShowInactive(!showInactive)}
              className={`btn ${
                showInactive ? "btn-secondary" : "btn-outline"
              }`}
            >
              {showInactive ? "Ẩn thuốc đã ngừng" : "Hiện thuốc đã ngừng"}
            </button> */}
            <button
              onClick={handleAdd}
              className="btn btn-primary flex items-center space-x-2"
            >
              <PlusIcon className="h-5 w-5" />
              <span>Thêm thuốc mới</span>
            </button>
          </div>
        </div>

        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-red-800 text-sm">{error}</p>
            <button
              onClick={loadMedications}
              className="mt-2 text-red-600 hover:text-red-800 text-sm underline"
            >
              Thử lại
            </button>
          </div>
        )}

        {/* Medications List */}
        <div className="space-y-4">
          {medications.length > 0 ? (
            medications.map((medication) => (
              <div key={medication.id} className="card">
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-2">
                      <h3 className="text-lg font-semibold text-elderly-text">
                        {medication.name}
                      </h3>
                      <span
                        className={`px-3 py-1 rounded-full text-sm ${getStatusColor(
                          medication
                        )}`}
                      >
                        {getStatusText(medication)}
                      </span>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <p className="text-elderly-text-light">
                          <strong>Liều dùng:</strong> {medication.dosage}
                        </p>
                        <p className="text-elderly-text-light">
                          <strong>Tần suất:</strong> {medication.frequency}
                        </p>
                      </div>
                      <div>
                        <p className="text-elderly-text-light">
                          <strong>Bắt đầu:</strong>{" "}
                          {medication.start_date
                            ? new Date(medication.start_date).toLocaleDateString(
                                "vi-VN"
                              )
                            : "-"}
                        </p>
                        {medication.end_date && (
                          <p className="text-elderly-text-light">
                            <strong>Kết thúc:</strong>{" "}
                            {new Date(medication.end_date).toLocaleDateString(
                              "vi-VN"
                            )}
                          </p>
                        )}
                      </div>
                    </div>

                    {medication.instructions && (
                      <div className="mt-3 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                        <p className="text-blue-800 text-sm">
                          <ClockIcon className="h-4 w-4 inline mr-1" />
                          <strong>Hướng dẫn:</strong> {medication.instructions}
                        </p>
                      </div>
                    )}
                  </div>

                  <div className="flex space-x-2 ml-4">
                    <button
                      onClick={() => handleEdit(medication)}
                      className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg"
                      title="Chỉnh sửa"
                    >
                      <PencilIcon className="h-5 w-5" />
                    </button>
                    <button
                      onClick={() => handleDelete(medication.id)}
                      className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
                      title="Xóa"
                    >
                      <TrashIcon className="h-5 w-5" />
                    </button>
                  </div>
                </div>
              </div>
            ))
          ) : (
            <div className="text-center py-12">
              <div className="text-6xl mb-4">💊</div>
              <h3 className="text-xl font-semibold text-elderly-text mb-2">
                {showInactive ? "Không có thuốc đã ngừng" : "Chưa có thuốc nào"}
              </h3>
              <p className="text-elderly-text-light mb-6">
                {showInactive
                  ? "Bạn chưa có thuốc nào đã ngừng sử dụng"
                  : "Hãy thêm thuốc đầu tiên để bắt đầu theo dõi"}
              </p>
              {!showInactive && (
                <button onClick={handleAdd} className="btn btn-primary">
                  Thêm thuốc đầu tiên
                </button>
              )}
            </div>
          )}
        </div>

        {/* Quick Stats */}
        {medications.length > 0 && (
          <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="card text-center">
              <div className="text-3xl font-bold text-green-600">
                {medications.filter((m) => m.is_active).length}
              </div>
              <p className="text-elderly-text-light">Thuốc đang dùng</p>
            </div>
            <div className="card text-center">
              <div className="text-3xl font-bold text-yellow-600">
                {
                  medications.filter((m) => {
                    if (!m.end_date || !m.is_active) return false;
                    const daysLeft = Math.ceil(
                      (new Date(m.end_date).getTime() - new Date().getTime()) /
                        (1000 * 60 * 60 * 24)
                    );
                    return daysLeft <= 7 && daysLeft > 0;
                  }).length
                }
              </div>
              <p className="text-elderly-text-light">Sắp hết hạn</p>
            </div>
            <div className="card text-center">
              <div className="text-3xl font-bold text-gray-600">
                {medications.filter((m) => !m.is_active).length}
              </div>
              <p className="text-elderly-text-light">Đã ngừng</p>
            </div>
          </div>
        )}
      </div>

      {/* Add/Edit Medication Modal */}
      <AddMedicationModal
        isOpen={showAddForm}
        onClose={() => {
          setShowAddForm(false);
          setEditingMed(null);
        }}
        onSuccess={loadMedications}
        editingMedication={editingMed}
      />
    </Layout>
  );
};

export default withAuth(MedicationsPage);
