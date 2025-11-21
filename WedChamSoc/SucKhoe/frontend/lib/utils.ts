/**
 * Utility functions for Elderly Health Support System
 */

import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { format, parseISO, isValid, differenceInYears, addDays, startOfDay, endOfDay } from 'date-fns';
import { vi } from 'date-fns/locale';
import { HealthRecord, HealthStatus, RecordType } from '@/types';

/**
 * Combine class names with Tailwind CSS merge
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/**
 * Format date for display
 */
export function formatDate(date: string | Date, formatStr: string = 'dd/MM/yyyy'): string {
  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    if (!isValid(dateObj)) return 'Ngày không hợp lệ';
    return format(dateObj, formatStr, { locale: vi });
  } catch (error) {
    console.error('Error formatting date:', error);
    return 'Ngày không hợp lệ';
  }
}

/**
 * Format datetime for display
 */
export function formatDateTime(date: string | Date): string {
  return formatDate(date, 'dd/MM/yyyy HH:mm');
}

/**
 * Format time for display
 */
export function formatTime(date: string | Date): string {
  return formatDate(date, 'HH:mm');
}

/**
 * Calculate age from date of birth
 */
export function calculateAge(dateOfBirth: string | Date): number {
  try {
    const birthDate = typeof dateOfBirth === 'string' ? parseISO(dateOfBirth) : dateOfBirth;
    if (!isValid(birthDate)) return 0;
    return differenceInYears(new Date(), birthDate);
  } catch (error) {
    console.error('Error calculating age:', error);
    return 0;
  }
}

/**
 * Format phone number for display
 */
export function formatPhoneNumber(phone: string): string {
  if (!phone) return '';
  
  // Remove all non-digits
  const cleaned = phone.replace(/\D/g, '');
  
  // Format Vietnamese phone numbers
  if (cleaned.length === 10 && cleaned.startsWith('0')) {
    return `${cleaned.slice(0, 4)} ${cleaned.slice(4, 7)} ${cleaned.slice(7)}`;
  }
  
  if (cleaned.length === 11 && cleaned.startsWith('84')) {
    return `+84 ${cleaned.slice(2, 5)} ${cleaned.slice(5, 8)} ${cleaned.slice(8)}`;
  }
  
  return phone;
}

/**
 * Validate email address
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validate Vietnamese phone number
 */
export function isValidPhoneNumber(phone: string): boolean {
  const phoneRegex = /^(\+84|84|0)(3[2-9]|5[6|8|9]|7[0|6-9]|8[1-6|8|9]|9[0-4|6-9])[0-9]{7}$/;
  return phoneRegex.test(phone.replace(/\s/g, ''));
}

/**
 * Get health status based on record type and value
 */
export function getHealthStatus(record: HealthRecord): HealthStatus {
  if (!record) return 'unknown';
  
  switch (record.record_type) {
    case 'blood_pressure':
      if (!record.systolic_pressure || !record.diastolic_pressure) return 'unknown';
      if (record.systolic_pressure >= 180 || record.diastolic_pressure >= 110) return 'danger';
      if (record.systolic_pressure >= 140 || record.diastolic_pressure >= 90) return 'warning';
      if (record.systolic_pressure >= 120 || record.diastolic_pressure >= 80) return 'warning';
      return 'normal';
      
    case 'heart_rate':
      if (!record.heart_rate) return 'unknown';
      if (record.heart_rate < 50 || record.heart_rate > 120) return 'danger';
      if (record.heart_rate < 60 || record.heart_rate > 100) return 'warning';
      return 'normal';
      
    case 'blood_sugar':
      if (!record.blood_sugar) return 'unknown';
      if (record.blood_sugar < 50 || record.blood_sugar > 300) return 'danger';
      if (record.blood_sugar < 70 || record.blood_sugar > 180) return 'warning';
      return 'normal';
      
    case 'temperature':
      if (!record.temperature) return 'unknown';
      if (record.temperature < 35 || record.temperature > 39) return 'danger';
      if (record.temperature < 36 || record.temperature > 37.5) return 'warning';
      return 'normal';
      
    case 'weight':
      return 'normal'; // Weight doesn't have universal normal ranges
      
    default:
      return 'unknown';
  }
}

/**
 * Get health status color
 */
export function getHealthStatusColor(status: HealthStatus): string {
  switch (status) {
    case 'normal':
      return 'text-green-600 bg-green-100';
    case 'warning':
      return 'text-yellow-600 bg-yellow-100';
    case 'danger':
      return 'text-red-600 bg-red-100';
    default:
      return 'text-gray-600 bg-gray-100';
  }
}

/**
 * Get health status message
 */
export function getHealthStatusMessage(status: HealthStatus, recordType: RecordType): string {
  const messages = {
    normal: {
      blood_pressure: 'Huyết áp bình thường',
      heart_rate: 'Nhịp tim bình thường',
      blood_sugar: 'Đường huyết bình thường',
      weight: 'Cân nặng ổn định',
      temperature: 'Nhiệt độ bình thường',
    },
    warning: {
      blood_pressure: 'Huyết áp hơi cao, cần theo dõi',
      heart_rate: 'Nhịp tim bất thường, cần chú ý',
      blood_sugar: 'Đường huyết cao, cần kiểm soát',
      weight: 'Cân nặng thay đổi',
      temperature: 'Nhiệt độ hơi cao',
    },
    danger: {
      blood_pressure: 'Huyết áp rất cao, cần khám ngay',
      heart_rate: 'Nhịp tim bất thường nghiêm trọng',
      blood_sugar: 'Đường huyết nguy hiểm',
      weight: 'Cân nặng thay đổi đáng lo',
      temperature: 'Sốt cao, cần chăm sóc y tế',
    },
    unknown: {
      blood_pressure: 'Không thể đánh giá',
      heart_rate: 'Không thể đánh giá',
      blood_sugar: 'Không thể đánh giá',
      weight: 'Không thể đánh giá',
      temperature: 'Không thể đánh giá',
    },
  };
  
  return messages[status][recordType] || 'Không xác định';
}

/**
 * Get record type display name
 */
export function getRecordTypeDisplayName(recordType: RecordType): string {
  const displayNames = {
    blood_pressure: 'Huyết áp',
    heart_rate: 'Nhịp tim',
    blood_sugar: 'Đường huyết',
    weight: 'Cân nặng',
    temperature: 'Nhiệt độ',
  };
  
  return displayNames[recordType] || recordType;
}

/**
 * Get record type unit
 */
export function getRecordTypeUnit(recordType: RecordType): string {
  const units = {
    blood_pressure: 'mmHg',
    heart_rate: 'bpm',
    blood_sugar: 'mg/dL',
    weight: 'kg',
    temperature: '°C',
  };
  
  return units[recordType] || '';
}

/**
 * Format number with locale
 */
export function formatNumber(value: number, decimals: number = 1): string {
  return new Intl.NumberFormat('vi-VN', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value);
}

/**
 * Debounce function
 */
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout;
  
  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
}

/**
 * Throttle function
 */
export function throttle<T extends (...args: any[]) => any>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle: boolean;
  
  return (...args: Parameters<T>) => {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
}

/**
 * Generate random ID
 */
export function generateId(): string {
  return Math.random().toString(36).substr(2, 9);
}

/**
 * Copy text to clipboard
 */
export async function copyToClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch (error) {
    console.error('Failed to copy to clipboard:', error);
    return false;
  }
}

/**
 * Download data as JSON file
 */
export function downloadJSON(data: any, filename: string): void {
  const blob = new Blob([JSON.stringify(data, null, 2)], {
    type: 'application/json',
  });
  
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `${filename}.json`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/**
 * Get date range for filtering
 */
export function getDateRange(period: 'today' | 'week' | 'month' | 'year'): {
  start: Date;
  end: Date;
} {
  const now = new Date();
  const today = startOfDay(now);
  
  switch (period) {
    case 'today':
      return {
        start: today,
        end: endOfDay(now),
      };
    case 'week':
      return {
        start: addDays(today, -7),
        end: endOfDay(now),
      };
    case 'month':
      return {
        start: addDays(today, -30),
        end: endOfDay(now),
      };
    case 'year':
      return {
        start: addDays(today, -365),
        end: endOfDay(now),
      };
    default:
      return {
        start: today,
        end: endOfDay(now),
      };
  }
}

/**
 * Check if user is elderly (65+)
 */
export function isElderly(age: number): boolean {
  return age >= 65;
}

/**
 * Get BMI category
 */
export function getBMICategory(bmi: number): string {
  if (bmi < 18.5) return 'Thiếu cân';
  if (bmi < 25) return 'Bình thường';
  if (bmi < 30) return 'Thừa cân';
  return 'Béo phì';
}

/**
 * Calculate BMI
 */
export function calculateBMI(weight: number, height: number): number {
  if (!weight || !height || height === 0) return 0;
  const heightInMeters = height / 100;
  return weight / (heightInMeters * heightInMeters);
}
