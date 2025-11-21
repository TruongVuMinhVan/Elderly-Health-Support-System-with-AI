-- Hệ thống hỗ trợ theo dõi & chăm sóc sức khỏe người cao tuổi
-- Database Schema for MySQL

-- Tạo database
CREATE DATABASE IF NOT EXISTS elderly_health_db;
USE elderly_health_db;

-- Bảng người dùng
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    auth0_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    full_name VARCHAR(255) NOT NULL,
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other') DEFAULT 'other',
    address TEXT,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Bảng hồ sơ sức khỏe
CREATE TABLE health_profiles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    height DECIMAL(5,2), -- cm
    blood_type ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'),
    chronic_diseases TEXT, -- JSON array of diseases
    allergies TEXT, -- JSON array of allergies
    current_medications TEXT, -- JSON array of medications
    medical_notes TEXT,
    doctor_name VARCHAR(255),
    doctor_phone VARCHAR(20),
    insurance_info TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Bảng ghi nhận chỉ số sức khỏe
CREATE TABLE health_records (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    record_type ENUM('blood_pressure', 'heart_rate', 'blood_sugar', 'weight', 'temperature') NOT NULL,
    systolic_pressure INT, -- for blood pressure
    diastolic_pressure INT, -- for blood pressure
    heart_rate INT, -- beats per minute
    blood_sugar DECIMAL(5,2), -- mg/dL
    weight DECIMAL(5,2), -- kg
    temperature DECIMAL(4,2), -- celsius
    notes TEXT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_type_date (user_id, record_type, recorded_at)
);

-- Bảng thông tin thuốc
CREATE TABLE medications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    medication_name VARCHAR(255) NOT NULL,
    dosage VARCHAR(100),
    frequency VARCHAR(100), -- e.g., "2 times daily", "every 8 hours"
    instructions TEXT,
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Bảng lịch hẹn (khám bệnh, uống thuốc)
CREATE TABLE schedules (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    schedule_type ENUM('medication', 'appointment', 'checkup') NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    scheduled_datetime DATETIME NOT NULL,
    location VARCHAR(255), -- for appointments
    doctor_name VARCHAR(255), -- for appointments
    medication_id INT, -- for medication schedules
    is_completed BOOLEAN DEFAULT FALSE,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern VARCHAR(100), -- e.g., "daily", "weekly", "monthly"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE SET NULL,
    INDEX idx_user_datetime (user_id, scheduled_datetime)
);

-- Bảng nhắc nhở
CREATE TABLE reminders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    schedule_id INT,
    reminder_type ENUM('medication', 'appointment', 'checkup', 'custom') NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    remind_datetime DATETIME NOT NULL,
    is_sent BOOLEAN DEFAULT FALSE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (schedule_id) REFERENCES schedules(id) ON DELETE CASCADE,
    INDEX idx_user_datetime (user_id, remind_datetime),
    INDEX idx_unsent (is_sent, remind_datetime)
);

-- Bảng phiên chat với AI
CREATE TABLE chat_sessions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_session (user_id, session_id)
);

-- Bảng tin nhắn chat
CREATE TABLE chat_messages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    session_id INT NOT NULL,
    message_type ENUM('user', 'assistant') NOT NULL,
    content TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE,
    INDEX idx_session_timestamp (session_id, timestamp)
);

-- Bảng cài đặt người dùng
CREATE TABLE user_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_setting (user_id, setting_key)
);

-- Tạo indexes để tối ưu performance
CREATE INDEX idx_users_auth0 ON users(auth0_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_health_records_user_date ON health_records(user_id, recorded_at DESC);
CREATE INDEX idx_schedules_upcoming ON schedules(user_id, scheduled_datetime) WHERE is_completed = FALSE;
CREATE INDEX idx_reminders_pending ON reminders(user_id, remind_datetime) WHERE is_sent = FALSE;

-- Tạo views để truy vấn dễ dàng hơn
CREATE VIEW user_health_summary AS
SELECT 
    u.id as user_id,
    u.full_name,
    u.email,
    hp.chronic_diseases,
    hp.allergies,
    hp.blood_type,
    COUNT(DISTINCT hr.id) as total_records,
    MAX(hr.recorded_at) as last_record_date
FROM users u
LEFT JOIN health_profiles hp ON u.id = hp.user_id
LEFT JOIN health_records hr ON u.id = hr.user_id
WHERE u.is_active = TRUE
GROUP BY u.id, u.full_name, u.email, hp.chronic_diseases, hp.allergies, hp.blood_type;

CREATE VIEW upcoming_reminders AS
SELECT 
    r.id,
    r.user_id,
    u.full_name,
    r.title,
    r.message,
    r.remind_datetime,
    r.reminder_type
FROM reminders r
JOIN users u ON r.user_id = u.id
WHERE r.is_sent = FALSE 
    AND r.remind_datetime <= DATE_ADD(NOW(), INTERVAL 24 HOUR)
    AND u.is_active = TRUE
ORDER BY r.remind_datetime ASC;
