-- Skin Disease Prediction Database Schema
-- For Elderly Health Support System

USE elderly_health_db;

-- Bảng danh sách bệnh ngoài da
CREATE TABLE IF NOT EXISTS skin_diseases (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    name_vi VARCHAR(255), -- Tên tiếng Việt
    description TEXT,
    symptoms TEXT, -- JSON array: ["Ngứa", "Đỏ da", "Phát ban"]
    causes TEXT,
    treatment TEXT,
    prevention TEXT,
    severity ENUM('mild', 'moderate', 'severe'),
    is_common BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_name_vi (name_vi)
);

-- Bảng lịch sử dự đoán bệnh ngoài da
CREATE TABLE IF NOT EXISTS skin_disease_predictions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    image_path VARCHAR(500) NOT NULL,
    predicted_disease_id INT,
    confidence DECIMAL(5,4), -- 0.0000 to 1.0000
    actual_disease_id INT NULL, -- User confirmed disease
    user_feedback TEXT, -- User's feedback about prediction
    is_confirmed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (predicted_disease_id) REFERENCES skin_diseases(id) ON DELETE SET NULL,
    FOREIGN KEY (actual_disease_id) REFERENCES skin_diseases(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_predicted_disease_id (predicted_disease_id),
    INDEX idx_created_at (created_at)
);

