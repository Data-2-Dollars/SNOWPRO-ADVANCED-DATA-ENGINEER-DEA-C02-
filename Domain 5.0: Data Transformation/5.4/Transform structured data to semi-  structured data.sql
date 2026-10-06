-- Create temporary database context
CREATE OR REPLACE DATABASE demo_db;
USE DATABASE demo_db;

-- 1. Customers Table
CREATE OR REPLACE TABLE customers (
    customer_id INT,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    signup_date DATE
);

INSERT INTO customers VALUES
(101, 'Alex', 'Rivera', 'alex.r@example.com', '2024-01-15'),
(102, 'Sam', 'Taylor', 'sam.t@example.com', '2024-02-20');

INSERT INTO customers VALUES
(null, null , null,null,null);

-- 2. Customer Orders Table
CREATE OR REPLACE TABLE orders (
    order_id INT,
    customer_id INT,
    product_name VARCHAR,
    quantity INT,
    price NUMBER(10,2)
);

INSERT INTO orders VALUES
(5001, 101, 'Wireless Mouse', 2, 25.50),
(5002, 101, 'USB-C Cable', 1, 12.00),
(5003, 102, 'Mechanical Keyboard', 1, 120.00);

---ROW TO JSON OBJECT
-- OBJECT_CONSTRUCT('*'): Automatically constructs a JSON object using all table columns as keys.

-- OBJECT_CONSTRUCT_KEEP_NULL(): Preserves keys with NULL values instead of omitting them.

Select customer_id,
OBJECT_CONSTRUCT(
    'cust_id',customer_id,
    'full_name', CONCAT(first_name, ' ', last_name),
        'email', email,
        'joined', signup_date
) as customer_json
from customers;



Select customer_id,
OBJECT_CONSTRUCT_KEEP_NULL(
    'cust_id',customer_id,
    'full_name', CONCAT(first_name, ' ', last_name),
        'email', email,
        'joined', signup_date
) as customer_json
from customers;


---Nested Arrays

-- OBJECT_CONSTRUCT() with ARRAY_AGG()


SELECT 
    c.customer_id,
    OBJECT_CONSTRUCT(
        'customer_id', c.customer_id,
        'name', CONCAT(c.first_name, ' ', c.last_name),
        'email', c.email,
        'order_history',ARRAY_AGG(
                            OBJECT_CONSTRUCT(

                                    'order_id',o.order_id,
                                    'item',o.product_name,
                                    'qty',o.quantity,
                                    'unit_price',o.price,
                                    'total_amount',o.quantity*o.price
                                                    )
        )
    ) AS full_customer_profile
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email;



-- Persisting Semi-Structured Data in VARIANT Tables


CREATE OR REPLACE TABLE customer_json_documents (
    customer_id INT,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    doc VARIANT
);


INSERT INTO customer_json_documents (customer_id, doc)
SELECT 
    c.customer_id,
    OBJECT_CONSTRUCT(
        'customer_id', c.customer_id,
        'name', CONCAT(c.first_name, ' ', c.last_name),
        'orders', ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'order_id', o.order_id,
                'item', o.product_name,
                'total', o.quantity * o.price
            )
        )
    )
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;


select * from customer_json_documents;


SELECT 
    doc:customer_id::INT AS cust_id,
    doc:name::STRING AS cust_name,
    doc:orders[0]:item::STRING AS first_ordered_item
FROM customer_json_documents;




