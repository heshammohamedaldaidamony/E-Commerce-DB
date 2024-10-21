-------------------------------------- category table

CREATE OR REPLACE FUNCTION insert_categories()
RETURNS VOID AS $$
DECLARE
    i INT;
    category_name TEXT;
    parent_category_id INT;
BEGIN
    -- Loop to insert 100 categories
    FOR i IN 1..100 LOOP
        -- Generate a category name dynamically
        category_name := 'Category ' || i;
        
        -- Assign parent_category_id as NULL for the first 10 categories
        -- and randomly for others to simulate subcategories
        IF i <= 10 THEN
            parent_category_id := NULL;
        ELSE
            -- Assign a random parent from the first 10 categories
            parent_category_id := (SELECT category_id FROM category WHERE category_id <= 10 ORDER BY RANDOM() LIMIT 1);
        END IF;
        
        -- Insert the category
        INSERT INTO category (category_name, parent_category_id)
        VALUES (category_name, parent_category_id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- To insert 100 categories, simply call the function:
SELECT insert_categories();



---------------------------------------- product table

CREATE OR REPLACE FUNCTION insert_products(num_rows INT)
RETURNS VOID AS $$
DECLARE
    i INT;
    product_name TEXT;
    description TEXT;
    long_description TEXT;
    product_price NUMERIC(10, 2);
    product_quantity INT;
    product_discount NUMERIC(5, 2);
    v_category_id INT; -- Renaming the local variable to avoid conflict
BEGIN
    FOR i IN 1..num_rows LOOP
        -- Generate random data for each product
        product_name := 'Product ' || i;
        description := 'This is a short description for product ' || i;
        long_description := 'This is a longer description for product ' || i || ', which provides more details.';
        product_price := ROUND((RANDOM() * 1000)::NUMERIC, 2); -- Random price between 0 and 1000
        product_quantity := (RANDOM() * 1000)::INT; -- Random quantity between 0 and 1000
        product_discount := ROUND((RANDOM() * 50)::NUMERIC, 2); -- Random discount between 0% and 50%
        
        -- Assign a random category from the category table
        SELECT c.category_id INTO v_category_id 
        FROM category c
        ORDER BY RANDOM() 
        LIMIT 1;
        
        -- Insert product into the table
        INSERT INTO product (product_name, description, long_description, product_price, product_quantity, product_discount, category_id)
        VALUES (product_name, description, long_description, product_price, product_quantity, product_discount, v_category_id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT insert_products(100000);



-------------------------------------- customer table

CREATE OR REPLACE FUNCTION insert_customers(num_rows INT)
RETURNS VOID AS $$
DECLARE
    i INT;
    first_name TEXT;
    last_name TEXT;
    email TEXT;
    password TEXT;
BEGIN
    FOR i IN 1..num_rows LOOP
        -- Generate random first name and last name
        first_name := 'FirstName' || i;
        last_name := 'LastName' || i;
        
        -- Generate random email using first name and last name
        email := first_name || '.' || last_name || '@example.com';
        
        -- Generate a random password (for simplicity, just concatenating 'password' and the row number)
        password := 'password' || i;
        
        -- Insert the customer into the table
        INSERT INTO customer (first_name, last_name, email, password)
        VALUES (first_name, last_name, email, password);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT insert_customers(100000);



-------------------------------------- orders table

ALTER TABLE orders DISABLE TRIGGER ALL;

CREATE OR REPLACE FUNCTION insert_orders(num_rows INT)
RETURNS VOID AS $$
DECLARE
    i INT := 0;
    batch_size INT := 1000; -- Number of rows per batch
    v_order_date TIMESTAMP;
    v_total_price NUMERIC(10, 2);
    v_customer_id INT;
    customer_ids INT[]; -- Array to store pre-selected random customer IDs
    insert_query TEXT := ''; -- For dynamically building the batch insert query
BEGIN
    -- Pre-select a list of random customer IDs
    SELECT ARRAY(SELECT customer_id FROM customer ORDER BY RANDOM() LIMIT 1000)
    INTO customer_ids;

    -- Outer loop for batch processing
    WHILE i < num_rows LOOP
        insert_query := 'INSERT INTO orders (order_date, total_price, customer_id) VALUES ';
        
        -- Inner loop to create batch inserts
        FOR j IN 1..batch_size LOOP
            -- Generate random order data
            v_order_date := NOW() - INTERVAL '1 day' * ROUND(RANDOM() * 365); -- Random date within the past year
            v_total_price := ROUND((RANDOM() * 1000)::NUMERIC, 2); -- Random total price between 0 and 1000
            -- Select a random customer ID from pre-selected array
            v_customer_id := customer_ids[FLOOR(RANDOM() * ARRAY_LENGTH(customer_ids, 1) + 1)::INT];
            
            -- Build the batch insert query
            insert_query := insert_query || 
                '(' || quote_literal(v_order_date) || ', ' || v_total_price || ', ' || v_customer_id || '),';
            
            i := i + 1; -- Increment the counter
            EXIT WHEN i >= num_rows; -- Stop if we have inserted enough rows
        END LOOP;

        -- Remove the trailing comma and execute the batch insert
        insert_query := RTRIM(insert_query, ',') || ';';
        EXECUTE insert_query;

        -- Optionally commit after each batch to reduce transaction overhead
        -- COMMIT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT insert_orders(1000000);

ALTER TABLE orders ENABLE TRIGGER ALL;
 


-------------------------------------- order_detail table

ALTER TABLE order_detail DISABLE TRIGGER ALL;

CREATE OR REPLACE FUNCTION insert_order_details(num_rows INT)
RETURNS VOID AS $$
DECLARE
    i INT := 0;
    batch_size INT := 500; -- Increase batch size for larger insertions
    v_order_id INT;
    v_product_id INT;
    v_product_order_quantity INT;
    v_unit_price NUMERIC(10, 2);
    v_product_order_discount NUMERIC(5, 2);
    insert_query TEXT := ''; -- For dynamically building the batch insert query

    order_ids INT[]; -- Array to store pre-selected random order IDs
    product_ids INT[]; -- Array to store pre-selected random product IDs
BEGIN
    -- Pre-select a list of random order IDs
    SELECT ARRAY(SELECT order_id FROM orders ORDER BY RANDOM() LIMIT 500) INTO order_ids;

    -- Pre-select a list of random product IDs
    SELECT ARRAY(SELECT product_id FROM product ORDER BY RANDOM() LIMIT 500) INTO product_ids;

    -- Outer loop for batch processing
    WHILE i < num_rows LOOP
        insert_query := 'INSERT INTO order_detail (order_id, product_id, product_order_quantity, unit_price, product_order_discount) VALUES ';
        
        -- Inner loop to create batch inserts
        FOR j IN 1..batch_size LOOP
            -- Select random order and product IDs from pre-selected arrays
            v_order_id := order_ids[FLOOR(RANDOM() * ARRAY_LENGTH(order_ids, 1)) + 1];
            v_product_id := product_ids[FLOOR(RANDOM() * ARRAY_LENGTH(product_ids, 1)) + 1];

            -- Generate random order detail data
            v_product_order_quantity := FLOOR(RANDOM() * 10 + 1)::INT; -- Random quantity between 1 and 10
            v_unit_price := ROUND((RANDOM() * 100)::NUMERIC, 2); -- Random unit price between 0 and 100
            v_product_order_discount := ROUND((RANDOM() * 10)::NUMERIC, 2); -- Random discount between 0 and 10
            
            -- Build the batch insert query
            insert_query := insert_query || 
                '(' || v_order_id || ', ' || v_product_id || ', ' || 
                v_product_order_quantity || ', ' || v_unit_price || ', ' || 
                v_product_order_discount || '),';

            i := i + 1; -- Increment the counter

            EXIT WHEN i >= num_rows; -- Stop if we have inserted enough rows
        END LOOP;

        -- Remove the trailing comma and execute the batch insert if there are rows to insert
        IF i > 0 THEN
            insert_query := RTRIM(insert_query, ',') || ' ON CONFLICT DO NOTHING;'; -- Use ON CONFLICT to avoid duplicates
            EXECUTE insert_query;
			
        END IF;
		
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Call to the function
SELECT insert_order_details(10000000); -- Insert 10,000,000 rows into order_detail

ALTER TABLE order_detail ENABLE TRIGGER ALL;
