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
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `chat_messages` */

insert  into `chat_messages`(`id`,`session_id`,`message_type`,`content`,`timestamp`) values 
(5,7,'user','toi bi dau da day','2025-11-05 20:50:20'),
(6,7,'assistant','Chào bác A! Cháu là trợ lý ảo sức khỏe, rất vui được hỗ trợ bác ạ. Cháu hiểu là bác đang bị đau dạ dày. Đau dạ dày có thể gây khó chịu, nhưng bác đừng quá lo lắng. Cháu sẽ đưa ra một vài lời khuyên để bác tham khảo nhé. ⚠️ Tuy nhiên, những thông tin này chỉ mang tính chất tham khảo, bác nên đi khám bác sĩ để được chẩn đoán và điều trị chính xác nhất ạ. ?\n\n**1. Chăm sóc tại nhà khi bị đau dạ dày:**\n\n*   **Ăn uống điều độ:**\n    *   Chia nhỏ các bữa ăn trong ngày (5-6 bữa nhỏ) thay vì 3 bữa chính.\n    *   Ăn chậm, nhai kỹ.\n    *   Tránh ăn quá no hoặc để bụng quá đói.\n*   **Chọn thực phẩm phù hợp:**\n    *   Ưu tiên các món mềm, dễ tiêu hóa như cháo, súp.\n    *   Hạn chế đồ ăn cay nóng, nhiều dầu mỡ, đồ chua (chanh, dấm), cà phê, rượu bia, và các loại nước ngọt có gas. ?\n    *   Bác có thể thử ăn một chút bánh mì hoặc cơm nguội vì chúng có thể giúp trung hòa axit trong dạ dày.\n*   **Uống đủ nước:** Uống đủ 2-2.5 lít nước mỗi ngày, tốt nhất là nước ấm.\n*   **Nghỉ ngơi đầy đủ:** Ngủ đủ giấc (7-8 tiếng mỗi đêm) và tránh căng thẳng.\n*   **Tránh hút thuốc lá:** Thuốc lá có thể làm tăng axit trong dạ dày và làm chậm quá trình lành vết thương.\n*   **Chườm ấm bụng:** Bác có thể dùng túi chườm ấm hoặc khăn ấm để chườm lên vùng bụng bị đau.\n\n**2. Theo dõi các triệu chứng:**\n\n*   Bác nên theo dõi xem cơn đau có liên quan đến loại thức ăn nào không.\n*   Ghi lại tần suất, mức độ và thời gian đau để cung cấp thông tin cho bác sĩ khi đi khám.\n\n**3. Khi nào cần đến gặp bác sĩ?**\n\nBác nên đến gặp bác sĩ ngay nếu có các triệu chứng sau:\n\n*   Đau bụng dữ dội, đột ngột.\n*   Nôn ra máu hoặc đi ngoài phân đen.\n*   Sụt cân không rõ nguyên nhân.\n*   Khó nuốt.\n*   Cảm thấy mệt mỏi, chóng mặt.\n\n**4. Lời khuyên chung:**\n\n*   **Lối sống lành mạnh:** Tập thể dục nhẹ nhàng thường xuyên (đi bộ, yoga) ?‍♂️ sẽ giúp tăng cường sức khỏe tổng thể và giảm căng thẳng.\n*   **Uống thuốc theo chỉ định:** Nếu bác đã được bác sĩ kê đơn thuốc, hãy uống thuốc đúng liều lượng và thời gian quy định. ?\n*   **Khám sức khỏe định kỳ:** Việc khám sức khỏe định kỳ sẽ giúp phát hiện sớm các vấn đề sức khỏe và có biện pháp can thiệp kịp thời.\n\nCháu hy vọng những thông tin này hữu ích cho bác. Chúc bác mau khỏe ạ! ?','2025-11-05 20:50:27'),
(7,7,'user','toi dau chan','2025-11-11 16:26:12'),
(8,7,'assistant','Chào bác A! Cháu là trợ lý ảo sức khỏe, rất vui được trò chuyện với bác. Bác đang bị đau chân đúng không ạ? Cháu hiểu rằng đau chân có thể gây khó chịu và ảnh hưởng đến sinh hoạt hàng ngày của bác.\n\nDưới đây là một vài lời khuyên để bác tham khảo, tuy nhiên, bác hãy nhớ rằng, nếu cơn đau kéo dài hoặc trở nên nghiêm trọng hơn, bác nên đi khám bác sĩ để được chẩn đoán và điều trị phù hợp nhé! ?\n\n**1. Xác định nguyên nhân và mức độ đau:**\n\n*   Bác hãy nhớ lại xem mình bị đau chân do đâu: có thể do va đập, vận động quá sức hay do một bệnh lý nào đó.\n*   Đánh giá mức độ đau: đau âm ỉ, đau nhói, đau liên tục hay chỉ đau khi vận động.\n\n**2. Các biện pháp giảm đau tại nhà:**\n\n*   **Nghỉ ngơi:** Hạn chế đi lại và vận động mạnh để chân được nghỉ ngơi.\n*   **Chườm đá:** Chườm đá lên vùng chân bị đau khoảng 15-20 phút mỗi lần, vài lần một ngày. Đá giúp giảm sưng và đau.\n*   **Kê cao chân:** Khi nằm, bác hãy kê cao chân lên một chút để máu lưu thông tốt hơn và giảm sưng.\n*   **Sử dụng thuốc giảm đau không kê đơn:** Bác có thể sử dụng các loại thuốc giảm đau thông thường như paracetamol (acetaminophen) hoặc ibuprofen theo hướng dẫn sử dụng. ? **⚠️Lưu ý:** Nếu bác có các bệnh nền hoặc đang dùng các loại thuốc khác, hãy hỏi ý kiến bác sĩ trước khi dùng thuốc giảm đau nhé!\n*   **Xoa bóp nhẹ nhàng:** Xoa bóp nhẹ nhàng vùng chân bị đau có thể giúp giảm căng cơ và cải thiện lưu thông máu.\n\n**3. Lối sống lành mạnh hỗ trợ giảm đau:**\n\n*   **Ăn uống đủ chất:** Bác nên ăn uống đủ chất dinh dưỡng, đặc biệt là các loại thực phẩm giàu canxi và vitamin D để giúp xương chắc khỏe. ?\n*   **Tập thể dục nhẹ nhàng:** Các bài tập nhẹ nhàng như đi bộ hoặc đạp xe có thể giúp tăng cường sức mạnh cơ bắp và cải thiện khả năng vận động. ?‍♂️\n*   **Giữ cân nặng hợp lý:** Thừa cân có thể gây áp lực lên khớp chân và làm tăng nguy cơ đau chân.\n\n**4. Khi nào cần đi khám bác sĩ:**\n\n*   Cơn đau kéo dài hơn một tuần hoặc trở nên nghiêm trọng hơn.\n*   Chân bị sưng, đỏ, nóng hoặc có dấu hiệu nhiễm trùng.\n*   Bác bị sốt.\n*   Bác không thể đi lại được.\n\n**Lời khuyên cuối cùng:**\n\n*   Đừng ngần ngại đi khám bác sĩ nếu bác cảm thấy lo lắng về tình trạng đau chân của mình.\n*   Hãy tuân thủ theo hướng dẫn của bác sĩ về việc điều trị và chăm sóc sức khỏe.\n\n? Cháu hy vọng những lời khuyên này sẽ giúp bác cảm thấy dễ chịu hơn. Chúc bác mau khỏe!','2025-11-11 16:26:25');

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
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `chat_sessions` */

insert  into `chat_sessions`(`id`,`user_id`,`session_id`,`started_at`,`ended_at`,`is_active`) values 
(7,11,'d0d73609-df4c-4c8d-a156-83a09c5217c8','2025-11-05 20:47:02',NULL,1);

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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `reminders` */

insert  into `reminders`(`id`,`user_id`,`schedule_id`,`reminder_type`,`title`,`message`,`remind_datetime`,`is_sent`,`is_read`,`created_at`) values 
(2,11,NULL,'checkup','Nhắc nhở: kham benh','Bạn có kham benh vào lúc 12:00','2025-11-06 11:30:00',0,0,'2025-11-05 20:49:07');

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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `schedules` */

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
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `skin_disease_predictions` */

insert  into `skin_disease_predictions`(`id`,`user_id`,`image_path`,`predicted_disease_id`,`confidence`,`actual_disease_id`,`user_feedback`,`is_confirmed`,`created_at`) values 
(28,11,'uploads/skin_disease/11_6f6035f8-ac4e-4153-8d2b-67e7fbe84822.jpg',92,0.9854,NULL,NULL,0,'2025-11-17 10:37:09'),
(29,11,'uploads/skin_disease/11_290a6bc8-dc3c-4777-89c1-e6569a611702.jpg',92,0.9646,NULL,NULL,0,'2025-11-17 10:37:56'),
(30,11,'uploads/skin_disease/11_7875d606-d466-4ab4-9dac-36547e94df51.jpg',92,0.9547,NULL,NULL,0,'2025-11-17 10:39:23'),
(31,11,'uploads/skin_disease/11_5c53b7f5-9694-4043-b498-5be15aae2c67.jpg',61,0.3556,NULL,NULL,0,'2025-11-17 10:40:17'),
(32,11,'uploads/skin_disease/11_d8ee777d-6efb-416f-9495-efc454e5b925.jpg',61,0.9975,NULL,NULL,0,'2025-11-17 10:41:17'),
(33,11,'uploads/skin_disease/11_c69e5578-6b68-4955-81c7-bef3c78b4917.jpg',61,0.9993,NULL,NULL,0,'2025-11-17 10:41:37'),
(34,11,'uploads/skin_disease/11_a22aa8f1-696f-43f3-91d3-2cabd064cd8c.jpg',93,0.9442,NULL,NULL,0,'2025-11-17 10:42:25'),
(35,11,'uploads/skin_disease/11_e28bb748-4786-4999-ad33-949200499c01.jpg',61,0.9745,NULL,NULL,0,'2025-11-17 10:43:18'),
(36,11,'uploads/skin_disease/11_34dfd6b3-2e47-46f2-ba03-347233394d55.jpg',94,0.9892,NULL,NULL,0,'2025-11-17 10:44:05'),
(37,11,'uploads/skin_disease/11_7cc247e5-1022-4d07-9f85-87236191541e.jpg',97,0.9990,NULL,NULL,0,'2025-11-17 10:45:02'),
(38,11,'uploads/skin_disease/11_f07fcdcb-6fc2-4283-bbae-365790fda525.jpg',97,0.9990,NULL,NULL,0,'2025-11-17 10:48:50'),
(39,11,'uploads/skin_disease/11_d4e8e9d1-9d12-49a7-9689-d4af97ec088a.jpg',97,1.0000,NULL,NULL,0,'2025-11-18 17:26:50'),
(40,11,'uploads/skin_disease/11_9cd4d3c0-ba40-4973-ba88-974893769d0a.jpg',97,0.7632,NULL,NULL,0,'2025-11-19 16:45:12');

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
  KEY `ix_user_settings_user_id` (`user_id`),
  KEY `ix_user_settings_id` (`id`),
  CONSTRAINT `user_settings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `user_settings` */

insert  into `user_settings`(`id`,`user_id`,`setting_key`,`setting_value`,`created_at`,`updated_at`) values 
(42,11,'display.fontSize','medium','2025-11-18 17:08:55','2025-11-19 18:54:56'),
(43,11,'display.theme','dark','2025-11-18 17:09:01','2025-11-19 18:55:04'),
(44,11,'preferred_2fa_method','totp','2025-11-19 18:29:33','2025-11-19 18:29:36'),
(45,11,'display.language','vi','2025-11-19 18:37:08','2025-11-19 18:37:24');

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
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `users` */

insert  into `users`(`id`,`email`,`password_hash`,`phone`,`full_name`,`date_of_birth`,`gender`,`address`,`emergency_contact_name`,`emergency_contact_phone`,`created_at`,`updated_at`,`is_active`,`email_verified`,`two_factor_enabled`,`two_factor_secret`,`backup_codes_hashed`,`email_otp_enabled`,`preferred_2fa_method`) values 
(11,'sieumc1990@gmail.com','$2b$12$ILbQX38AqaHa865.KEpgOONW3Uj.SsErodysQNX3k0ohCa0ue6OZ2','0338611716','TRUONG VAN A',NULL,'other',NULL,NULL,NULL,'2025-11-05 20:46:37','2025-11-05 20:46:37',1,1,0,NULL,NULL,0,'totp');

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
