-- ============================================
-- Hệ thống hỗ trợ theo dõi & chăm sóc sức khỏe người cao tuổi
-- Database Schema for MySQL (Tổng hợp từ backup)
-- ============================================

-- Tạo database
CREATE DATABASE IF NOT EXISTS elderly_health_db 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE elderly_health_db;

-- ============================================
-- Bảng người dùng (users)
-- ============================================

DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `full_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_of_birth` date DEFAULT NULL,
  `gender` enum('male','female','other') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci,
  `emergency_contact_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `emergency_contact_phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_active` tinyint(1) DEFAULT NULL,
  `email_verified` tinyint(1) DEFAULT NULL,
  `two_factor_enabled` tinyint(1) DEFAULT '0',
  `two_factor_secret` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `backup_codes_hashed` text COLLATE utf8mb4_unicode_ci,
  `email_otp_enabled` tinyint(1) DEFAULT '0',
  `preferred_2fa_method` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT 'totp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_users_email` (`email`),
  KEY `ix_users_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng hồ sơ sức khỏe (health_profiles)
-- ============================================

DROP TABLE IF EXISTS `health_profiles`;

CREATE TABLE `health_profiles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `height` decimal(5,2) DEFAULT NULL,
  `blood_type` enum('A_POSITIVE','A_NEGATIVE','B_POSITIVE','B_NEGATIVE','AB_POSITIVE','AB_NEGATIVE','O_POSITIVE','O_NEGATIVE') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `chronic_diseases` text COLLATE utf8mb4_unicode_ci,
  `allergies` text COLLATE utf8mb4_unicode_ci,
  `current_medications` text COLLATE utf8mb4_unicode_ci,
  `medical_notes` text COLLATE utf8mb4_unicode_ci,
  `doctor_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `doctor_phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `insurance_info` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `ix_health_profiles_id` (`id`),
  CONSTRAINT `health_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng ghi nhận chỉ số sức khỏe (health_records)
-- ============================================

DROP TABLE IF EXISTS `health_records`;

CREATE TABLE `health_records` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `record_type` enum('blood_pressure','heart_rate','blood_sugar','weight','temperature') COLLATE utf8mb4_unicode_ci NOT NULL,
  `systolic_pressure` int DEFAULT NULL,
  `diastolic_pressure` int DEFAULT NULL,
  `heart_rate` int DEFAULT NULL,
  `blood_sugar` decimal(5,2) DEFAULT NULL,
  `weight` decimal(5,2) DEFAULT NULL,
  `temperature` decimal(4,2) DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `recorded_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_health_records_id` (`id`),
  KEY `ix_health_records_record_type` (`record_type`),
  KEY `ix_health_records_user_id` (`user_id`),
  CONSTRAINT `health_records_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng thông tin thuốc (medications)
-- ============================================

DROP TABLE IF EXISTS `medications`;

CREATE TABLE `medications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `medication_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dosage` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `frequency` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `instructions` text COLLATE utf8mb4_unicode_ci,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_medications_user_id` (`user_id`),
  KEY `ix_medications_id` (`id`),
  CONSTRAINT `medications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng lịch hẹn (schedules)
-- ============================================

DROP TABLE IF EXISTS `schedules`;

CREATE TABLE `schedules` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `schedule_type` enum('medication','appointment','checkup') COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `scheduled_datetime` datetime NOT NULL,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `doctor_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `medication_id` int DEFAULT NULL,
  `is_completed` tinyint(1) DEFAULT NULL,
  `is_recurring` tinyint(1) DEFAULT NULL,
  `recurrence_pattern` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `medication_id` (`medication_id`),
  KEY `ix_schedules_id` (`id`),
  KEY `ix_schedules_scheduled_datetime` (`scheduled_datetime`),
  KEY `ix_schedules_user_id` (`user_id`),
  CONSTRAINT `schedules_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `schedules_ibfk_2` FOREIGN KEY (`medication_id`) REFERENCES `medications` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng nhắc nhở (reminders)
-- ============================================

DROP TABLE IF EXISTS `reminders`;

CREATE TABLE `reminders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `schedule_id` int DEFAULT NULL,
  `reminder_type` enum('medication','appointment','checkup','custom') COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci,
  `remind_datetime` datetime NOT NULL,
  `is_sent` tinyint(1) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `schedule_id` (`schedule_id`),
  KEY `ix_reminders_id` (`id`),
  KEY `ix_reminders_is_sent` (`is_sent`),
  KEY `ix_reminders_user_id` (`user_id`),
  KEY `ix_reminders_remind_datetime` (`remind_datetime`),
  CONSTRAINT `reminders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reminders_ibfk_2` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng phiên chat với AI (chat_sessions)
-- ============================================

DROP TABLE IF EXISTS `chat_sessions`;

CREATE TABLE `chat_sessions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `session_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `started_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `ended_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_chat_sessions_session_id` (`session_id`),
  KEY `ix_chat_sessions_user_id` (`user_id`),
  KEY `ix_chat_sessions_id` (`id`),
  CONSTRAINT `chat_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng tin nhắn chat (chat_messages)
-- ============================================

DROP TABLE IF EXISTS `chat_messages`;

CREATE TABLE `chat_messages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `session_id` int NOT NULL,
  `message_type` enum('user','assistant') COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_chat_messages_id` (`id`),
  KEY `ix_chat_messages_session_id` (`session_id`),
  KEY `ix_chat_messages_timestamp` (`timestamp`),
  CONSTRAINT `chat_messages_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `chat_sessions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng cài đặt người dùng (user_settings)
-- ============================================

DROP TABLE IF EXISTS `user_settings`;

CREATE TABLE `user_settings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `setting_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `setting_value` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_setting` (`user_id`,`setting_key`),
  KEY `ix_user_settings_user_id` (`user_id`),
  KEY `ix_user_settings_id` (`id`),
  KEY `idx_user_setting_key` (`user_id`,`setting_key`),
  CONSTRAINT `user_settings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng danh sách bệnh ngoài da (skin_diseases)
-- ============================================

DROP TABLE IF EXISTS `skin_diseases`;

CREATE TABLE `skin_diseases` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name_vi` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `symptoms` text COLLATE utf8mb4_unicode_ci,
  `causes` text COLLATE utf8mb4_unicode_ci,
  `treatment` text COLLATE utf8mb4_unicode_ci,
  `prevention` text COLLATE utf8mb4_unicode_ci,
  `severity` enum('mild','moderate','severe') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_common` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`),
  KEY `idx_name_vi` (`name_vi`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng lịch sử dự đoán bệnh ngoài da (skin_disease_predictions)
-- ============================================

DROP TABLE IF EXISTS `skin_disease_predictions`;

CREATE TABLE `skin_disease_predictions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `image_path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `predicted_disease_id` int DEFAULT NULL,
  `confidence` decimal(5,4) DEFAULT NULL,
  `actual_disease_id` int DEFAULT NULL,
  `user_feedback` text COLLATE utf8mb4_unicode_ci,
  `is_confirmed` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `actual_disease_id` (`actual_disease_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_predicted_disease_id` (`predicted_disease_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `skin_disease_predictions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `skin_disease_predictions_ibfk_2` FOREIGN KEY (`predicted_disease_id`) REFERENCES `skin_diseases` (`id`) ON DELETE SET NULL,
  CONSTRAINT `skin_disease_predictions_ibfk_3` FOREIGN KEY (`actual_disease_id`) REFERENCES `skin_diseases` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng danh sách bác sĩ (doctors)
-- ============================================

DROP TABLE IF EXISTS `doctors`;

CREATE TABLE `doctors` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `specialty` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `clinic_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `website` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `rating` decimal(3,2) DEFAULT '0.00',
  `review_count` int DEFAULT '0',
  `price_range` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `opening_hours` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- END OF SCHEMA
-- ============================================
