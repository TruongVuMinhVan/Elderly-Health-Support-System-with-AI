/**
 * Type definitions for Elderly Health Support System
 */

// User types
export interface User {
  id: number;
  auth0_id: string;
  email: string;
  phone?: string;
  full_name: string;
  date_of_birth?: string;
  gender?: 'male' | 'female' | 'other';
  address?: string;
  emergency_contact_name?: string;
  emergency_contact_phone?: string;
  created_at: string;
  updated_at: string;
  is_active: boolean;
  age?: number;
}

export interface UserCreate {
  email: string;
  phone?: string;
  full_name: string;
  date_of_birth?: string;
  gender?: 'male' | 'female' | 'other';
  address?: string;
  emergency_contact_name?: string;
  emergency_contact_phone?: string;
}

export interface UserUpdate {
  phone?: string;
  full_name?: string;
  date_of_birth?: string;
  gender?: 'male' | 'female' | 'other';
  address?: string;
  emergency_contact_name?: string;
  emergency_contact_phone?: string;
}

// Health Profile types
export interface HealthProfile {
  id: number;
  user_id: number;
  height?: number;
  blood_type?: 'A+' | 'A-' | 'B+' | 'B-' | 'AB+' | 'AB-' | 'O+' | 'O-';
  chronic_diseases: string[];
  allergies: string[];
  current_medications: string[];
  medical_notes?: string;
  doctor_name?: string;
  doctor_phone?: string;
  insurance_info?: string;
  created_at: string;
  updated_at: string;
}

export interface HealthProfileCreate {
  height?: number;
  blood_type?: string;
  chronic_diseases?: string[];
  allergies?: string[];
  current_medications?: string[];
  medical_notes?: string;
  doctor_name?: string;
  doctor_phone?: string;
  insurance_info?: string;
}

// Health Record types
export type RecordType = 'blood_pressure' | 'heart_rate' | 'blood_sugar' | 'weight' | 'temperature';

export interface HealthRecord {
  id: number;
  user_id: number;
  record_type: RecordType;
  systolic_pressure?: number;
  diastolic_pressure?: number;
  heart_rate?: number;
  blood_sugar?: number;
  weight?: number;
  temperature?: number;
  notes?: string;
  recorded_at: string;
  created_at: string;
  display_value: string;
  is_normal: boolean;
}

export interface HealthRecordCreate {
  record_type: RecordType;
  systolic_pressure?: number;
  diastolic_pressure?: number;
  heart_rate?: number;
  blood_sugar?: number;
  weight?: number;
  temperature?: number;
  notes?: string;
  recorded_at?: string;
}

// Medication types
export interface Medication {
  id: number;
  user_id: number;
  medication_name: string;
  dosage?: string;
  frequency?: string;
  instructions?: string;
  start_date?: string;
  end_date?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  is_current: boolean;
}

export interface MedicationCreate {
  medication_name: string;
  dosage?: string;
  frequency?: string;
  instructions?: string;
  start_date?: string;
  end_date?: string;
}

// Schedule types
export type ScheduleType = 'medication' | 'appointment' | 'checkup';

export interface Schedule {
  id: number;
  user_id: number;
  schedule_type: ScheduleType;
  title: string;
  description?: string;
  scheduled_datetime: string;
  location?: string;
  doctor_name?: string;
  medication_id?: number;
  is_completed: boolean;
  is_recurring: boolean;
  recurrence_pattern?: string;
  created_at: string;
  updated_at: string;
  is_upcoming: boolean;
  is_overdue: boolean;
}

export interface ScheduleCreate {
  schedule_type: ScheduleType;
  title: string;
  description?: string;
  scheduled_datetime: string;
  location?: string;
  doctor_name?: string;
  medication_id?: number;
  is_recurring?: boolean;
  recurrence_pattern?: string;
}

// Reminder types
export type ReminderType = 'medication' | 'appointment' | 'checkup' | 'custom';

export interface Reminder {
  id: number;
  user_id: number;
  schedule_id?: number;
  reminder_type: ReminderType;
  title: string;
  message?: string;
  remind_datetime: string;
  is_sent: boolean;
  is_read: boolean;
  created_at: string;
}

// Chat types
export type MessageType = 'user' | 'assistant';

export interface ChatMessage {
  id: number;
  session_id: number;
  message_type: MessageType;
  content: string;
  timestamp: string;
}

export interface ChatSession {
  id: number;
  user_id: number;
  session_id: string;
  started_at: string;
  ended_at?: string;
  is_active: boolean;
  messages?: ChatMessage[];
}

export interface ChatResponse {
  message: ChatMessage;
  session: ChatSession;
}

// API Response types
export interface ApiResponse<T> {
  data?: T;
  error?: string;
  message?: string;
  status: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  has_next: boolean;
  has_prev: boolean;
}

// Chart data types
export interface ChartDataPoint {
  x: string | Date;
  y: number;
  label?: string;
}

export interface HealthChartData {
  labels: string[];
  datasets: {
    label: string;
    data: number[];
    borderColor: string;
    backgroundColor: string;
    fill?: boolean;
  }[];
}

// Form types
export interface FormField {
  name: string;
  label: string;
  type: 'text' | 'email' | 'password' | 'number' | 'date' | 'select' | 'textarea';
  placeholder?: string;
  required?: boolean;
  options?: { value: string; label: string }[];
  validation?: {
    min?: number;
    max?: number;
    pattern?: string;
    message?: string;
  };
}

// Navigation types
export interface NavItem {
  name: string;
  href: string;
  icon?: React.ComponentType<{ className?: string }>;
  current?: boolean;
  children?: NavItem[];
}

// Theme types
export interface Theme {
  name: string;
  colors: {
    primary: string;
    secondary: string;
    background: string;
    text: string;
    border: string;
  };
  fontSize: 'small' | 'medium' | 'large' | 'extra-large';
}

// Settings types
export interface UserSettings {
  theme: 'light' | 'dark' | 'auto';
  language: 'vi' | 'en';
  fontSize: 'small' | 'medium' | 'large' | 'extra-large';
  notifications: {
    email: boolean;
    push: boolean;
    sms: boolean;
  };
  reminders: {
    advance_minutes: number;
    sound: boolean;
  };
  privacy: {
    share_data: boolean;
    analytics: boolean;
  };
}

// Error types
export interface AppError {
  code: string;
  message: string;
  details?: any;
  timestamp: string;
}

// Loading states
export interface LoadingState {
  isLoading: boolean;
  error?: string;
  lastUpdated?: string;
}

// Health status types
export type HealthStatus = 'normal' | 'warning' | 'danger' | 'unknown';

export interface HealthStatusInfo {
  status: HealthStatus;
  message: string;
  recommendation?: string;
}

// Dashboard types
export interface DashboardStats {
  total_records: number;
  records_this_week: number;
  upcoming_appointments: number;
  pending_reminders: number;
  medications_count: number;
  last_checkup?: string;
}

// Export utility types
export type Optional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;
export type RequiredFields<T, K extends keyof T> = T & Required<Pick<T, K>>;
export type PartialExcept<T, K extends keyof T> = Partial<T> & Pick<T, K>;
