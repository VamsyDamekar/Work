show databases;
use test_db;
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    product_name VARCHAR(100),
    amount DECIMAL(10,2),
    status VARCHAR(20),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO orders (user_id, product_name, amount, status, order_date)
VALUES
(10, 'Headphones', 150.00, 'processing', UTC_TIMESTAMP()),
(11, 'Monitor', 220.00, 'shipped', UTC_TIMESTAMP());
Select * from orders