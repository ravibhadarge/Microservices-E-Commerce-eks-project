CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products (name, price)
SELECT 'Laptop', 999.99
WHERE NOT EXISTS (
    SELECT 1 FROM products WHERE name = 'Laptop'
);

INSERT INTO products (name, price)
SELECT 'Keyboard', 49.99
WHERE NOT EXISTS (
    SELECT 1 FROM products WHERE name = 'Keyboard'
);

INSERT INTO products (name, price)
SELECT 'Mouse', 29.99
WHERE NOT EXISTS (
    SELECT 1 FROM products WHERE name = 'Mouse'
);
