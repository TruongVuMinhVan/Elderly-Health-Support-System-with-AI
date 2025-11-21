import React, { useState, useEffect } from "react";
import { withAuth } from "@/lib/auth";
import Layout from "@/components/Layout/Layout";
import { userApi, twoFactorApi, email2FaApi } from "@/lib/api";
import { useAppSettings } from "@/contexts/AppSettingsContext";
import {
  Cog6ToothIcon,
  BellIcon,
  EyeIcon,
  ShieldCheckIcon,
  LanguageIcon,
  CheckIcon,
  KeyIcon,
  QrCodeIcon,
  ExclamationTriangleIcon,
} from "@heroicons/react/24/outline";

interface UserSettings {
  [key: string]: string;
}

const SettingsPage: React.FC = () => {
  const { settings: appSettings, updateTheme, updateFontSize, updateLanguage } = useAppSettings();
  
  const [settings, setSettings] = useState({
    notifications: {
      email: true,
      push: true,
      sms: false,
    },
    display: {
      fontSize: appSettings.fontSize,
      theme: appSettings.theme,
      language: appSettings.language,
    },
    privacy: {
      shareData: false,
      analytics: true,
    },
    reminders: {
      advanceMinutes: 30,
      sound: true,
    },
  });
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saveSuccess, setSaveSuccess] = useState(false);
  
  // 2FA states
  const [twoFactorEnabled, setTwoFactorEnabled] = useState(false);
  const [emailOtpEnabled, setEmailOtpEnabled] = useState(false);
  const [preferred2FAMethod, setPreferred2FAMethod] = useState<'totp' | 'email'>('totp');
  const [twoFactorSetup, setTwoFactorSetup] = useState({
    isSettingUp: false,
    qrCodeUrl: '',
    secret: '',
    backupCodes: [] as string[],
    verificationCode: '',
    showBackupCodes: false,
    liveCode: '',
    liveCountdown: 30,
  });
  const [email2FASetup, setEmail2FASetup] = useState({
    isSettingUp: false,
    otpCode: '',
    isSendingOtp: false,
  });
  const [currentUser, setCurrentUser] = useState<any>(null);

  useEffect(() => {
    loadSettings();
    load2FAStatus();
    loadCurrentUser();
  }, []);

  const loadCurrentUser = async () => {
    try {
      const user = await userApi.getCurrentUser();
      setCurrentUser(user);
    } catch (error) {
      console.error('Error loading current user:', error);
    }
  };

  // Refresh QR and live TOTP code every 30s during setup
  useEffect(() => {
    if (!twoFactorSetup.isSettingUp || !twoFactorSetup.secret) return;

    // Minimal TOTP (HMAC-SHA1) generator using Web Crypto
    const base32ToBytes = (base32: string): ArrayBuffer => {
      const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
      const cleaned = base32.replace(/=+$/,'').replace(/\s+/g,'').toUpperCase();
      let bits = '';
      for (const c of cleaned) {
        const val = alphabet.indexOf(c);
        if (val < 0) continue;
        bits += val.toString(2).padStart(5,'0');
      }
      const bytes: number[] = [];
      for (let i=0; i+8<=bits.length; i+=8) {
        bytes.push(parseInt(bits.substring(i,i+8),2));
      }
      return new Uint8Array(bytes).buffer;
    };

    const hmacSha1 = async (key: ArrayBuffer, msg: ArrayBuffer): Promise<ArrayBuffer> => {
      const cryptoKey = await crypto.subtle.importKey(
        'raw',
        key,
        { name: 'HMAC', hash: 'SHA-1' },
        false,
        ['sign']
      );
      return crypto.subtle.sign('HMAC', cryptoKey, msg);
    };

    const generateTotp = async (secret: string, step: number = 30, digits: number = 6): Promise<string> => {
      const counter = Math.floor(Date.now() / 1000 / step);
      const counterBuf = new ArrayBuffer(8);
      const view = new DataView(counterBuf);
      // big-endian 8-byte counter
      view.setUint32(4, counter);
      const key = base32ToBytes(secret);
      const hmacBuf = await hmacSha1(key, counterBuf);
      const hmac = new Uint8Array(hmacBuf);
      const offset = hmac[hmac.length - 1] & 0x0f;
      const bin = ((hmac[offset] & 0x7f) << 24) |
                  ((hmac[offset + 1] & 0xff) << 16) |
                  ((hmac[offset + 2] & 0xff) << 8) |
                  (hmac[offset + 3] & 0xff);
      const otp = (bin % 10 ** digits).toString().padStart(digits, '0');
      return otp;
    };

    const updateLiveCode = async () => {
      try {
        const step = 30;
        const code = await generateTotp(twoFactorSetup.secret, step, 6);
        const remaining = step - (Math.floor(Date.now() / 1000) % step);
        setTwoFactorSetup((prev) => ({ ...prev, liveCode: code, liveCountdown: remaining }));
      } catch {}
    };

    // initial update
    updateLiveCode();

    const codeInterval = setInterval(() => { updateLiveCode(); }, 1000);
    const qrInterval = setInterval(async () => {
      try {
        const qrUrl = await twoFactorApi.getQrObjectUrl();
        setTwoFactorSetup((prev) => ({ ...prev, qrCodeUrl: qrUrl }));
      } catch {}
    }, 30000);

    return () => {
      clearInterval(codeInterval);
      clearInterval(qrInterval);
    };
  }, [twoFactorSetup.isSettingUp, twoFactorSetup.secret]);

  const load2FAStatus = async () => {
    try {
      const data = await twoFactorApi.getStatus();
      setTwoFactorEnabled(data.two_factor_enabled);
      setEmailOtpEnabled(data.email_otp_enabled);
      setPreferred2FAMethod(data.preferred_2fa_method as 'totp' | 'email');
    } catch (error) {
      console.error('Error loading 2FA status:', error);
    }
  };

  const start2FASetup = async () => {
    try {
      const data = await twoFactorApi.startSetup();
      const qrUrl = await twoFactorApi.getQrObjectUrl();
      setTwoFactorSetup(prev => ({
        ...prev,
        isSettingUp: true,
        secret: data.secret,
        qrCodeUrl: qrUrl,
        liveCode: '',
        liveCountdown: 30,
      }));
    } catch (error) {
      console.error('Error starting 2FA setup:', error);
      setError('Không thể bắt đầu thiết lập 2FA');
    }
  };

  const enable2FA = async () => {
    try {
      const data = await twoFactorApi.enable(twoFactorSetup.verificationCode);
      setTwoFactorSetup(prev => ({
        ...prev,
        backupCodes: data.backup_codes,
        showBackupCodes: true,
      }));
      setTwoFactorEnabled(true);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 5000);
    } catch (error: any) {
      setError(error?.message || 'Mã xác thực không đúng');
    }
  };

  const disable2FA = async () => {
    try {
      await twoFactorApi.disable(twoFactorSetup.verificationCode);
      setTwoFactorEnabled(false);
        setTwoFactorSetup({
          isSettingUp: false,
          qrCodeUrl: '',
          secret: '',
          backupCodes: [],
          verificationCode: '',
          showBackupCodes: false,
          liveCode: '',
          liveCountdown: 30,
        });
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (error: any) {
      setError(error?.message || 'Mã xác thực không đúng');
    }
  };

  // Email 2FA functions
  const startEmail2FASetup = async () => {
    try {
      if (!currentUser?.email) {
        setError('Không tìm thấy email người dùng');
        return;
      }
      setEmail2FASetup(prev => ({ ...prev, isSendingOtp: true }));
      await email2FaApi.sendOtp(currentUser.email);
      setEmail2FASetup(prev => ({ ...prev, isSettingUp: true, isSendingOtp: false }));
    } catch (error: any) {
      setEmail2FASetup(prev => ({ ...prev, isSendingOtp: false }));
      setError(error?.message || 'Không thể gửi mã OTP');
    }
  };

  const enableEmail2FA = async () => {
    try {
      if (!currentUser?.email) {
        setError('Không tìm thấy email người dùng');
        return;
      }
      await email2FaApi.enable(email2FASetup.otpCode);
      setEmailOtpEnabled(true);
      setEmail2FASetup({ isSettingUp: false, otpCode: '', isSendingOtp: false });
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (error: any) {
      setError(error?.message || 'Mã OTP không đúng');
    }
  };

  const disableEmail2FA = async () => {
    try {
      await email2FaApi.disable();
      setEmailOtpEnabled(false);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (error: any) {
      setError(error?.message || 'Không thể tắt email 2FA');
    }
  };

  const updatePreferred2FAMethod = async (method: 'totp' | 'email') => {
    try {
      await twoFactorApi.updatePreferredMethod(method);
      setPreferred2FAMethod(method);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (error: any) {
      setError(error?.message || 'Không thể cập nhật phương thức 2FA');
    }
  };

  const loadSettings = async () => {
    try {
      setIsLoading(true);
      setError(null);

      const userSettings = await userApi.getSettings();

      // Convert array of settings to nested object
      const settingsMap: UserSettings = {};
      userSettings.forEach((setting: any) => {
        settingsMap[setting.setting_key] = setting.setting_value;
      });

      // Update state with loaded settings
      setSettings({
        notifications: {
          email: settingsMap["notifications.email"] === "true",
          push: settingsMap["notifications.push"] === "true",
          sms: settingsMap["notifications.sms"] === "true",
        },
        display: {
          fontSize: (settingsMap["display.fontSize"] as 'small' | 'medium' | 'large' | 'extra-large') || appSettings.fontSize,
          theme: (settingsMap["display.theme"] as 'light' | 'dark' | 'auto') || appSettings.theme,
          language: (settingsMap["display.language"] as 'vi' | 'en') || appSettings.language,
        },
        privacy: {
          shareData: settingsMap["privacy.shareData"] === "true",
          analytics: settingsMap["privacy.analytics"] === "true",
        },
        reminders: {
          advanceMinutes:
            parseInt(settingsMap["reminders.advanceMinutes"]) || 30,
          sound: settingsMap["reminders.sound"] === "true",
        },
      });
    } catch (err: any) {
      console.error("Error loading settings:", err);
      setError("Không thể tải cài đặt");
    } finally {
      setIsLoading(false);
    }
  };

  const handleSettingChange = async (
    category: string,
    key: string,
    value: any
  ) => {
    // Update local state immediately for better UX
    setSettings((prev) => ({
      ...prev,
      [category]: {
        ...prev[category as keyof typeof prev],
        [key]: value,
      },
    }));

    // Save to backend
    try {
      const settingKey = `${category}.${key}`;
      const settingValue =
        typeof value === "boolean" ? value.toString() : value.toString();

      await userApi.updateSetting(settingKey, settingValue);
    } catch (err: any) {
      console.error("Error saving setting:", err);
      setError("Không thể lưu cài đặt");
      // Revert local state on error
      await loadSettings();
    }
  };

  const handleSaveAll = async () => {
    try {
      setIsSaving(true);
      setError(null);
      setSaveSuccess(false);

      // Flatten settings and save all
      const settingsToSave = [
        {
          key: "notifications.email",
          value: settings.notifications.email.toString(),
        },
        {
          key: "notifications.push",
          value: settings.notifications.push.toString(),
        },
        {
          key: "notifications.sms",
          value: settings.notifications.sms.toString(),
        },
        { key: "display.fontSize", value: settings.display.fontSize },
        { key: "display.theme", value: settings.display.theme },
        { key: "display.language", value: settings.display.language },
        {
          key: "privacy.shareData",
          value: settings.privacy.shareData.toString(),
        },
        {
          key: "privacy.analytics",
          value: settings.privacy.analytics.toString(),
        },
        {
          key: "reminders.advanceMinutes",
          value: settings.reminders.advanceMinutes.toString(),
        },
        { key: "reminders.sound", value: settings.reminders.sound.toString() },
      ];

      // Save all settings
      await Promise.all(
        settingsToSave.map((setting) =>
          userApi.updateSetting(setting.key, setting.value)
        )
      );

      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err: any) {
      console.error("Error saving all settings:", err);
      setError("Không thể lưu tất cả cài đặt");
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <Layout title="Cài đặt">
        <div className="p-6">
          <div className="flex items-center justify-center min-h-96">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
          </div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout title="Cài đặt">
      <div className="p-6">
        <h1 className="text-3xl font-bold text-elderly-text dark:text-dark-text mb-6">
          Cài đặt hệ thống
        </h1>

        {error && (
          <div className="mb-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
            <p className="text-red-800 dark:text-red-300 text-sm">{error}</p>
            <button
              onClick={loadSettings}
              className="mt-2 text-red-600 dark:text-red-400 hover:text-red-800 dark:hover:text-red-300 text-sm underline"
            >
              Thử lại
            </button>
          </div>
        )}

        {saveSuccess && (
          <div className="mb-6 p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
            <div className="flex items-center">
              <CheckIcon className="h-5 w-5 text-green-600 dark:text-green-400 mr-2" />
              <p className="text-green-800 dark:text-green-300 text-sm">
                Đã lưu cài đặt thành công!
              </p>
            </div>
          </div>
        )}

        <div className="space-y-6">
          {/* Notification Settings */}
          <div className="card">
            <h2 className="text-xl font-semibold mb-4 flex items-center text-elderly-text dark:text-dark-text">
              <BellIcon className="h-5 w-5 mr-2 text-primary-600 dark:text-primary-400" />
              Thông báo
            </h2>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-medium text-elderly-text dark:text-dark-text">
                    Thông báo email
                  </h3>
                  <p className="text-elderly-text-light dark:text-dark-text-light text-sm">
                    Nhận thông báo qua email
                  </p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={settings.notifications.email}
                    onChange={(e) =>
                      handleSettingChange(
                        "notifications",
                        "email",
                        e.target.checked
                      )
                    }
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 dark:bg-gray-700 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 dark:peer-focus:ring-primary-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 dark:after:border-gray-600 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600 dark:peer-checked:bg-primary-500"></div>
                </label>
              </div>

              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-medium text-elderly-text dark:text-dark-text">
                    Thông báo push
                  </h3>
                  <p className="text-elderly-text-light dark:text-dark-text-light text-sm">
                    Nhận thông báo trên trình duyệt
                  </p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={settings.notifications.push}
                    onChange={(e) =>
                      handleSettingChange(
                        "notifications",
                        "push",
                        e.target.checked
                      )
                    }
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 dark:bg-gray-700 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 dark:peer-focus:ring-primary-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 dark:after:border-gray-600 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600 dark:peer-checked:bg-primary-500"></div>
                </label>
              </div>

              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-medium text-elderly-text dark:text-dark-text">
                    Thông báo SMS
                  </h3>
                  <p className="text-elderly-text-light dark:text-dark-text-light text-sm">
                    Nhận thông báo qua tin nhắn
                  </p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={settings.notifications.sms}
                    onChange={(e) =>
                      handleSettingChange(
                        "notifications",
                        "sms",
                        e.target.checked
                      )
                    }
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 dark:bg-gray-700 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 dark:peer-focus:ring-primary-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 dark:after:border-gray-600 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600 dark:peer-checked:bg-primary-500"></div>
                </label>
              </div>
            </div>
          </div>

          {/* Display Settings */}
          <div className="card">
            <h2 className="text-xl font-semibold mb-4 flex items-center text-elderly-text dark:text-dark-text">
              <EyeIcon className="h-5 w-5 mr-2 text-primary-600 dark:text-primary-400" />
              Hiển thị
            </h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-elderly-text dark:text-dark-text mb-2">
                  Kích thước chữ
                </label>
                <select
                  value={settings.display.fontSize}
                  onChange={async (e) => {
                    const newFontSize = e.target.value as 'small' | 'medium' | 'large' | 'extra-large';
                    await handleSettingChange("display", "fontSize", newFontSize);
                    // Áp dụng ngay lập tức
                    await updateFontSize(newFontSize);
                  }}
                  className="form-select"
                >
                  <option value="small">Nhỏ</option>
                  <option value="medium">Vừa</option>
                  <option value="large">Lớn</option>
                  <option value="extra-large">Rất lớn</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text dark:text-dark-text mb-2">
                  Giao diện
                </label>
                <select
                  value={settings.display.theme}
                  onChange={async (e) => {
                    const newTheme = e.target.value as 'light' | 'dark' | 'auto';
                    await handleSettingChange("display", "theme", newTheme);
                    // Áp dụng ngay lập tức
                    await updateTheme(newTheme);
                  }}
                  className="form-select"
                >
                  <option value="light">Sáng</option>
                  <option value="dark">Tối</option>
                  <option value="auto">Tự động</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-elderly-text dark:text-dark-text mb-2">
                  Ngôn ngữ
                </label>
                <select
                  value={settings.display.language}
                  onChange={async (e) => {
                    const newLanguage = e.target.value as 'vi' | 'en';
                    await handleSettingChange("display", "language", newLanguage);
                    // Áp dụng ngay lập tức
                    await updateLanguage(newLanguage);
                  }}
                  className="form-select"
                >
                  <option value="vi">Tiếng Việt</option>
                  <option value="en">English</option>
                </select>
              </div>
            </div>
          </div>

          {/* Reminder Settings */}
          <div className="card">
            <h2 className="text-xl font-semibold mb-4 flex items-center text-elderly-text dark:text-dark-text">
              <Cog6ToothIcon className="h-5 w-5 mr-2 text-primary-600 dark:text-primary-400" />
              Nhắc nhở
            </h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-elderly-text dark:text-dark-text mb-2">
                  Thời gian nhắc trước (phút)
                </label>
                <select
                  value={settings.reminders.advanceMinutes}
                  onChange={(e) =>
                    handleSettingChange(
                      "reminders",
                      "advanceMinutes",
                      parseInt(e.target.value)
                    )
                  }
                  className="form-select"
                >
                  <option value={15}>15 phút</option>
                  <option value={30}>30 phút</option>
                  <option value={60}>1 giờ</option>
                  <option value={120}>2 giờ</option>
                </select>
              </div>

              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-medium text-elderly-text dark:text-dark-text">
                    Âm thanh nhắc nhở
                  </h3>
                  <p className="text-elderly-text-light dark:text-dark-text-light text-sm">
                    Phát âm thanh khi có nhắc nhở
                  </p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={settings.reminders.sound}
                    onChange={(e) =>
                      handleSettingChange(
                        "reminders",
                        "sound",
                        e.target.checked
                      )
                    }
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 dark:bg-gray-700 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 dark:peer-focus:ring-primary-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 dark:after:border-gray-600 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600 dark:peer-checked:bg-primary-500"></div>
                </label>
              </div>
            </div>
          </div>

          {/* Privacy Settings */}
          <div className="card">
            <h2 className="text-xl font-semibold mb-4 flex items-center text-elderly-text dark:text-dark-text">
              <ShieldCheckIcon className="h-5 w-5 mr-2 text-primary-600 dark:text-primary-400" />
              Quyền riêng tư
            </h2>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-medium text-elderly-text dark:text-dark-text">
                    Chia sẻ dữ liệu
                  </h3>
                  <p className="text-elderly-text-light dark:text-dark-text-light text-sm">
                    Cho phép chia sẻ dữ liệu để cải thiện dịch vụ
                  </p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={settings.privacy.shareData}
                    onChange={(e) =>
                      handleSettingChange(
                        "privacy",
                        "shareData",
                        e.target.checked
                      )
                    }
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 dark:bg-gray-700 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 dark:peer-focus:ring-primary-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 dark:after:border-gray-600 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600 dark:peer-checked:bg-primary-500"></div>
                </label>
              </div>

              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-medium text-elderly-text dark:text-dark-text">
                    Phân tích sử dụng
                  </h3>
                  <p className="text-elderly-text-light dark:text-dark-text-light text-sm">
                    Cho phép thu thập dữ liệu phân tích
                  </p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={settings.privacy.analytics}
                    onChange={(e) =>
                      handleSettingChange(
                        "privacy",
                        "analytics",
                        e.target.checked
                      )
                    }
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 dark:bg-gray-700 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 dark:peer-focus:ring-primary-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 dark:after:border-gray-600 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600 dark:peer-checked:bg-primary-500"></div>
                </label>
              </div>

              {/* 2FA Section */}
              <div className="border-t pt-6 mt-6">
                <div className="mb-6">
                  <h3 className="font-medium text-elderly-text dark:text-dark-text flex items-center mb-4">
                    <KeyIcon className="h-5 w-5 mr-2 text-primary-600 dark:text-primary-400" />
                    Xác thực 2 bước (2FA)
                  </h3>
                  
                  {/* Preferred 2FA Method Selection */}
                  <div className="mb-6">
                    <label className="block text-sm font-medium text-elderly-text dark:text-dark-text mb-3">
                      Phương thức xác thực ưa thích:
                    </label>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div 
                        className={`border-2 rounded-lg p-4 cursor-pointer transition-all ${
                          preferred2FAMethod === 'totp' 
                            ? 'border-primary-500 dark:border-primary-400 bg-primary-50 dark:bg-primary-900/30' 
                            : 'border-gray-200 dark:border-dark-border hover:border-gray-300 dark:hover:border-dark-hover-bg'
                        }`}
                        onClick={() => updatePreferred2FAMethod('totp')}
                      >
                        <div className="flex items-center">
                          <QrCodeIcon className="h-6 w-6 text-primary-600 dark:text-primary-400 mr-3" />
                          <div>
                            <h4 className="font-medium text-elderly-text dark:text-dark-text">Ứng dụng xác thực</h4>
                            <p className="text-sm text-elderly-text-light dark:text-dark-text-light">Sử dụng ứng dụng như Google Authenticator</p>
                          </div>
                        </div>
                      </div>
                      
                      <div 
                        className={`border-2 rounded-lg p-4 cursor-pointer transition-all ${
                          preferred2FAMethod === 'email' 
                            ? 'border-primary-500 dark:border-primary-400 bg-primary-50 dark:bg-primary-900/30' 
                            : 'border-gray-200 dark:border-dark-border hover:border-gray-300 dark:hover:border-dark-hover-bg'
                        }`}
                        onClick={() => updatePreferred2FAMethod('email')}
                      >
                        <div className="flex items-center">
                          <BellIcon className="h-6 w-6 text-primary-600 dark:text-primary-400 mr-3" />
                          <div>
                            <h4 className="font-medium text-elderly-text dark:text-dark-text">Email OTP</h4>
                            <p className="text-sm text-elderly-text-light dark:text-dark-text-light">Nhận mã xác thực qua email</p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* TOTP 2FA */}
                  <div className="mb-6">
                    <div className="flex items-center justify-between mb-4">
                      <div>
                        <h4 className="font-medium text-elderly-text dark:text-dark-text">Xác thực bằng ứng dụng (TOTP)</h4>
                        <p className="text-elderly-text-light dark:text-dark-text-light text-sm">
                          Sử dụng ứng dụng xác thực như Google Authenticator
                        </p>
                      </div>
                      <div className="flex items-center space-x-2">
                        <span className={`text-sm font-medium ${twoFactorEnabled ? 'text-green-600 dark:text-green-400' : 'text-gray-500 dark:text-gray-400'}`}>
                          {twoFactorEnabled ? 'Đã bật' : 'Chưa bật'}
                        </span>
                        <label className="relative inline-flex items-center cursor-pointer">
                          <input
                            type="checkbox"
                            checked={twoFactorEnabled}
                            onChange={(e) => {
                              if (e.target.checked) {
                                start2FASetup();
                              } else {
                                setTwoFactorSetup(prev => ({ ...prev, verificationCode: '' }));
                              }
                            }}
                            className="sr-only peer"
                          />
                          <div className="w-11 h-6 bg-gray-200 dark:bg-gray-700 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 dark:peer-focus:ring-primary-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 dark:after:border-gray-600 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600 dark:peer-checked:bg-primary-500"></div>
                        </label>
                      </div>
                    </div>
                  </div>

                  {/* Email 2FA */}
                  <div className="mb-6">
                    <div className="flex items-center justify-between mb-4">
                      <div>
                        <h4 className="font-medium text-elderly-text dark:text-dark-text">Xác thực bằng email</h4>
                        <p className="text-elderly-text-light dark:text-dark-text-light text-sm">
                          Nhận mã xác thực qua email
                        </p>
                      </div>
                      <div className="flex items-center space-x-2">
                        <span className={`text-sm font-medium ${emailOtpEnabled ? 'text-green-600 dark:text-green-400' : 'text-gray-500 dark:text-gray-400'}`}>
                          {emailOtpEnabled ? 'Đã bật' : 'Chưa bật'}
                        </span>
                        <label className="relative inline-flex items-center cursor-pointer">
                          <input
                            type="checkbox"
                            checked={emailOtpEnabled}
                            onChange={(e) => {
                              if (e.target.checked) {
                                startEmail2FASetup();
                              } else {
                                disableEmail2FA();
                              }
                            }}
                            className="sr-only peer"
                          />
                          <div className="w-11 h-6 bg-gray-200 dark:bg-gray-700 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 dark:peer-focus:ring-primary-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 dark:after:border-gray-600 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600 dark:peer-checked:bg-primary-500"></div>
                        </label>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Email 2FA Setup */}
                {email2FASetup.isSettingUp && !emailOtpEnabled && (
                  <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4 mb-4">
                    <h4 className="font-medium text-green-800 dark:text-green-300 mb-3">Thiết lập Email 2FA</h4>
                    
                    <div className="mb-4">
                      <p className="text-sm text-green-700 dark:text-green-300 mb-2">
                        Mã xác thực đã được gửi đến email của bạn. Vui lòng kiểm tra hộp thư và nhập mã 6 số:
                      </p>
                      <input
                        type="text"
                        value={email2FASetup.otpCode}
                        onChange={(e) => setEmail2FASetup(prev => ({
                          ...prev,
                          otpCode: e.target.value.replace(/\D/g, '').slice(0, 6)
                        }))}
                        className="form-input w-full text-center text-2xl tracking-widest"
                        placeholder="000000"
                        maxLength={6}
                      />
                    </div>

                    <div className="flex space-x-2">
                      <button
                        onClick={enableEmail2FA}
                        disabled={email2FASetup.otpCode.length !== 6}
                        className="btn btn-primary flex-1"
                      >
                        Bật Email 2FA
                      </button>
                      <button
                        onClick={startEmail2FASetup}
                        disabled={email2FASetup.isSendingOtp}
                        className="btn btn-secondary"
                      >
                        {email2FASetup.isSendingOtp ? 'Đang gửi...' : 'Gửi lại mã'}
                      </button>
                      <button
                        onClick={() => setEmail2FASetup({ isSettingUp: false, otpCode: '', isSendingOtp: false })}
                        className="btn btn-secondary"
                      >
                        Hủy
                      </button>
                    </div>
                  </div>
                )}

                {/* TOTP 2FA Setup */}
                {twoFactorSetup.isSettingUp && !twoFactorEnabled && (
                  <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
                    <h4 className="font-medium text-blue-800 dark:text-blue-300 mb-3">Thiết lập 2FA</h4>
                    
                    {/* QR Code */}
                    {twoFactorSetup.qrCodeUrl && (
                      <div className="text-center mb-4">
                        <p className="text-sm text-blue-700 dark:text-blue-300 mb-2">
                          Quét mã QR bằng ứng dụng xác thực:
                        </p>
                        <img 
                          src={twoFactorSetup.qrCodeUrl} 
                          alt="2FA QR Code" 
                          className="mx-auto border border-gray-300 dark:border-dark-border rounded-lg"
                          style={{ width: '200px', height: '200px' }}
                        />
                    <p className="text-xs text-blue-700 dark:text-blue-300 mt-2">
                      Mã QR sẽ làm mới sau {twoFactorSetup.liveCountdown % 30}s
                    </p>
                      </div>
                    )}

                    {/* Manual Secret */}
                    <div className="mb-4">
                      <p className="text-sm text-blue-700 dark:text-blue-300 mb-2">
                        Hoặc nhập mã thủ công:
                      </p>
                      <div className="bg-white dark:bg-dark-card-bg p-3 rounded border border-gray-300 dark:border-dark-border font-mono text-sm break-all text-elderly-text dark:text-dark-text">
                        {twoFactorSetup.secret}
                      </div>
                    </div>

                    {/* Verification Code Input */}
                    <div className="mb-4">
                      <label className="block text-sm font-medium text-blue-800 dark:text-blue-300 mb-2">
                        Nhập mã 6 số để xác thực:
                      </label>
                      <input
                        type="text"
                        value={twoFactorSetup.verificationCode}
                        onChange={(e) => setTwoFactorSetup(prev => ({
                          ...prev,
                          verificationCode: e.target.value.replace(/\D/g, '').slice(0, 6)
                        }))}
                        className="form-input w-full text-center text-2xl tracking-widest"
                        placeholder="000000"
                        maxLength={6}
                      />
                      {twoFactorSetup.secret && (
                        <div className="mt-2 text-center">
                          <p className="text-sm text-blue-700 dark:text-blue-300">
                            Mã hiện tại: <span className="font-mono text-lg">{twoFactorSetup.liveCode || '------'}</span>
                          </p>
                          <p className="text-xs text-blue-500 dark:text-blue-400">Tự động đổi sau {twoFactorSetup.liveCountdown}s</p>
                        </div>
                      )}
                    </div>

                    {/* Action Buttons */}
                    <div className="flex space-x-2">
                      <button
                        onClick={enable2FA}
                        disabled={twoFactorSetup.verificationCode.length !== 6}
                        className="btn btn-primary flex-1"
                      >
                        Bật 2FA
                      </button>
                      <button
                        onClick={() => setTwoFactorSetup(prev => ({ ...prev, isSettingUp: false }))}
                        className="btn btn-secondary"
                      >
                        Hủy
                      </button>
                    </div>
                  </div>
                )}

                {/* Backup Codes */}
                {twoFactorSetup.showBackupCodes && twoFactorSetup.backupCodes.length > 0 && (
                  <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4 mt-4">
                    <div className="flex items-start">
                      <ExclamationTriangleIcon className="h-5 w-5 text-yellow-600 dark:text-yellow-400 mt-0.5 mr-3 flex-shrink-0" />
                      <div className="flex-1">
                        <h4 className="font-medium text-yellow-800 dark:text-yellow-300 mb-2">
                          Mã dự phòng (Backup Codes)
                        </h4>
                        <p className="text-sm text-yellow-700 dark:text-yellow-300 mb-3">
                          Lưu các mã này ở nơi an toàn. Chúng có thể được sử dụng để đăng nhập khi không có ứng dụng xác thực.
                        </p>
                        <div className="bg-white dark:bg-dark-card-bg p-3 rounded border border-gray-300 dark:border-dark-border">
                          <div className="grid grid-cols-2 gap-2 font-mono text-sm">
                            {twoFactorSetup.backupCodes.map((code, index) => (
                              <div key={index} className="p-2 bg-gray-50 dark:bg-dark-hover-bg rounded text-center text-elderly-text dark:text-dark-text">
                                {code}
                              </div>
                            ))}
                          </div>
                        </div>
                        <button
                          onClick={() => setTwoFactorSetup(prev => ({ ...prev, showBackupCodes: false }))}
                          className="mt-3 btn btn-secondary"
                        >
                          Đã lưu
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {/* Disable TOTP 2FA */}
                {twoFactorEnabled && !twoFactorSetup.isSettingUp && (
                  <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mt-4">
                    <h4 className="font-medium text-red-800 dark:text-red-300 mb-3">Tắt TOTP 2FA</h4>
                    <div className="mb-4">
                      <label className="block text-sm font-medium text-red-800 dark:text-red-300 mb-2">
                        Nhập mã xác thực để tắt TOTP 2FA:
                      </label>
                      <input
                        type="text"
                        value={twoFactorSetup.verificationCode}
                        onChange={(e) => setTwoFactorSetup(prev => ({
                          ...prev,
                          verificationCode: e.target.value.replace(/\D/g, '').slice(0, 6)
                        }))}
                        className="form-input w-full text-center text-2xl tracking-widest"
                        placeholder="000000"
                        maxLength={6}
                      />
                    </div>
                    <button
                      onClick={disable2FA}
                      disabled={twoFactorSetup.verificationCode.length !== 6}
                      className="btn btn-danger"
                    >
                      Tắt TOTP 2FA
                    </button>
                  </div>
                )}

                {/* Disable Email 2FA */}
                {emailOtpEnabled && !email2FASetup.isSettingUp && (
                  <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mt-4">
                    <h4 className="font-medium text-red-800 dark:text-red-300 mb-3">Tắt Email 2FA</h4>
                    <p className="text-sm text-red-700 dark:text-red-300 mb-4">
                      Bạn có thể tắt Email 2FA bằng cách nhấn nút tắt ở dưới.
                    </p>
                    <button
                      onClick={disableEmail2FA}
                      className="btn btn-danger"
                    >
                      Tắt Email 2FA
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Save Button */}
          <div className="flex justify-end space-x-4">
            <button
              onClick={loadSettings}
              className="btn btn-secondary"
              disabled={isLoading}
            >
              Khôi phục
            </button>
            <button
              onClick={handleSaveAll}
              className="btn btn-primary flex items-center space-x-2"
              disabled={isSaving}
            >
              {isSaving ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  <span>Đang lưu...</span>
                </>
              ) : (
                <>
                  <CheckIcon className="h-5 w-5" />
                  <span>Lưu tất cả cài đặt</span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default withAuth(SettingsPage);
