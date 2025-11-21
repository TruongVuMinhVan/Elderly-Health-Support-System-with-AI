import React, { useState, useEffect } from "react";
import { withAuth } from "@/lib/auth";
import Layout from "@/components/Layout/Layout";
import { healthApi } from "@/lib/api";
import type { HealthRecord as ApiHealthRecord } from "@/types";
import { PlusIcon, ChartBarIcon, TrashIcon } from "@heroicons/react/24/outline";
import AddHealthRecordModal from "@/components/Health/AddHealthRecordModal";

// Align with shared API type
type HealthRecord = ApiHealthRecord;

interface HealthStats {
  record_type: string;
  total_records: number;
  latest_value: string | null;
  latest_date: string | null;
  average_last_7_days: number | null;
  trend: string;
}

const HealthPage: React.FC = () => {
  const [records, setRecords] = useState<HealthRecord[]>([]);
  const [stats, setStats] = useState<HealthStats[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [selectedType, setSelectedType] = useState<string>("");

  const healthTypes = [
    {
      type: "blood_pressure",
      name: "Huyết áp",
      unit: "mmHg",
      description: "Ghi nhận chỉ số huyết áp hàng ngày",
      color: "bg-red-50 border-red-200 text-red-800",
      icon: "❤️",
    },
    {
      type: "blood_sugar",
      name: "Đường huyết",
      unit: "mg/dL",
      description: "Theo dõi mức đường huyết",
      color: "bg-blue-50 border-blue-200 text-blue-800",
      icon: "🩸",
    },
    {
      type: "weight",
      name: "Cân nặng",
      unit: "kg",
      description: "Theo dõi cân nặng",
      color: "bg-green-50 border-green-200 text-green-800",
      icon: "⚖️",
    },
    {
      type: "heart_rate",
      name: "Nhịp tim",
      unit: "bpm",
      description: "Theo dõi nhịp tim",
      color: "bg-purple-50 border-purple-200 text-purple-800",
      icon: "💓",
    },
  ];

  useEffect(() => {
    loadHealthData();
  }, []);

  const loadHealthData = async () => {
    try {
      setIsLoading(true);
      setError(null);

      // Load recent records
      const recentRecords = await healthApi.getRecords({ limit: 20 });
      setRecords(recentRecords);

      // Load stats for each health type
      const statsPromises = healthTypes.map(async (type) => {
        try {
          return await healthApi.getStats(type.type);
        } catch {
          return {
            record_type: type.type,
            total_records: 0,
            latest_value: null,
            latest_date: null,
            average_last_7_days: null,
            trend: "stable",
          };
        }
      });

      const statsResults = await Promise.all(statsPromises);
      setStats(statsResults);
    } catch (err: any) {
      console.error("Error loading health data:", err);
      setError("Không thể tải dữ liệu sức khỏe");
    } finally {
      setIsLoading(false);
    }
  };

  const handleAddRecord = (type: string) => {
    setSelectedType(type);
    setShowAddForm(true);
  };

  const handleDeleteRecord = async (recordId: number) => {
    if (!confirm("Bạn có chắc chắn muốn xóa bản ghi này?")) return;

    try {
      await healthApi.deleteRecord(recordId);
      await loadHealthData();
    } catch (err: any) {
      console.error("Error deleting health record:", err);
      setError("Không thể xóa bản ghi");
    }
  };

  const getTypeConfig = (type: string) => {
    return healthTypes.find((t) => t.type === type) || healthTypes[0];
  };

  const getTypeStats = (type: string) => {
    return stats.find((s) => s.record_type === type);
  };

  if (isLoading) {
    return (
      <Layout title="Theo dõi sức khỏe">
        <div className="p-6">
          <div className="flex items-center justify-center min-h-96">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
          </div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout title="Theo dõi sức khỏe">
      <div className="p-6">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-3xl font-bold text-elderly-text">
            Theo dõi sức khỏe
          </h1>
          <button
            onClick={() => setShowAddForm(true)}
            className="btn btn-primary flex items-center space-x-2"
          >
            <PlusIcon className="h-5 w-5" />
            <span>Ghi nhận mới</span>
          </button>
        </div>

        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-red-800 text-sm">{error}</p>
            <button
              onClick={loadHealthData}
              className="mt-2 text-red-600 hover:text-red-800 text-sm underline"
            >
              Thử lại
            </button>
          </div>
        )}

        {/* Health Type Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {healthTypes.map((type) => {
            const typeStats = getTypeStats(type.type);
            return (
              <div key={type.type} className="card">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center space-x-2">
                    <span className="text-2xl">{type.icon}</span>
                    <h2 className="text-xl font-semibold">{type.name}</h2>
                  </div>
                  <ChartBarIcon className="h-5 w-5 text-gray-400" />
                </div>

                <p className="text-elderly-text-light text-sm mb-4">
                  {type.description}
                </p>

                {typeStats && typeStats.latest_value ? (
                  <div className="mb-4">
                    <p className="text-2xl font-bold text-elderly-text">
                      {typeStats.latest_value}
                    </p>
                    <p className="text-xs text-elderly-text-light">
                      {typeStats.latest_date
                        ? new Date(typeStats.latest_date).toLocaleDateString(
                            "vi-VN"
                          )
                        : "Chưa có dữ liệu"}
                    </p>
                    <p className="text-xs text-elderly-text-light">
                      Tổng: {typeStats.total_records} lần ghi nhận
                    </p>
                  </div>
                ) : (
                  <div className="mb-4">
                    <p className="text-gray-500 text-sm">Chưa có dữ liệu</p>
                  </div>
                )}

                <button
                  onClick={() => handleAddRecord(type.type)}
                  className="btn btn-primary w-full"
                >
                  Ghi nhận
                </button>
              </div>
            );
          })}
        </div>

        {/* Recent Records */}
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Ghi nhận gần đây</h2>
          {records.length > 0 ? (
            <div className="space-y-3">
              {records.slice(0, 10).map((record) => {
                const typeConfig = getTypeConfig(record.record_type);
                return (
                  <div
                    key={record.id}
                    className={`p-3 border rounded-lg ${typeConfig.color}`}
                  >
                    <div className="flex justify-between items-start">
                      <div className="flex-1">
                        <p className="font-medium">
                          {typeConfig.icon} {typeConfig.name}
                        </p>
                        <p className="text-lg font-bold">
                          {record.display_value}
                        </p>
                      </div>
                      <div className="text-right">
                        <div className="flex items-center space-x-2 mb-2">
                          <button
                            onClick={() => handleDeleteRecord(record.id)}
                            className="p-1 text-red-600 hover:bg-red-50 rounded"
                            title="Xóa"
                          >
                            <TrashIcon className="h-4 w-4" />
                          </button>
                        </div>
                        <p className="text-sm">
                          {new Date(record.recorded_at).toLocaleDateString(
                            "vi-VN"
                          )}
                        </p>
                        <p className="text-xs">
                          {new Date(record.recorded_at).toLocaleTimeString(
                            "vi-VN"
                          )}
                        </p>
                        <span
                          className={`inline-block px-2 py-1 rounded-full text-xs ${
                            record.is_normal
                              ? "bg-green-100 text-green-800"
                              : "bg-yellow-100 text-yellow-800"
                          }`}
                        >
                          {record.is_normal ? "Bình thường" : "Cần chú ý"}
                        </span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="text-center py-8">
              <p className="text-gray-500">Chưa có ghi nhận nào</p>
              <button
                onClick={() => setShowAddForm(true)}
                className="mt-4 btn btn-primary"
              >
                Thêm ghi nhận đầu tiên
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Add Health Record Modal */}
      <AddHealthRecordModal
        isOpen={showAddForm}
        onClose={() => setShowAddForm(false)}
        onSuccess={loadHealthData}
        selectedType={selectedType}
      />
    </Layout>
  );
};

export default withAuth(HealthPage);
