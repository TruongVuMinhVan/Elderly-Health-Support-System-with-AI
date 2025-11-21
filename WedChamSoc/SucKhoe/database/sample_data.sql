-- Sample data for Elderly Health Support System
USE elderly_health_db;

-- Sample users (Auth0 IDs would be real in production)
INSERT INTO users (auth0_id, email, phone, full_name, date_of_birth, gender, address, emergency_contact_name, emergency_contact_phone) VALUES
('auth0|sample1', 'nguyen.van.a@email.com', '0901234567', 'Nguyễn Văn A', '1950-05-15', 'male', '123 Đường ABC, Quận 1, TP.HCM', 'Nguyễn Thị B', '0907654321'),
('auth0|sample2', 'tran.thi.c@email.com', '0912345678', 'Trần Thị C', '1955-08-20', 'female', '456 Đường XYZ, Quận 3, TP.HCM', 'Trần Văn D', '0908765432'),
('auth0|sample3', 'le.van.e@email.com', '0923456789', 'Lê Văn E', '1948-12-10', 'male', '789 Đường DEF, Quận 5, TP.HCM', 'Lê Thị F', '0909876543');

-- Sample health profiles
INSERT INTO health_profiles (user_id, height, blood_type, chronic_diseases, allergies, current_medications, medical_notes, doctor_name, doctor_phone) VALUES
(1, 165.5, 'A+', '["Cao huyết áp", "Tiểu đường type 2"]', '["Penicillin", "Tôm cua"]', '["Metformin 500mg", "Lisinopril 10mg"]', 'Cần theo dõi đường huyết thường xuyên', 'BS. Nguyễn Văn X', '0281234567'),
(2, 158.0, 'O+', '["Loãng xương", "Viêm khớp"]', '["Aspirin"]', '["Calcium 600mg", "Glucosamine"]', 'Tập thể dục nhẹ nhàng hàng ngày', 'BS. Trần Thị Y', '0282345678'),
(3, 170.2, 'B+', '["Bệnh tim mạch"]', '[]', '["Atorvastatin 20mg", "Metoprolol 50mg"]', 'Kiểm tra tim mạch định kỳ 3 tháng/lần', 'BS. Lê Văn Z', '0283456789');

-- Sample health records (last 30 days)
INSERT INTO health_records (user_id, record_type, systolic_pressure, diastolic_pressure, recorded_at) VALUES
(1, 'blood_pressure', 140, 90, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(1, 'blood_pressure', 135, 85, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(1, 'blood_pressure', 145, 95, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(1, 'blood_pressure', 138, 88, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(1, 'blood_pressure', 142, 92, DATE_SUB(NOW(), INTERVAL 5 DAY));

INSERT INTO health_records (user_id, record_type, blood_sugar, recorded_at) VALUES
(1, 'blood_sugar', 120.5, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(1, 'blood_sugar', 115.2, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(1, 'blood_sugar', 125.8, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(1, 'blood_sugar', 118.3, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(1, 'blood_sugar', 122.1, DATE_SUB(NOW(), INTERVAL 5 DAY));

INSERT INTO health_records (user_id, record_type, heart_rate, recorded_at) VALUES
(2, 'heart_rate', 75, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(2, 'heart_rate', 78, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(2, 'heart_rate', 72, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(2, 'heart_rate', 76, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(2, 'heart_rate', 74, DATE_SUB(NOW(), INTERVAL 5 DAY));

INSERT INTO health_records (user_id, record_type, weight, recorded_at) VALUES
(3, 'weight', 68.5, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(3, 'weight', 68.3, DATE_SUB(NOW(), INTERVAL 7 DAY)),
(3, 'weight', 68.8, DATE_SUB(NOW(), INTERVAL 14 DAY)),
(3, 'weight', 68.2, DATE_SUB(NOW(), INTERVAL 21 DAY)),
(3, 'weight', 68.6, DATE_SUB(NOW(), INTERVAL 28 DAY));

-- Sample medications
INSERT INTO medications (user_id, medication_name, dosage, frequency, instructions, start_date, end_date) VALUES
(1, 'Metformin', '500mg', '2 lần/ngày', 'Uống sau ăn sáng và tối', '2024-01-01', NULL),
(1, 'Lisinopril', '10mg', '1 lần/ngày', 'Uống vào buổi sáng', '2024-01-01', NULL),
(2, 'Calcium', '600mg', '1 lần/ngày', 'Uống cùng với bữa ăn', '2024-01-15', NULL),
(2, 'Glucosamine', '1500mg', '1 lần/ngày', 'Uống sau ăn', '2024-01-15', NULL),
(3, 'Atorvastatin', '20mg', '1 lần/ngày', 'Uống vào buổi tối', '2024-01-01', NULL),
(3, 'Metoprolol', '50mg', '2 lần/ngày', 'Uống sáng và tối', '2024-01-01', NULL);

-- Sample schedules
INSERT INTO schedules (user_id, schedule_type, title, description, scheduled_datetime, medication_id, is_recurring, recurrence_pattern) VALUES
(1, 'medication', 'Uống Metformin sáng', 'Uống thuốc Metformin 500mg', DATE_ADD(NOW(), INTERVAL 8 HOUR), 1, TRUE, 'daily'),
(1, 'medication', 'Uống Metformin tối', 'Uống thuốc Metformin 500mg', DATE_ADD(NOW(), INTERVAL 20 HOUR), 1, TRUE, 'daily'),
(1, 'medication', 'Uống Lisinopril', 'Uống thuốc Lisinopril 10mg', DATE_ADD(NOW(), INTERVAL 8 HOUR), 2, TRUE, 'daily'),
(1, 'appointment', 'Khám định kỳ', 'Khám tổng quát và kiểm tra đường huyết', DATE_ADD(NOW(), INTERVAL 7 DAY), NULL, FALSE, NULL),
(2, 'medication', 'Uống Calcium', 'Uống viên Calcium 600mg', DATE_ADD(NOW(), INTERVAL 12 HOUR), 3, TRUE, 'daily'),
(2, 'appointment', 'Khám xương khớp', 'Tái khám tình trạng loãng xương', DATE_ADD(NOW(), INTERVAL 14 DAY), NULL, FALSE, NULL),
(3, 'medication', 'Uống Atorvastatin', 'Uống thuốc hạ cholesterol', DATE_ADD(NOW(), INTERVAL 21 HOUR), 5, TRUE, 'daily'),
(3, 'appointment', 'Khám tim mạch', 'Kiểm tra tình trạng tim mạch định kỳ', DATE_ADD(NOW(), INTERVAL 21 DAY), NULL, FALSE, NULL);

-- Sample reminders
INSERT INTO reminders (user_id, schedule_id, reminder_type, title, message, remind_datetime) VALUES
(1, 1, 'medication', 'Nhắc nhở uống thuốc', 'Đã đến giờ uống Metformin 500mg (buổi sáng)', DATE_ADD(NOW(), INTERVAL 7 HOUR)),
(1, 2, 'medication', 'Nhắc nhở uống thuốc', 'Đã đến giờ uống Metformin 500mg (buổi tối)', DATE_ADD(NOW(), INTERVAL 19 HOUR)),
(1, 4, 'appointment', 'Nhắc nhở khám bệnh', 'Bạn có lịch khám định kỳ vào ngày mai', DATE_ADD(NOW(), INTERVAL 6 DAY)),
(2, 5, 'medication', 'Nhắc nhở uống thuốc', 'Đã đến giờ uống Calcium 600mg', DATE_ADD(NOW(), INTERVAL 11 HOUR)),
(2, 6, 'appointment', 'Nhắc nhở khám bệnh', 'Bạn có lịch khám xương khớp trong 2 ngày nữa', DATE_ADD(NOW(), INTERVAL 12 DAY)),
(3, 7, 'medication', 'Nhắc nhở uống thuốc', 'Đã đến giờ uống Atorvastatin 20mg', DATE_ADD(NOW(), INTERVAL 20 HOUR));

-- Sample chat sessions
INSERT INTO chat_sessions (user_id, session_id, started_at) VALUES
(1, 'session_001', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(2, 'session_002', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(3, 'session_003', DATE_SUB(NOW(), INTERVAL 3 HOUR));

-- Sample chat messages
INSERT INTO chat_messages (session_id, message_type, content, timestamp) VALUES
(1, 'user', 'Chào bạn, tôi muốn hỏi về tình trạng huyết áp của mình', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(1, 'assistant', 'Xin chào! Tôi có thể giúp bạn tư vấn về huyết áp. Huyết áp hiện tại của bạn là bao nhiêu?', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(1, 'user', 'Huyết áp của tôi hôm nay là 140/90', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(1, 'assistant', 'Chỉ số 140/90 mmHg cho thấy huyết áp của bạn ở mức cao (Stage 1 Hypertension). Bạn nên: 1) Tiếp tục uống thuốc theo đúng chỉ định, 2) Giảm muối trong ăn uống, 3) Tập thể dục nhẹ nhàng, 4) Theo dõi huyết áp hàng ngày. Nếu huyết áp liên tục cao trên 140/90, hãy liên hệ bác sĩ.', DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(2, 'user', 'Tôi bị đau khớp gối, có nên tập thể dục không?', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(2, 'assistant', 'Với tình trạng đau khớp gối, bạn vẫn nên tập thể dục nhưng chọn những bài tập phù hợp: 1) Bơi lội hoặc tập trong nước, 2) Đi bộ nhẹ nhàng, 3) Tập yoga hoặc thái cực quyền, 4) Tránh chạy bộ hoặc nhảy. Hãy khởi động kỹ trước khi tập và dừng lại nếu cảm thấy đau.', DATE_SUB(NOW(), INTERVAL 1 DAY));

-- Sample user settings
INSERT INTO user_settings (user_id, setting_key, setting_value) VALUES
(1, 'notification_enabled', 'true'),
(1, 'reminder_advance_minutes', '30'),
(1, 'language', 'vi'),
(1, 'theme', 'light'),
(2, 'notification_enabled', 'true'),
(2, 'reminder_advance_minutes', '15'),
(2, 'language', 'vi'),
(2, 'theme', 'light'),
(3, 'notification_enabled', 'false'),
(3, 'reminder_advance_minutes', '60'),
(3, 'language', 'vi'),
(3, 'theme', 'dark');
