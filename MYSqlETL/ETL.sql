CREATE DATABASE IF NOT EXISTS retaildb;
USE retaildb;
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    amount DECIMAL(10,2),
    currency VARCHAR(10),
    transaction_date DATETIME,
    updated_at DATETIME
);

-- This inserts 10 records per day for the last 5 days
USE retaildb;


-- Set base date to today
SET @base_date := CURDATE();

-- Insert exactly 10 rows per day for the last 5 days
INSERT INTO transactions (customer_id, amount, currency, transaction_date, updated_at)
SELECT 
    FLOOR(RAND() * 1000) + 100, 
    ROUND(RAND() * 500 + 100, 2), 
    IF(RAND() > 0.5, 'USD', 'EUR'),
    DATE_SUB(@base_date, INTERVAL days.day_offset DAY),
    DATE_SUB(@base_date, INTERVAL days.day_offset DAY)
FROM (
    SELECT 0 AS day_offset UNION ALL
    SELECT 1 UNION ALL
    SELECT 2 UNION ALL
    SELECT 3 UNION ALL
    SELECT 4
) AS days
JOIN (
    SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
) AS reps
LIMIT 50;
