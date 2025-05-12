-- Create tables for e-commerce application
CREATE TABLE products (
                          id SERIAL PRIMARY KEY,
                          name VARCHAR(100) NOT NULL,
                          description TEXT,
                          price DECIMAL(10, 2) NOT NULL,
                          category VARCHAR(50),
                          stock_quantity INT NOT NULL,
                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
                           id SERIAL PRIMARY KEY,
                           first_name VARCHAR(50) NOT NULL,
                           last_name VARCHAR(50) NOT NULL,
                           email VARCHAR(100) UNIQUE NOT NULL,
                           address TEXT,
                           phone VARCHAR(20),
                           created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
                        id SERIAL PRIMARY KEY,
                        customer_id INT REFERENCES customers(id),
                        order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        total_amount DECIMAL(12, 2) NOT NULL,
                        status VARCHAR(20) DEFAULT 'pending',
                        shipping_address TEXT,
                        payment_method VARCHAR(50)
);

-- Insert fake products (2000 records)
INSERT INTO products (name, description, price, category, stock_quantity)
SELECT
    'Product ' || i,
    'Description for product ' || i,
    (random() * 500 + 10)::numeric(10,2),
    (ARRAY['Electronics', 'Clothing', 'Books', 'Home & Kitchen', 'Sports', 'Toys', 'Beauty'])[floor(random() * 7 + 1)],
    floor(random() * 1000)::int
FROM generate_series(1, 2000) AS i;

-- Insert fake customers (3000 records)
INSERT INTO customers (first_name, last_name, email, address, phone)
SELECT
    'FirstName' || i,
    'LastName' || i,
    'user' || i || '@example.com',
    (ARRAY['123 Main St', '456 Oak Ave', '789 Pine Rd', '321 Elm Blvd', '654 Maple Dr'])[floor(random() * 5 + 1)] ||
    ', City' || (i % 50) || ', Country',
    '+1-' || (floor(random() * 900 + 100))::int || '-' || (floor(random() * 900 + 100))::int || '-' || (floor(random() * 9000 + 1000))::int
FROM generate_series(1, 3000) AS i;

-- Insert fake orders (5000 records)
INSERT INTO orders (customer_id, order_date, total_amount, status, shipping_address, payment_method)
SELECT
    floor(random() * 3000 + 1)::int,
            CURRENT_TIMESTAMP - (random() * 365 * '1 day'::interval),
    (random() * 1000 + 20)::numeric(12,2),
    (ARRAY['pending', 'processing', 'shipped', 'delivered', 'cancelled'])[floor(random() * 5 + 1)],
    'Shipping Address ' || floor(random() * 3000 + 1)::int,
    (ARRAY['Credit Card', 'PayPal', 'Bank Transfer', 'Cash on Delivery'])[floor(random() * 4 + 1)]
FROM generate_series(1, 5000) AS i;