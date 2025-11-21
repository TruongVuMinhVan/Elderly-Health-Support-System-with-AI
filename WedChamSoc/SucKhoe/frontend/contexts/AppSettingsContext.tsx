import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { userApi } from '@/lib/api';

interface AppSettings {
  theme: 'light' | 'dark' | 'auto';
  fontSize: 'small' | 'medium' | 'large' | 'extra-large';
  language: 'vi' | 'en';
}

interface AppSettingsContextType {
  settings: AppSettings;
  updateTheme: (theme: AppSettings['theme']) => Promise<void>;
  updateFontSize: (fontSize: AppSettings['fontSize']) => Promise<void>;
  updateLanguage: (language: AppSettings['language']) => Promise<void>;
  isLoading: boolean;
}

const AppSettingsContext = createContext<AppSettingsContextType | undefined>(undefined);

export const useAppSettings = () => {
  const context = useContext(AppSettingsContext);
  if (!context) {
    throw new Error('useAppSettings must be used within AppSettingsProvider');
  }
  return context;
};

interface AppSettingsProviderProps {
  children: ReactNode;
}

export const AppSettingsProvider: React.FC<AppSettingsProviderProps> = ({ children }) => {
  const [settings, setSettings] = useState<AppSettings>({
    theme: 'light',
    fontSize: 'large',
    language: 'vi',
  });
  const [isLoading, setIsLoading] = useState(true);

  // Load settings from backend on mount
  useEffect(() => {
    loadSettings();
  }, []);

  // Apply theme to document
  useEffect(() => {
    applyTheme(settings.theme);
  }, [settings.theme]);

  // Apply font size to document
  useEffect(() => {
    applyFontSize(settings.fontSize);
  }, [settings.fontSize]);

  // Apply language to document
  useEffect(() => {
    applyLanguage(settings.language);
  }, [settings.language]);

  const loadSettings = async () => {
    try {
      const userSettings = await userApi.getSettings();
      const settingsMap: { [key: string]: string } = {};
      userSettings.forEach((setting: any) => {
        settingsMap[setting.setting_key] = setting.setting_value;
      });

      const newSettings: AppSettings = {
        theme: (settingsMap['display.theme'] as AppSettings['theme']) || 'light',
        fontSize: (settingsMap['display.fontSize'] as AppSettings['fontSize']) || 'large',
        language: (settingsMap['display.language'] as AppSettings['language']) || 'vi',
      };

      setSettings(newSettings);
      
      // Apply immediately
      applyTheme(newSettings.theme);
      applyFontSize(newSettings.fontSize);
      applyLanguage(newSettings.language);
    } catch (error) {
      console.error('Error loading settings:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const applyTheme = (theme: AppSettings['theme']) => {
    const root = document.documentElement;
    
    if (theme === 'dark') {
      root.classList.add('dark');
    } else if (theme === 'light') {
      root.classList.remove('dark');
    } else {
      // Auto - use system preference
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      if (prefersDark) {
        root.classList.add('dark');
      } else {
        root.classList.remove('dark');
      }
    }
  };

  const applyFontSize = (fontSize: AppSettings['fontSize']) => {
    const root = document.documentElement;
    
    // Remove all font size classes
    root.classList.remove('font-size-small', 'font-size-medium', 'font-size-large', 'font-size-extra-large');
    
    // Add new font size class
    root.classList.add(`font-size-${fontSize}`);
  };

  const applyLanguage = (language: AppSettings['language']) => {
    document.documentElement.lang = language;
  };

  const updateTheme = async (theme: AppSettings['theme']) => {
    try {
      await userApi.updateSetting('display.theme', theme);
      setSettings(prev => ({ ...prev, theme }));
      applyTheme(theme);
    } catch (error) {
      console.error('Error updating theme:', error);
      throw error;
    }
  };

  const updateFontSize = async (fontSize: AppSettings['fontSize']) => {
    try {
      await userApi.updateSetting('display.fontSize', fontSize);
      setSettings(prev => ({ ...prev, fontSize }));
      applyFontSize(fontSize);
    } catch (error) {
      console.error('Error updating font size:', error);
      throw error;
    }
  };

  const updateLanguage = async (language: AppSettings['language']) => {
    try {
      await userApi.updateSetting('display.language', language);
      setSettings(prev => ({ ...prev, language }));
      applyLanguage(language);
    } catch (error) {
      console.error('Error updating language:', error);
      throw error;
    }
  };

  return (
    <AppSettingsContext.Provider
      value={{
        settings,
        updateTheme,
        updateFontSize,
        updateLanguage,
        isLoading,
      }}
    >
      {children}
    </AppSettingsContext.Provider>
  );
};

