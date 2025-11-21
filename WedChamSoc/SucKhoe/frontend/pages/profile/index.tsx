import React, { useState, useEffect } from "react";
import { withAuth, useAuth } from "@/lib/auth";
import Layout from "@/components/Layout/Layout";
import { userApi } from "@/lib/api";
import { User, UserUpdate, HealthProfile, HealthProfileCreate } from "@/types";
import {
  UserIcon,
  HeartIcon,
  PhoneIcon,
  MapPinIcon,
  CheckCircleIcon,
} from "@heroicons/react/24/outline";

const ProfilePage: React.FC = () => {
  const { user } = useAuth();

  // State for user profile
  const [userProfile, setUserProfile] = useState<User | null>(null);
  const [healthProfile, setHealthProfile] = useState<HealthProfile | null>(
    null
  );

  // Form states
  const [userFormData, setUserFormData] = useState<UserUpdate>({});
  const [healthFormData, setHealthFormData] = useState<HealthProfileCreate>({});

  // Loading and success states
  const [isLoadingUser, setIsLoadingUser] = useState(false);
  const [isLoadingHealth, setIsLoadingHealth] = useState(false);
  const [userUpdateSuccess, setUserUpdateSuccess] = useState(false);
  const [healthUpdateSuccess, setHealthUpdateSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Load user and health profile data
  useEffect(() => {
    loadUserProfile();
    loadHealthProfile();
  }, []);

  const loadUserProfile = async () => {
    try {
      const profile = await userApi.getCurrentUser();
      setUserProfile(profile);
      setUserFormData({
        full_name: profile.full_name,
        phone: profile.phone,
        date_of_birth: profile.date_of_birth,
        gender: profile.gender,
        address: profile.address,
        emergency_contact_name: profile.emergency_contact_name,
        emergency_contact_phone: profile.emergency_contact_phone,
      });
    } catch (err) {
      console.error("Error loading user profile:", err);
      setError("Không thể tải thông tin người dùng");
    }
  };

  const loadHealthProfile = async () => {
    try {
      const profile = await userApi.getHealthProfile();
      setHealthProfile(profile);
      setHealthFormData({
        height: profile.height,
        blood_type: profile.blood_type,
        chronic_diseases: profile.chronic_diseases,
        allergies: profile.allergies,
        current_medications: profile.current_medications,
        medical_notes: profile.medical_notes,
        doctor_name: profile.doctor_name,
        doctor_phone: profile.doctor_phone,
        insurance_info: profile.insurance_info,
      });
    } catch (err: any) {
      // Check if it's a 404 error (health profile doesn't exist yet)
      if (err.response?.status === 404) {
        // Health profile doesn't exist yet, that's normal for new users
        setHealthProfile(null);
        setHealthFormData({
          height: undefined,
          blood_type: "",
          chronic_diseases: [],
          allergies: [],
          current_medications: [],
          medical_notes: "",
          doctor_name: "",
          doctor_phone: "",
          insurance_info: "",
        });
      } else {
        // Other errors should be logged
        console.error("Error loading health profile:", err);
      }
    }
  };

  const handleUserUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoadingUser(true);
    setError(null);
    setUserUpdateSuccess(false);

    try {
      await userApi.updateUser(userFormData);
      setUserUpdateSuccess(true);
      await loadUserProfile(); // Reload to get updated data

      // Hide success message after 3 seconds
      setTimeout(() => setUserUpdateSuccess(false), 3000);
    } catch (err: any) {
      console.error("Error updating user profile:", err);
      setError(err.response?.data?.detail || "Không thể cập nhật thông tin");
    } finally {
      setIsLoadingUser(false);
    }
  };

  const handleHealthUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoadingHealth(true);
    setError(null);
    setHealthUpdateSuccess(false);

    try {
      if (healthProfile) {
        await userApi.updateHealthProfile(healthFormData);
      } else {
        await userApi.createHealthProfile(healthFormData);
      }
      setHealthUpdateSuccess(true);
      await loadHealthProfile(); // Reload to get updated data

      // Hide success message after 3 seconds
      setTimeout(() => setHealthUpdateSuccess(false), 3000);
    } catch (err: any) {
      console.error("Error updating health profile:", err);
      setError(
        err.response?.data?.detail || "Không thể cập nhật hồ sơ sức khỏe"
      );
    } finally {
      setIsLoadingHealth(false);
    }
  };

  return (
    <Layout title="Hồ sơ cá nhân">
      <div className="p-6">
        <h1 className="text-3xl font-bold text-elderly-text mb-6">
          Hồ sơ cá nhân
        </h1>

        {/* Error Message */}
        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-red-800 text-sm">{error}</p>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Personal Information */}
          <div className="card">
            <h2 className="text-xl font-semibold mb-4 flex items-center">
              <UserIcon className="h-5 w-5 mr-2 text-primary-600" />
              Thông tin cá nhân
              {userUpdateSuccess && (
                <CheckCircleIcon className="h-5 w-5 ml-2 text-green-600" />
              )}
            </h2>
            <form onSubmit={handleUserUpdate} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Họ và tên
                </label>
                <input
                  type="text"
                  value={userFormData.full_name || ""}
                  onChange={(e) =>
                    setUserFormData({
                      ...userFormData,
                      full_name: e.target.value,
                    })
                  }
                  className="input w-full"
                  placeholder="Nhập họ và tên"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Email
                </label>
                <input
                  type="email"
                  value={userProfile?.email || ""}
                  className="input w-full bg-gray-100"
                  disabled
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Số điện thoại
                </label>
                <input
                  type="tel"
                  value={userFormData.phone || ""}
                  onChange={(e) =>
                    setUserFormData({ ...userFormData, phone: e.target.value })
                  }
                  className="input w-full"
                  placeholder="Nhập số điện thoại"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Ngày sinh
                </label>
                <input
                  type="date"
                  value={userFormData.date_of_birth || ""}
                  onChange={(e) =>
                    setUserFormData({
                      ...userFormData,
                      date_of_birth: e.target.value,
                    })
                  }
                  className="input w-full"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Giới tính
                </label>
                <select
                  value={userFormData.gender || ""}
                  onChange={(e) =>
                    setUserFormData({
                      ...userFormData,
                      gender: e.target.value as "male" | "female" | "other",
                    })
                  }
                  className="input w-full"
                >
                  <option value="">Chọn giới tính</option>
                  <option value="male">Nam</option>
                  <option value="female">Nữ</option>
                  <option value="other">Khác</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Địa chỉ
                </label>
                <textarea
                  value={userFormData.address || ""}
                  onChange={(e) =>
                    setUserFormData({
                      ...userFormData,
                      address: e.target.value,
                    })
                  }
                  className="input w-full h-20 resize-none"
                  placeholder="Nhập địa chỉ"
                />
              </div>

              {userUpdateSuccess && (
                <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
                  <p className="text-green-800 text-sm">
                    ✅ Cập nhật thông tin thành công!
                  </p>
                </div>
              )}

              <button
                type="submit"
                disabled={isLoadingUser}
                className="btn btn-primary w-full"
              >
                {isLoadingUser ? "Đang cập nhật..." : "Cập nhật thông tin"}
              </button>
            </form>
          </div>

          {/* Health Profile */}
          <div className="card">
            <h2 className="text-xl font-semibold mb-4 flex items-center">
              <HeartIcon className="h-5 w-5 mr-2 text-primary-600" />
              Hồ sơ sức khỏe
              {healthUpdateSuccess && (
                <CheckCircleIcon className="h-5 w-5 ml-2 text-green-600" />
              )}
            </h2>
            <form onSubmit={handleHealthUpdate} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Chiều cao (cm)
                </label>
                <input
                  type="number"
                  value={healthFormData.height || ""}
                  onChange={(e) =>
                    setHealthFormData({
                      ...healthFormData,
                      height: parseFloat(e.target.value) || undefined,
                    })
                  }
                  className="input w-full"
                  placeholder="Nhập chiều cao"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Nhóm máu
                </label>
                <select
                  value={healthFormData.blood_type || ""}
                  onChange={(e) =>
                    setHealthFormData({
                      ...healthFormData,
                      blood_type: e.target.value,
                    })
                  }
                  className="input w-full"
                >
                  <option value="">Chọn nhóm máu</option>
                  <option value="A+">A+</option>
                  <option value="A-">A-</option>
                  <option value="B+">B+</option>
                  <option value="B-">B-</option>
                  <option value="AB+">AB+</option>
                  <option value="AB-">AB-</option>
                  <option value="O+">O+</option>
                  <option value="O-">O-</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Bệnh mãn tính
                </label>
                <textarea
                  value={Array.isArray(healthFormData.chronic_diseases) ? healthFormData.chronic_diseases.join(', ') : (healthFormData.chronic_diseases || "")}
                  onChange={(e) =>
                    setHealthFormData({
                      ...healthFormData,
                      chronic_diseases: e.target.value.split(',').map(item => item.trim()).filter(item => item),
                    })
                  }
                  className="input w-full h-20 resize-none"
                  placeholder="Nhập các bệnh mãn tính (nếu có)"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Dị ứng
                </label>
                <textarea
                  value={Array.isArray(healthFormData.allergies) ? healthFormData.allergies.join(', ') : (healthFormData.allergies || "")}
                  onChange={(e) =>
                    setHealthFormData({
                      ...healthFormData,
                      allergies: e.target.value.split(',').map(item => item.trim()).filter(item => item),
                    })
                  }
                  className="input w-full h-20 resize-none"
                  placeholder="Nhập các loại dị ứng (nếu có)"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Thuốc đang sử dụng
                </label>
                <textarea
                  value={Array.isArray(healthFormData.current_medications) ? healthFormData.current_medications.join(', ') : (healthFormData.current_medications || "")}
                  onChange={(e) =>
                    setHealthFormData({
                      ...healthFormData,
                      current_medications: e.target.value.split(',').map(item => item.trim()).filter(item => item),
                    })
                  }
                  className="input w-full h-20 resize-none"
                  placeholder="Nhập các thuốc đang sử dụng (nếu có)"
                />
              </div>

              {healthUpdateSuccess && (
                <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
                  <p className="text-green-800 text-sm">
                    ✅ Cập nhật hồ sơ sức khỏe thành công!
                  </p>
                </div>
              )}

              <button
                type="submit"
                disabled={isLoadingHealth}
                className="btn btn-primary w-full"
              >
                {isLoadingHealth
                  ? "Đang cập nhật..."
                  : "Cập nhật hồ sơ sức khỏe"}
              </button>
            </form>
          </div>
        </div>

        {/* Emergency Contact */}
        <div className="mt-6">
          <div className="card">
            <h2 className="text-xl font-semibold mb-4 flex items-center">
              <PhoneIcon className="h-5 w-5 mr-2 text-primary-600" />
              Liên hệ khẩn cấp
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Tên người liên hệ
                </label>
                <input
                  type="text"
                  value={userFormData.emergency_contact_name || ""}
                  onChange={(e) =>
                    setUserFormData({
                      ...userFormData,
                      emergency_contact_name: e.target.value,
                    })
                  }
                  className="input w-full"
                  placeholder="Nhập tên người liên hệ"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text mb-1">
                  Số điện thoại
                </label>
                <input
                  type="tel"
                  value={userFormData.emergency_contact_phone || ""}
                  onChange={(e) =>
                    setUserFormData({
                      ...userFormData,
                      emergency_contact_phone: e.target.value,
                    })
                  }
                  className="input w-full"
                  placeholder="Nhập số điện thoại"
                />
              </div>

              <div className="md:col-span-2">
                <p className="text-sm text-gray-600">
                  * Thông tin liên hệ khẩn cấp sẽ được cập nhật cùng với thông
                  tin cá nhân ở phần trên
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default withAuth(ProfilePage);
