-- =====================================================
-- MySQL Script to update user_settings table
-- Add unique constraint and index on (user_id, setting_key)
-- =====================================================
-- 
-- Purpose:
-- - Prevent duplicate settings for the same user
-- - Improve query performance
--
-- Settings Keys Used in Application:
-- 
-- 1. Notifications (notifications.*):
--    - notifications.email (boolean: 'true'/'false', default: 'true')
--    - notifications.push (boolean: 'true'/'false', default: 'true')
--    - notifications.sms (boolean: 'true'/'false', default: 'false')
--
-- 2. Display (display.*):
--    - display.fontSize (string: 'small'/'medium'/'large'/'extra-large', default: 'large')
--    - display.theme (string: 'light'/'dark'/'auto', default: 'light')
--    - display.language (string: 'vi'/'en', default: 'vi')
--
-- 3. Reminders (reminders.*):
--    - reminders.advanceMinutes (integer: number of minutes, default: '30')
--    - reminders.sound (boolean: 'true'/'false', default: 'true')
--
-- 4. Privacy (privacy.*):
--    - privacy.shareData (boolean: 'true'/'false', default: 'false')
--    - privacy.analytics (boolean: 'true'/'false', default: 'true')
--
-- Note: 2FA settings (two_factor_enabled, email_otp_enabled, preferred_2fa_method)
--       are stored in the users table, not in user_settings.
-- =====================================================

-- Step 1: Remove any duplicate entries (keep the latest one)
-- Run this first if you have duplicate settings
DELETE t1 FROM user_settings t1
INNER JOIN user_settings t2 
WHERE t1.id < t2.id 
AND t1.user_id = t2.user_id 
AND t1.setting_key = t2.setting_key;

-- Step 2: Drop existing constraint/index if they exist (to avoid errors)
SET @constraint_exists = (
    SELECT COUNT(*) 
    FROM information_schema.TABLE_CONSTRAINTS 
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_settings'
    AND CONSTRAINT_NAME = 'uq_user_setting'
);

SET @sql = IF(@constraint_exists > 0,
    'ALTER TABLE user_settings DROP CONSTRAINT uq_user_setting',
    'SELECT "Constraint does not exist, skipping drop" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Step 3: Drop existing index if it exists
-- MySQL doesn't support DROP INDEX IF EXISTS, so we check first
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_settings'
    AND INDEX_NAME = 'idx_user_setting_key'
);

SET @sql_drop_index = IF(@index_exists > 0,
    'DROP INDEX idx_user_setting_key ON user_settings',
    'SELECT "Index does not exist, skipping drop" AS message'
);
PREPARE stmt_drop FROM @sql_drop_index;
EXECUTE stmt_drop;
DEALLOCATE PREPARE stmt_drop;

-- Step 4: Add unique constraint
ALTER TABLE user_settings 
ADD CONSTRAINT uq_user_setting 
UNIQUE (user_id, setting_key);

-- Step 5: Create index for better query performance
CREATE INDEX idx_user_setting_key 
ON user_settings(user_id, setting_key);

-- =====================================================
-- Verification queries
-- =====================================================

-- Check if constraint exists
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS 
WHERE CONSTRAINT_SCHEMA = DATABASE()
AND TABLE_NAME = 'user_settings'
AND CONSTRAINT_NAME = 'uq_user_setting';

-- Check if index exists
SHOW INDEX FROM user_settings WHERE Key_name = 'idx_user_setting_key';

-- Check for any remaining duplicates
SELECT user_id, setting_key, COUNT(*) as count
FROM user_settings
GROUP BY user_id, setting_key
HAVING COUNT(*) > 1;

-- View all settings for a specific user (replace USER_ID with actual user id)
-- SELECT setting_key, setting_value, created_at, updated_at
-- FROM user_settings
-- WHERE user_id = USER_ID
-- ORDER BY setting_key;

