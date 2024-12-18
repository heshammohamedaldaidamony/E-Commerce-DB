
-- Table for customers
CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL
);

-- Table for categories
CREATE TABLE category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL,
    parent_category_id INT,
    CONSTRAINT fk_parent_category
        FOREIGN KEY (parent_category_id)
        REFERENCES category (category_id)
);

-- Table for products
CREATE TABLE product (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    long_description TEXT,
    product_price NUMERIC(10, 2) NOT NULL,
    product_quantity INT NOT NULL,
    product_discount NUMERIC(5, 2),
    category_id INT NOT NULL,
    CONSTRAINT fk_category
        FOREIGN KEY (category_id)
        REFERENCES category (category_id)
);

-- Table for orders
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_price NUMERIC(10, 2) NOT NULL,
    order_discount NUMERIC(5, 2),
    ship_date DATE,
    ship_cost NUMERIC(10, 2),
    customer_id INT NOT NULL,
    CONSTRAINT fk_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer (customer_id)
);

-- Table for order details
CREATE TABLE order_detail (
    order_id INT,
    product_id INT,
    product_order_quantity INT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    product_order_discount NUMERIC(5, 2),
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT fk_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id),
    CONSTRAINT fk_product
        FOREIGN KEY (product_id)
        REFERENCES product (product_id)
);
