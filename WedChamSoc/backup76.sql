/*
SQLyog Community v13.3.1 (64 bit)
MySQL - 8.0.43 : Database - elderly_health_db
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`elderly_health_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `elderly_health_db`;

/*Table structure for table `chat_messages` */

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
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `chat_messages` */

insert  into `chat_messages`(`id`,`session_id`,`message_type`,`content`,`timestamp`) values 
(19,10,'user','my head hurts','2025-12-01 15:02:08'),
(20,10,'assistant','Chào bác abc ạ! Cháu là trợ lý ảo sức khỏe, rất vui được hỗ trợ bác. Cháu hiểu là bác đang bị đau đầu.\n\n? **Đau đầu có thể do nhiều nguyên nhân, nhưng cháu xin phép đưa ra một vài lời khuyên chung để bác tham khảo nhé:**\n\n1.  **Nghỉ ngơi hợp lý:**\n    *   Bác nên tìm một nơi yên tĩnh, thoáng mát để nghỉ ngơi.\n    *   Có thể chườm khăn mát lên trán hoặc gáy để giảm bớt khó chịu.\n2.  **Uống đủ nước:**\n    *   Đôi khi đau đầu là do cơ thể thiếu nước. Bác hãy uống một cốc nước ấm nhé.\n3.  **Massage nhẹ nhàng:**\n    *   Bác có thể xoa bóp nhẹ nhàng vùng thái dương, trán và gáy để giúp thư giãn.\n4.  **Tránh các yếu tố kích thích:**\n    *   Nếu bác nhạy cảm với ánh sáng, tiếng ồn, hoặc mùi hương mạnh, hãy cố gắng tránh chúng.\n5.  **Ăn uống đầy đủ:**\n    *   Đừng để bụng quá đói, vì hạ đường huyết cũng có thể gây đau đầu. Bác nên ăn nhẹ một chút gì đó nhé.\n\n⚠️ **Lưu ý quan trọng:**\n\n*   Nếu bác bị đau đầu dữ dội, đau đầu kèm theo các triệu chứng như sốt cao, cứng cổ, nhìn mờ, yếu tay chân, hoặc nói khó, thì đây có thể là dấu hiệu của một vấn đề nghiêm trọng hơn.\n*   **Trong trường hợp này, bác cần đến bệnh viện hoặc gọi 115 ngay lập tức!** ?\n\n**Lời khuyên chung về sức khỏe (dành cho mọi người):**\n\n*   ? **Chế độ ăn uống:** Bác nên ăn nhiều rau xanh, trái cây, và các loại ngũ cốc nguyên hạt. Hạn chế đồ ăn chế biến sẵn, đồ ngọt, và đồ ăn nhiều dầu mỡ.\n*   ?‍♂️ **Vận động thường xuyên:** Bác nên tập thể dục đều đặn, ít nhất 30 phút mỗi ngày. Đi bộ, tập dưỡng sinh, hoặc yoga là những lựa chọn tốt cho người cao tuổi.\n*   ? **Uống thuốc đúng giờ:** Nếu bác đang uống thuốc điều trị bệnh, hãy nhớ uống thuốc đúng giờ và theo đúng chỉ dẫn của bác sĩ.\n\nCháu xin nhắc lại là cháu không thể chẩn đoán bệnh cho bác được. **Nếu tình trạng đau đầu của bác không cải thiện hoặc trở nên nghiêm trọng hơn, bác nên đi khám bác sĩ để được chẩn đoán và điều trị kịp thời nhé.**\n\nChúc bác abc luôn khỏe mạnh và vui vẻ! ?','2025-12-01 15:02:15');

/*Table structure for table `chat_sessions` */

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
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `chat_sessions` */

insert  into `chat_sessions`(`id`,`user_id`,`session_id`,`started_at`,`ended_at`,`is_active`) values 
(10,14,'bb64c679-b76c-41d3-9e12-43a87f551eab','2025-12-01 14:56:46',NULL,1);

/*Table structure for table `doctors` */

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

/*Data for the table `doctors` */

/*Table structure for table `health_profiles` */

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
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `ix_health_profiles_id` (`id`),
  CONSTRAINT `health_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `health_profiles` */

/*Table structure for table `health_records` */

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
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `health_records` */

/*Table structure for table `medications` */

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
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_medications_user_id` (`user_id`),
  KEY `ix_medications_id` (`id`),
  CONSTRAINT `medications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `medications` */

/*Table structure for table `reminders` */

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
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `reminders` */

insert  into `reminders`(`id`,`user_id`,`schedule_id`,`reminder_type`,`title`,`message`,`remind_datetime`,`is_sent`,`is_read`,`created_at`) values 
(6,14,NULL,'appointment','Nhắc nhở: abc','Bạn có abc vào lúc 15:57','2025-12-01 15:27:27',0,0,'2025-12-01 14:58:07'),
(7,14,NULL,'appointment','Nhắc nhở: afc','Bạn có afc vào lúc 15:45','2025-12-01 15:30:00',0,0,'2025-12-01 15:27:31'),
(8,14,NULL,'appointment','Nhắc nhở: ad','Bạn có ad vào lúc 16:15','2025-12-01 16:00:00',0,0,'2025-12-01 15:57:08'),
(9,14,NULL,'appointment','Nhắc nhở: abvc','Bạn có abvc vào lúc 16:19','2025-12-01 16:04:00',0,0,'2025-12-01 16:02:34'),
(10,14,NULL,'appointment','Nhắc nhở: dd','Bạn có dd vào lúc 17:25','2025-12-01 17:10:00',0,0,'2025-12-01 16:08:38'),
(11,14,14,'appointment','Nhắc nhở: sdfsd','Bạn có sdfsd vào lúc 16:32','2025-12-01 16:17:00',0,0,'2025-12-01 16:16:56');

/*Table structure for table `schedules` */

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
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `medication_id` (`medication_id`),
  KEY `ix_schedules_id` (`id`),
  KEY `ix_schedules_scheduled_datetime` (`scheduled_datetime`),
  KEY `ix_schedules_user_id` (`user_id`),
  CONSTRAINT `schedules_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `schedules_ibfk_2` FOREIGN KEY (`medication_id`) REFERENCES `medications` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `schedules` */

insert  into `schedules`(`id`,`user_id`,`schedule_type`,`title`,`description`,`scheduled_datetime`,`location`,`doctor_name`,`medication_id`,`is_completed`,`is_recurring`,`recurrence_pattern`,`created_at`,`updated_at`) values 
(14,14,'appointment','sdfsd',NULL,'2025-12-01 16:32:00',NULL,NULL,NULL,0,0,NULL,'2025-12-01 16:16:56','2025-12-01 16:16:56');

/*Table structure for table `skin_disease_predictions` */

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
) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `skin_disease_predictions` */

insert  into `skin_disease_predictions`(`id`,`user_id`,`image_path`,`predicted_disease_id`,`confidence`,`actual_disease_id`,`user_feedback`,`is_confirmed`,`created_at`) values 
(44,14,'uploads/skin_disease/14_40ef8bf8-abdf-45af-a1a2-8652b948429c.jpg',97,0.8186,NULL,NULL,0,'2025-12-01 15:37:31'),
(45,14,'uploads/skin_disease/14_1b85f66a-f768-4259-bb31-08ff63fb9f82.jpg',97,0.8186,NULL,NULL,0,'2025-12-01 15:55:43');

/*Table structure for table `skin_diseases` */

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
) ENGINE=InnoDB AUTO_INCREMENT=99 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `skin_diseases` */

insert  into `skin_diseases`(`id`,`name`,`name_vi`,`description`,`symptoms`,`causes`,`treatment`,`prevention`,`severity`,`is_common`,`created_at`,`updated_at`) values 
(17,'keratoacanthoma','u sừng dạng nón','U da mọc nhanh hình núi lửa với trung tâm chứa sừng, được xem là biến thể độ thấp của ung thư tế bào vảy, cần cắt bỏ sớm','[\"u nhỏ rất nhanh trong 4-6 tuần\", \"hình núi lửa với hố giữa\", \"trung tâm chứa keratin\", \"màu da hoặc hồng nhạt\", \"vùng da hở\"]','[\"tia UV mạn tính\", \"tuổi cao trên 50\", \"da sáng\", \"virus HPV\", \"chấn thương da\", \"hóa chất như tar\"]','[\"cắt bỏ hoàn toàn (phương pháp tốt nhất)\", \"phẫu thuật Mohs\", \"đông lạnh\", \"tiêm 5-fluorouracil trong u\", \"không nên chờ tự khỏi vì có thể là ung thư\"]','[\"chống nắng nghiêm ngặt\", \"tránh chấn thương da\", \"khám da thường xuyên\", \"điều trị sớm nếu phát hiện\"]','severe',0,'2025-11-07 19:54:45','2025-11-16 15:53:14'),
(18,'eczema','chàm','Bệnh viêm da mãn tính gây ngứa, đỏ và khô da, thường tái phát theo chu kỳ. Còn gọi là viêm da cơ địa (atopic dermatitis), là bệnh da liễu phổ biến nhất ở trẻ em nhưng có thể kéo dài đến tuổi trưởng thành.','[\"da khô bong vảy\", \"ngứa dữ dội đặc biệt về đêm\", \"vùng da đỏ hoặc nâu xám\", \"vết sần nhỏ có thể chảy nước khi gãi\", \"da dày chai sạn do gãi lâu ngày\", \"da nứt nẻ nhạy cảm\", \"ở trẻ em thường xuất hiện ở mặt và đầu gối khuỷu tay\"]','[\"di truyền và yếu tố gia đình\", \"rối loạn hàng rào bảo vệ da\", \"hệ miễn dịch quá mẫn\", \"yếu tố môi trường (khô hanh, nóng ẩm)\", \"chất kích ứng (xà phòng, hóa chất)\", \"dị ứng thực phẩm hoặc phấn hoa\", \"stress và căng thẳng\"]','[\"kem dưỡng ẩm thường xuyên 2-3 lần/ngày\", \"corticosteroid bôi ngoài (theo đơn bác sĩ)\", \"thuốc ức chế calcineurin bôi (tacrolimus, pimecrolimus)\", \"thuốc kháng histamin giảm ngứa\", \"kháng sinh nếu nhiễm trùng thứ phát\", \"liệu pháp ánh sáng UVB\", \"thuốc sinh học (dupilumab) cho trường hợp nặng\"]','[\"dưỡng ẩm da đầy đủ mỗi ngày\", \"tắm nước ấm ngắn dưới 10 phút\", \"dùng sữa tắm không xà phòng pH trung tính\", \"tránh gãi ngứa\", \"mặc quần áo cotton thoáng mát\", \"tránh các yếu tố kích thích đã biết\", \"quản lý stress hiệu quả\", \"duy trì độ ẩm phòng 40-50%\"]','moderate',1,'2025-11-30 15:41:55','2025-11-30 15:41:55'),
(61,'melanoma','u hắc tố ác tính','Ung thư da NGUY HIỂM NHẤT từ tế bào hắc tố, di căn nhanh, tỷ lệ tử vong cao nếu phát hiện muộn, cần phát hiện và điều trị SỚM','[\"nốt ruồi thay đổi nhanh\", \"bất đối xứng (Asymmetry)\", \"ranh giới lởm chởm (Border)\", \"nhiều màu sắc (Color)\", \"đường kính >6mm (Diameter)\", \"phát triển (Evolving)\"]','[\"tia UV tích lũy và cháy nắng nặng\", \"da sáng\", \"nhiều nốt ruồi\", \"tiền sử gia đình\", \"tuổi cao\", \"suy giảm miễn dịch\"]','[\"phẫu thuật cắt rộng\", \"sinh thiết hạch bạch huyết\", \"miễn dịch trị liệu (immunotherapy)\", \"thuốc nhắm trúng đích (targeted therapy)\", \"xạ trị\", \"hóa trị nếu di căn\"]','[\"QUAN TRỌNG: khám da toàn thân 3-6 tháng/lần\", \"tự kiểm tra da hàng tháng theo ABCDE\", \"chống nắng nghiêm ngặt\", \"không tắm nắng\", \"cắt bỏ nốt ruồi nghi ngờ sớm\"]','severe',0,'2025-11-08 15:29:50','2025-11-16 15:53:14'),
(74,'dermatofibroma','u xơ da','U xơ lành tính thường gặp ở người trưởng thành và cao tuổi, cứng, màu nâu, đặc trưng lõm khi véo (dimple sign)','[\"nốt cứng màu nâu hoặc đỏ nâu\", \"lõm xuống khi véo hai bên\", \"không đau\", \"kích thước 0.5-1cm\", \"chủ yếu ở chân\"]','[\"nguyên nhân chưa rõ\", \"có thể sau vết côn trùng cắn\", \"chấn thương nhỏ\", \"di truyền\", \"phản ứng mô xơ của da\"]','[\"thường không cần điều trị\", \"cắt bỏ nếu ngứa hoặc thẩm mỹ\", \"đông lạnh giúp giảm kích thước\", \"tiêm corticoid trong u\", \"không tự biến mất\"]','[\"không có cách phòng ngừa cụ thể\", \"tránh chấn thương da\", \"theo dõi nếu thay đổi đột ngột\"]','mild',1,'2025-11-08 15:29:50','2025-11-16 15:53:14'),
(92,'healthy','da khỏe mạnh','Da bình thường, khỏe mạnh không có bệnh lý, dùng làm baseline để so sánh và phân loại hình ảnh trong chẩn đoán AI','[\"màu da đều\", \"không có tổn thương\", \"không đỏ không sưng\", \"không ngứa không đau\", \"bề mặt da mịn tự nhiên\"]','[\"da khỏe mạnh tự nhiên\", \"chăm sóc da đúng cách\", \"chế độ ăn cân bằng\", \"uống đủ nước\", \"ngủ đủ giấc\", \"không tiếp xúc yếu tố gây hại\"]','[\"duy trì chế độ chăm sóc da\", \"làm sạch nhẹ nhàng\", \"dưỡng ẩm đầy đủ\", \"chống nắng hàng ngày\", \"ăn uống lành mạnh\"]','[\"kem chống nắng SPF 30+\", \"tránh hút thuốc và rượu\", \"ăn nhiều rau củ quả\", \"uống 2 lít nước/ngày\", \"ngủ 7-8 giờ/đêm\", \"khám da định kỳ\"]','mild',1,'2025-11-13 09:51:17','2025-11-16 15:53:14'),
(93,'actinic_keratosis','dày sừng ánh sáng','Tổn thương tiền ung thư do tiếp xúc tia UV mạn tính, có 5-10% nguy cơ chuyển thành ung thư tế bào vảy, rất phổ biến ở người trên 60 tuổi','[\"mảng da sần như giấy nhám\", \"màu hồng đỏ hoặc nâu\", \"vảy khô dính chặt\", \"có thể ngứa hoặc rát\", \"xuất hiện vùng da hở\"]','[\"tiếp xúc tia UV mạn tính\", \"tuổi cao trên 60\", \"da sáng dễ cháy nắng\", \"sống vùng nắng nhiều\", \"suy giảm miễn dịch\"]','[\"đông lạnh bằng nitơ lỏng (cryotherapy)\", \"kem bôi 5-fluorouracil hoặc imiquimod\", \"liệu pháp ánh sáng (photodynamic therapy)\", \"laser\", \"cắt bỏ nếu nghi ngờ ung thư\"]','[\"dùng kem chống nắng SPF 30+ hàng ngày\", \"tránh nắng 10h-14h\", \"mặc quần áo che chắn\", \"đội mũ rộng vành\", \"khám da định kỳ\"]','severe',0,'2025-11-16 15:53:14','2025-11-16 15:53:14'),
(94,'basal_cell_carcinoma','ung thư tế bào đáy','Loại ung thư da PHỔ BIẾN NHẤT ở người cao tuổi, phát triển chậm từ tế bào đáy biểu bì, hiếm di căn nhưng cần điều trị sớm','[\"u nhỏ bóng như ngọc trai\", \"viền nổi với lõm ở giữa\", \"loét không lành\", \"chảy máu dễ khi va chạm\", \"vùng da tiếp xúc nắng nhiều\"]','[\"tia UV tích lũy suốt đời\", \"tuổi cao trên 50\", \"da sáng\", \"tiền sử bị cháy nắng\", \"suy giảm miễn dịch\", \"tiếp xúc hóa chất arsenic\"]','[\"phẫu thuật cắt bỏ (Mohs surgery)\", \"đông lạnh cho u nhỏ\", \"xạ trị cho người không phẫu thuật được\", \"kem imiquimod cho u nông\", \"thuốc nhắm trúng đích nếu di căn\"]','[\"kem chống nắng hàng ngày\", \"tránh nắng giữa trưa\", \"khám da 6-12 tháng/lần\", \"kiểm tra tự thân hàng tháng\", \"không dùng giường tắm nắng\"]','severe',1,'2025-11-16 15:53:14','2025-11-16 15:53:14'),
(95,'squamous_cell_carcinoma','ung thư tế bào vảy','Ung thư da phổ biến thứ 2, từ tế bào vảy biểu bì, có thể di căn nếu không điều trị, thường ở người cao tuổi vùng da hở','[\"u hoặc mảng đỏ sần\", \"vảy dày dai\", \"loét không lành lâu\", \"chảy máu dễ\", \"đau hoặc ngứa\", \"vùng da tiếp xúc nắng\"]','[\"tia UV mạn tính\", \"tiền sử actinic keratosis\", \"tuổi cao trên 50\", \"da sáng\", \"suy giảm miễn dịch\", \"nhiễm HPV\", \"vết sẹo mãn tính\"]','[\"phẫu thuật cắt bỏ (tiêu chuẩn vàng)\", \"phẫu thuật Mohs cho vùng mặt\", \"xạ trị\", \"đông lạnh cho u nhỏ\", \"thuốc miễn dịch nếu di căn\", \"hóa trị\"]','[\"chống nắng nghiêm ngặt SPF 50+\", \"điều trị actinic keratosis sớm\", \"khám da 6 tháng/lần\", \"tránh thuốc lá\", \"chích ngừa HPV\"]','severe',1,'2025-11-16 15:53:14','2025-11-16 15:53:14'),
(96,'lichen_planus','bệnh liken phẳng','Bệnh viêm da mãn tính tự miễn với sẩn tím phẳng ngứa, có thể ảnh hưởng da, niêm mạc, móng và tóc, hay gặp ở người 30-60 tuổi','[\"sẩn tím phẳng bóng\", \"ngứa nhiều\", \"đường Wickham (vân trắng)\", \"ở cổ tay mắt cá\", \"có thể loét miệng\", \"rụng tóc từng mảng\"]','[\"rối loạn miễn dịch tự thân\", \"virus viêm gan C\", \"phản ứng thuốc\", \"stress\", \"di truyền\", \"tiếp xúc hóa chất\"]','[\"corticosteroid bôi mạnh\", \"corticosteroid uống nếu nặng\", \"thuốc ức chế miễn dịch\", \"retinoid\", \"quang trị liệu UVB\", \"điều trị viêm gan C nếu có\"]','[\"kiểm soát stress\", \"tránh thuốc gây kích ứng\", \"vệ sinh răng miệng tốt\", \"điều trị viêm gan C\", \"theo dõi lâu dài\"]','moderate',0,'2025-11-16 15:53:14','2025-11-16 15:53:14'),
(97,'seborrheic_keratosis','u da tiết bã','U da lành tính rất phổ biến ở người cao tuổi, nổi cao có vẻ \"dán lên da\", màu nâu đen, không nguy hiểm nhưng có thể gây lo lắng','[\"nốt nổi cao màu nâu đen\", \"bề mặt sần như sáp\", \"vẻ dán lên da (stuck-on)\", \"ranh giới rõ ràng\", \"không đau ngứa\", \"xuất hiện vùng thân mặt\"]','[\"lão hóa tự nhiên\", \"di truyền\", \"ánh nắng mặt trời\", \"tuổi trên 50\", \"không phải do nấm hay nhiễm trùng\"]','[\"thường không cần điều trị\", \"đông lạnh nếu ngứa hoặc thẩm mỹ\", \"cắt bỏ bằng dao mổ\", \"laser\", \"kem vitamin D3 giảm số lượng\"]','[\"không có cách phòng ngừa\", \"chống nắng có thể làm chậm\", \"đừng nhầm với ung thư da\", \"khám nếu thay đổi nhanh\"]','mild',1,'2025-11-16 15:53:14','2025-11-16 15:53:14'),
(98,'spider_angioma','u mạch máu hình nhện','Giãn mao mạch hình sao nhện với điểm đỏ giữa và các nhánh tỏa ra, thường lành tính nhưng có thể là dấu hiệu bệnh gan','[\"điểm đỏ tươi ở giữa\", \"các nhánh mạch máu tỏa ra\", \"nhạt khi ấn giữa\", \"thường ở mặt ngực vai\", \"kích thước 2-10mm\"]','[\"tăng estrogen (mang thai, thuốc tránh thai)\", \"bệnh gan mạn tính\", \"tuổi già\", \"tiếp xúc nắng\", \"di truyền\", \"không rõ ở người khỏe mạnh\"]','[\"không cần điều trị nếu ít\", \"laser mạch máu\", \"điện đốt (electrocautery)\", \"điều trị bệnh gan nếu có\", \"tránh estrogen\"]','[\"hạn chế rượu\", \"bảo vệ gan\", \"chống nắng\", \"khám gan nếu xuất hiện nhiều đột ngột\"]','mild',0,'2025-11-16 15:53:14','2025-11-16 15:53:14');

/*Table structure for table `user_settings` */

DROP TABLE IF EXISTS `user_settings`;

CREATE TABLE `user_settings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `setting_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `setting_value` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_setting` (`user_id`,`setting_key`),
  KEY `ix_user_settings_user_id` (`user_id`),
  KEY `ix_user_settings_id` (`id`),
  KEY `idx_user_setting_key` (`user_id`,`setting_key`),
  CONSTRAINT `user_settings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `user_settings` */

insert  into `user_settings`(`id`,`user_id`,`setting_key`,`setting_value`,`created_at`,`updated_at`) values 
(50,14,'display.theme','light','2025-12-01 14:56:55','2025-12-01 15:22:42'),
(51,14,'reminders.advanceMinutes','15','2025-12-01 14:57:09','2025-12-01 14:57:09'),
(52,14,'display.fontSize','large','2025-12-01 15:05:12','2025-12-01 15:18:34'),
(53,14,'notifications.push','true','2025-12-01 15:10:28','2025-12-01 15:10:28'),
(54,14,'reminders.sound','true','2025-12-01 15:18:01','2025-12-01 15:18:02');

/*Table structure for table `users` */

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
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
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
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `users` */

insert  into `users`(`id`,`email`,`password_hash`,`phone`,`full_name`,`date_of_birth`,`gender`,`address`,`emergency_contact_name`,`emergency_contact_phone`,`created_at`,`updated_at`,`is_active`,`email_verified`,`two_factor_enabled`,`two_factor_secret`,`backup_codes_hashed`,`email_otp_enabled`,`preferred_2fa_method`) values 
(14,'sieumc1990@gmail.com','$2b$12$QJWgUgiq98n/V1ukHYiZHutt3M5fkmVfeEHbrE52S9OXXQIGrw8iS','0338611716','abc',NULL,'other',NULL,NULL,NULL,'2025-12-01 14:56:25','2025-12-01 14:56:25',1,1,0,NULL,NULL,0,'totp');

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
