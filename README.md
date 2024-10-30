# 📦 E-Commerce-DB
## INDEX
- [1. Introduction](#1-introduction)
- [2. Entity Relationship Diagram](#2-entity-relationship-diagram-)
- [3. Schema DDL](#3-schema-ddl)
- [4. Sample Queries](#4-sample-queries)
  - [4.1 Revenue Report](#41-generate-a-daily-report-of-the-total-revenue-for-a-specific-date)
  - [4.2 Top Selling Report](#42-generate-a-monthly-report-of-the-top-selling-products-in-a-given-month)
  - [4.3 Customers Orders > $500](#43-retrieve-a-list-of-customers-who-have-placed-orders-totaling-more-than-500-in-the-past-month)
  - [4.4 Text Searching](#44-search-for-all-products-with-the-word-camera-in-either-the-product-name-or-description)
  - [4.5 Recommend Products](#45-suggest-popular-products-in-the-same-category-for-the-same-author-excluding-the-purchsed-product-from-the-recommendations)
- [5. Advanced Topics](#5-advanced-topics)
  - [5.1 Indexing](#51-indexing)
  - [5.2 SubQueries](#52-subqueries)
  - [5.3 View](#53-view)
  - [5.4 Stored Procedure](#54-stored-procedure)
  - [5.5 Trigger](#55-trigger)
- [6. Challenges Faced](#6-challenges-faced-)
  - [6.1 Handling Recursive Categories](#61-handling-retrieving-recursive-categories)
  - [6.2 High Read Operations - Denormalization](#62-denormalization-for-performance-improvement)
  - [6.3 Null Values and Union Operation](#63-null-values-and-union-operation)
- [7. Query Optimization](#7-query-optimization)
  

## 1. Introduction
This repository provides a comprehensive framework for developing and optimizing an e-commerce database using PostgreSQL. It covers various aspects of database design, including entity relationship diagrams and schema definitions, alongside practical sample queries that facilitate insights into customer behavior and sales performance.  

The repository delves into advanced topics such as indexing strategies to enhance query performance, the use of subqueries for complex data retrieval, and the implementation of views to simplify data access. Additionally, it explores stored procedures and triggers to automate processes and ensure data integrity.

You'll find insights into handling challenges faced during development.  
And a significant focus of this project is query optimization, which is essential for improving the efficiency of SQL queries, reducing execution time, and minimizing resource consumption. You'll find techniques for analyzing query execution plans, optimizing joins, and utilizing indexing and denormalization strategies to ensure your e-commerce system is robust, efficient, and scalable. Overall, this project emphasizes performance enhancement techniques to ensure your e-commerce system is robust, efficient, and scalable.


## 2. Entity Relationship Diagram 📊  
- **Logical ERD**
![ERD](DOCs/ERD.png)  
- **Physical ERD**
![ERD](DOCs/Physical%20ERD.png)



## 3. Schema Creation
The Schema DDL SQL code can be reviewed in detail in the following document: [Schema DDL](DOCs/Schema%20DDL.sql)
  
### 3.1 Natural Vs Surrogate Primary Key
We made a surrogate primary key in the Product table, using a simple sequential identifier (e.g., product_id).  
#### This choice is suitable due to:  
- **Stability**: Product IDs remain unchanged even if product details are modified.  
- **Simplicity**: A numeric ID simplifies relationships and indexing across tables.  
- **security**:These keys are often non-meaningful (like auto-incrementing numbers), which means they do not expose sensitive information about the data.  
  
### 3.2 Soft Vs Hard Delete 🗑️
We often implement soft delete to preserve data integrity and maintain a record of historical data, which can be critical in many applications. Instead of permanently deleting records, a soft delete involves marking them as deleted using a boolean (e.g., is_deleted) or timestamp (e.g., deleted_at) column.  
#### Pros:
- **Easy recovery**: Restore records by resetting the `is_deleted` flag.
- **Audit trail**: Keeps a history for better traceability(Data Analysis).  
- **Data integrity**: Prevents accidental loss of records.



## 4. Sample Queries
### 4.1 Generate a daily report of the total revenue for a specific date
```sql
SELECT SUM(total_price) AS DailyRevenue
FROM Orders
WHERE DATE(order_date) = '2024-08-01';
```
### 4.2 Generate a monthly report of the top-selling products in a given month
```sql
SELECT 
	 p.product_id,
	 product_name, 
	 SUM(od.product_order_quantity)AS total_quantity_sold
FROM order_detail od
JOIN product p ON p.product_id=od.product_id
JOIN orders o ON o.order_id=od.order_id
WHERE 
    EXTRACT(MONTH FROM o.order_date) = 8
    AND EXTRACT(YEAR FROM o.order_date) = 2024
GROUP BY p.product_id
ORDER BY total_quantity_sold DESC;
```
### 4.3 Retrieve a list of customers who have placed orders totaling more than $500 in the past month
```sql
SELECT 
  	c.customer_id,
	CONCAT(c.first_name,' ',c.last_name) AS customer_name,
	SUM(o.total_price)
FROM customer  c 
JOIN orders o ON o.customer_id=c.customer_id
WHERE o.order_date >= date_trunc('month', current_date - interval '1 month')
    AND o.order_date < date_trunc('month', current_date)
GROUP BY c.customer_id
HAVING SUM(o.total_price) > 500; 
```
### 4.4 Search for all products with the word "camera" in either the product name or description
```sql
SELECT
	product_id,
	product_name,
	description,
	long_description
FROM product  c 
WHERE product_name LIKE '%camera%'
	OR description LIKE '%camera%'
	OR long_description LIKE '%camera%';
```
**🛑 The following query is inefficient due to the use of leading wildcards. The database is unable to effectively utilize indexes.**  
#### 🛠️ Proposed Solutions
| **Solution**                    | **Description**                                                                                                      | **Pros**                                                        | **Cons**                                                                       |
|----------------------------------|----------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------|--------------------------------------------------------------------------------|
| **1. Limiting Leading Wildcards**| Use regular indexes and avoid leading wildcards by restructuring queries (camera%).                                             | **Index-Friendly**: Works efficiently with indexes in any database.  | **Less flexible**: Can't search for terms in the middle of strings (%camera%).            |
| **2. Full-Text Search**          | Use `MATCH` and `AGAINST` operators for full-text search on indexed columns.                                          | **Efficient for large text**: Enhances performance for large text searches. | **Limited availability**: Not supported by all databases.     |

### 4.5 Suggest popular products in the same category for the same author, excluding the purchsed product from the recommendations
```sql
SELECT 
	 p.product_id,
	 product_name, 
	 description,
	 product_price,
	 COUNT(*) sales_count  -- instead add sales_count as a column in product table
FROM product p
JOIN order_detail od ON p.product_id = od.product_id 
WHERE category_id = (SELECT category_id FROM product WHERE product_id = 1)  
	AND p.product_id != 1    -- 1 is the purchased product for example
GROUP BY p.product_id
ORDER BY sales_count DESC
LIMIT 5;
```

## 5. Advanced Topics
## 5.1 Indexing
There are two types of index :  
| **Index Type**         | **Pros**                                                      | **Cons**                                                  | **Time Complexity**            | **Example**                                                                                                     |
|------------------------|--------------------------------------------------------------|-----------------------------------------------------------|--------------------------------|-----------------------------------------------------------------------------------------------------------------|
| **Clustered Index**     | Fast data retrieval, maintains data in sorted order, ideal for range queries. | Only one per table, can slow down insert/update operations due to data rearrangement. | O(log n) for retrieval, O(n) for insert/update due to **rearrangement**. |➡️ The `order_id` primary key in the `orders` table can be set as a clustered index, allowing quick retrieval of order data, such as fetching details about an Order for a Kitchen Appliance.  ➡️ For range queries, such as retrieving products priced between `$100` and `$200`, it efficiently scans through the sorted data. |
| **Non-Clustered Index** | Multiple indexes per table, improves retrieval performance for various queries. | Requires additional storage, slower access due to pointer lookups. | O(log n) for retrieval, O(n) for insert/update due to **additional pointers**. | ➡️ Creating a non-clustered index on the `email` column in the `customer` table allows fast lookup of customers during authentication or when sending marketing emails. |

While primary key indexing is automatic, effective indexing should be query-driven. In many cases, it may be more beneficial to create indexes on other columns, such as foreign keys or frequently queried normal columns, rather than relying solely on primary key indexing. This ensures that we are optimizing our database for actual use cases.  
**🛑 Excessive indexing can lead to unnecessary consumption of disk space and could degrade performance during write operations (inserts, updates, and deletes).**   
  
**Indexing on Foreign Keys**  
➡️ In a sales table where customer_id references the customers table, indexing customer_id allows faster retrieval of sales records for specific customers. For instance, if John Doe is a frequent buyer with customer_id = 202, the index helps quickly retrieve his purchase history.  
  
**Indexing Composite Keys**    
➡️ In our e-commerce system, we have a composite key for Order_Details, which consists of (order_id, product_id). By default, the DBMS only indexes order_id. However, since we often query product_id (e.g., to retrieve the top-selling products or product-specific order details), we have added a secondary index on product_id to optimize those queries.

## 5.2 SubQueries
In complex database systems, certain queries require fetching data based on the result of other queries.  
➡️ For example:  
A scenarion where a user selects multiple categories (e.g., "Hiking Boots," "Hooded Sweats," "College Teams") to filter the displayed products
```sql
SELECT p.product_id, p.product_name, p.product_price
FROM product p
WHERE p.category_id IN (
    SELECT c.category_id
    FROM category c
    WHERE c.category_name IN ('Hiking Boots', 'Hooded Sweats', 'College Teams')
);
```
**🛑 These subqueries can enhance the flexibility of data retrieval but also introduce performance challenges:** 
  
➡️ Imagine the scenario that we want to identify products that are priced above the average price of products within their respective categories. This can help in determining premium products for promotional strategies.
```sql
SELECT p.product_id, p.product_name, p.product_price
FROM product p
WHERE p.product_price > (
    SELECT AVG(p2.product_price)
    FROM product p2
    WHERE p2.category_id = p.category_id
);
```
**🛑 The inner query is executed for each row returned by the outer query (Correlated Subquery) which is performance challange.**

## 5.3 View
➡️ We want to generate a sales report that summarizes customer purchases over the past month. The report should include customer names, total sales amounts, and the number of purchases for each customer.
**Challenge:** The sales data is spread across multiple tables: orders, order_detail, and customer. Creating this report requires complex joins and aggregations that would be cumbersome for end-users who need to access this information frequently.
**Solution:** Create a view that encapsulates the logic required to generate this report.
```sql
CREATE VIEW customer_sales_report AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(od.product_order_quantity * od.unit_price) AS total_sales,
    COUNT(o.order_id) AS total_orders
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_detail od ON o.order_id = od.order_id
WHERE o.order_date >= date_trunc('month', current_date - interval '1 month')
GROUP BY c.customer_id
ORDER BY total_sales DESC;
```
**🛑 Although views offer significant benefits in terms of simplifying complex queries, enhancing security(Access Levels), and ensuring consistency in reporting, they also come with drawbacks related to functionality, and maintenance,Views can become stale if underlying data changes(Static View)**


## 5.4 Stored Procedure
➡️ When a customer places an order, multiple operations need to be executed, such as updating inventory, calculating total prices, applying discounts, and creating records in the orders and order details tables.  
A stored procedure can encapsulate all these steps into a single transaction, ensuring that either all changes are committed or none are, preserving data integrity.
#### pros:  
- Stored procedures are precompiled, which can improve execution speed than a normal query.
- Can help enhance security by restricting direct access to tables.
```sql
CREATE PROCEDURE ProcessOrder(
    IN p_customer_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    OUT p_order_id INT
)
BEGIN
    DECLARE v_total_price DECIMAL(10, 2);
    
    -- Calculate total price
    SELECT price INTO v_total_price FROM product WHERE product_id = p_product_id;
    SET v_total_price = v_total_price * p_quantity;

    -- Insert order
    INSERT INTO orders (customer_id, order_date, total_price)
    VALUES (p_customer_id, NOW(), v_total_price);
    SET p_order_id = LAST_INSERT_ID();

    -- Update inventory
    UPDATE product SET stock = stock - p_quantity WHERE product_id = p_product_id;
END;
```


## 5.5 Trigger
➡️ When an order is deleted from the orders table (perhaps due to cancellation), you might want to automatically delete the related rows in the order_detail table to avoid orphaned records. This ensures that when an order is removed, all its associated details are also removed which using of trigger comes(After Trigger), keeping the data consistent.
```sql
CREATE TRIGGER DeleteOrderDetailsAfterOrderDelete
AFTER DELETE ON orders
FOR EACH ROW
BEGIN
    DELETE FROM order_detail WHERE order_id = OLD.order_id;
END;
```
**🛑 But they can become dangerous if not carefully managed like **cascading triggers** causes innfinite loops.**


## 6. Challenges Faced 🤔
### 6.1 Handling Retrieving Recursive Categories 
In our e-commerce system, categories can have multiple levels of subcategories, forming a hierarchical tree structure.➡️ For example:  
  
**Clothes**    
├── **Shoes** 👟    
│   ├── Sport Shoes  
│   │   └── Half Neck Sport Shoes  
│   └── Casual Shoes  
├── **Accessories** 🎒    
    └── Belts  
      
Managing and retrieving this hierarchical data efficiently is crucial for providing a seamless user experience. Below are the solutions we considered to handle this recursive relationship.
#### 🛠️ Proposed Solutions

| Solution                                          | Description                                                                                         | Pros                                                       | Cons                                                          |
|---------------------------------------------------|-----------------------------------------------------------------------------------------------------|------------------------------------------------------------|---------------------------------------------------------------|
| **1. Application-Level Solution: On-Demand API Calls** | When a user clicks on a category, the application makes an API request to fetch its immediate subcategories dynamically. | **Dynamic Data Loading**: Fetches only the necessary data when needed, optimizing initial load times. | **Increased API Calls**: May lead to multiple requests, increasing latency. |
| **2. Database-Level Solution: Denormalization with JSON Subcategories** | Create a new table that stores categories with their subcategories in a JSON field. | **Single Query Retrieval**: Fetch entire category tree in one database call. | **Data Redundancy**: JSON may duplicate data, leading to inconsistencies. |


### 6.2 Denormalization for Performance Improvement  
In our e-commerce system, we encountered a specific case where the volume of read operations for certain attributes—such as customer details, product information, and sales data—was significantly high. To address this, we implemented denormalization to optimize performance.

➡️ For example, rather than executing multiple joins across various tables to generate sales history reports, We created a denormalized sale_history table that consolidates these frequently accessed attributes into a single table. This approach reduces the need for complex joins and speeds up data retrieval, particularly for reports and queries that require this specific information.
```sql
CREATE TABLE sale_history (
  customer_id SERIAL PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL

  product_id CHAR(8),
  description VARCHAR(50) NOT NULL,
  price NUMERIC(5,2) NOT NULL,
  
  sale_no SMALLINT,
  sale_date DATE NOT NULL,
  quantity INTEGER NOT NULL,
  amount NUMERIC(6,2) NOT NULL,
  
  PRIMARY KEY (sale_no)  -- cutomer_id and product_id can be repeated, but sale_no cannot
);
```

### 6.3 Null Values and Union Operation
we encountered a situation where retrieving data with null values in the CustomerNo field was problematic. Specifically, including these nulls in the results caused issues with the query output.
Like this query:
```sql
SELECT 
    customers.custumer_id, 
    customers.first_name, 
    customers.last_name, 
    COUNT(*) AS num_sales
FROM sales
LEFT JOIN customers ON sales.custumer_id = customers.custumer_id
GROUP BY customers.custumer_id, customers.first_name, customers.last_name
ORDER BY customers.last_name, customers.first_name;
```
<img src="DOCs/Unoin_Nulls.png" alt="Query Result" width="70%" />  

Well, there's no obvious way to eliminate the nulls from the query that we've already got, but what we can do is break the original query into two: 
one that retrieves the sales for "real" customers, and one that retrieves the cash sales(e.g., a walk-in customer). As long as the results of both queries are compatible, we can then use a UNION to combine them into a single result.
```sql
SELECT 
    customers.custumer_id, 
    customers.first_name, 
    customers.last_name, 
    COUNT(*) AS num_sales
FROM sales
LEFT JOIN customers ON sales.custumer_id = customers.custumer_id
GROUP BY customers.custumer_id, customers.first_name, customers.last_name

UNION

SELECT 
    'Cash sale' AS custumer_id,
    'Cash sale' AS first_name,
    'Cash sale' AS last_name,
    COUNT(*) AS num_sales
FROM sales
WHERE sales.custumer_id IS NULL

ORDER BY last_name, first_name;

```
<img src="DOCs/Unoin_Cash_Sale.png" alt="Query Result" width="70%" />  



## 7. Query Optimization
 
### 7.1 Write SQL Query to Retrieve the total number of products in each category.
```sql
EXPLAIN ANALYZE
SELECT category_name , COUNT(*) AS total_products 
FROM product
RIGHT JOIN category ON category.category_id = product.category_id
GROUP BY category.category_id;
```
The database performs a full table scan, resulting in slower performance.By indexing the foreign key(category_id), the database can more efficiently find and join related rows, reducing query execution time.  
Here is the query execution plan: 
| Before Optimization | After Optimization |
|---------------------|--------------------|
| ![Before Optimization](DOCs/Query%20Optimization/Q1_before.png) | ![After Optimization](DOCs/Query%20Optimization/Q1_after.png) |

### 7.2 Write SQL Query to Retrieve the most recent orders with customer information(LIMIT 1000).
```sql
EXPLAIN ANALYZE
SELECT o.order_id,o.order_date,CONCAT(first_name,' ',last_name) As full_name  
FROM orders o 
JOIN customer c ON o.customer_id = c.customer_id
ORDER BY order_date DESC
LIMIT 1000;
```
From the execution plans before and after adding the index on order_date, the following changes and improvements can be observed:
| **Aspect**                  | **Before Optimization**                                 | **After Optimization**                                 |
|-----------------------------|--------------------------------------------------------|--------------------------------------------------------|
| **Execution Plan**             | ![Before Optimization](DOCs/Query%20Optimization/Q2_before.png) | ![After Optimization](DOCs/Query%20Optimization/Q2_after.png) |
| **Sorting**                  | Top-N heapsort                                        | **Removed** (Since the index provides pre-sorted data, the query plan no longer involves a sort step.)         |
| **Join Method**              | Parallel Hash Join                                     | The join operation switched to a Nested Loop instead of a Hash Join, which is generally faster when dealing with smaller sets of data (after the limit operation)                                           |
| **Scan Method on Orders**    | Parallel Seq Scan (Full table scan)                    | The query plan now uses Index Scan Backward on the orders table     |

### 7.3 Write SQL Query to List products that have low stock quantities of less than 10 quantities.
```sql
EXPLAIN ANALYZE
SELECT product_name, product_quantity
FROM Product
WHERE product_quantity < 10;
```
| **Before Optimization**                  | **After Optimization**                                 | **More Optimize**                                 |
|-----------------------------|--------------------------------------------------------|--------------------------------------------------------|
| The query scans every row in the table **(Sequential Scan)**          | Creating index on `product_quantity` **Bitmap Index** that has cost reflects the time spent retrieving the actual data from the table based on the bitmap. | Creating **Covering Index** (on `product_quantity`, includes `product_name`) which allows the query to fetch both required columns (`product_name` and `product_quantity`) from the index itself, avoiding table access **(Index Only Scan)** |
| ![Before Optimization](DOCs/Query%20Optimization/Q3_before.png) | ![After Optimization](DOCs/Query%20Optimization/Q3_after.png) | ![After Optimization](DOCs/Query%20Optimization/Q3_after2.png) |

### 7.4 Write SQL Query to Calculate the revenue generated from each product category.
```sql
EXPLAIN ANALYZE
SELECT c.category_name , SUM(o.total_price) AS category_revenue
FROM category c
LEFT JOIN product p ON p.category_id=c.category_id
LEFT JOIN order_detail od ON od.product_id=p.product_id
LEFT JOIN orders o ON o.order_id=od.order_id
GROUP BY c.category_id;
```
To optimize our query performance, we tracked the joins we created indexes on foreign keys involved in joins, specifically on product.category_id, order_detail.product_id, and order_detail.order_id. This allows the database to quickly locate and match rows during join operations.  
To further optimize query performance, we strategically applied clustering on key tables based on the foreign keys.
| Before Optimization | After Optimization |
|---------------------|--------------------|
| ![Before Optimization](DOCs/Query%20Optimization/Q4_before.png) | ![After Optimization](DOCs/Query%20Optimization/Q4_after.png) |  

**🛑Indexing and clustering can boost performance, but for large tables with heavy aggregations, they may not be ideal. As tables grow, maintaining indexes and clusters becomes costly, especially with frequent updates like on orders and order_detail tables. Aggregating on indexed columns can still cause performance issues due to the large data volumes being scanned.**  

In scenarios involving large aggregations, a better alternative to relying solely on indexing is using subquery pre-aggregation. Instead of directly joining and aggregating everything at once, we can first pre-aggregate order details in a subquery and then join the summarized data with other tables.
```sql
EXPLAIN ANALYZE
SELECT category_name, SUM(total_price)
FROM category c
LEFT JOIN product p ON p.category_id = c.category_id
LEFT JOIN (
    SELECT product_id, SUM(total_price) AS total_price
	FROM order_detail od
	LEFT JOIN orders o ON od.order_id=o.order_id
    GROUP BY product_id
) od ON od.product_id = p.product_id
GROUP BY c.category_id;
```
<img src="DOCs/Query%20Optimization/Q4_after2.png" alt="After Optimization" width="70%" />  
  
Another solution, We could denormalize the data by embedding some category-related fields (like category_name) in the order_detail table to avoid joining with the product and category tables altogether.
```sql
--Add columns
ALTER TABLE order_detail 
ADD COLUMN category_id INT,
ADD COLUMN category_name VARCHAR(255);
--Update data
UPDATE order_detail od
SET category_id = p.category_id, category_name = c.category_name
FROM product p
JOIN category c ON p.category_id = c.category_id
WHERE od.product_id = p.product_id;
```
Now, your query can be simplified to:
```sql
SELECT category_name, SUM(o.total_price) AS category_revenue
FROM order_detail od
JOIN orders o ON od.order_id = o.order_id
GROUP BY category_name;
```
<img src="DOCs/Query%20Optimization/Q4_after3.png" alt="After Optimization" width="70%" />  

**🛑 Although this denormalization reduces some of the complexity and improves execution time, it might still not be the optimal solution in cases where the dataset grows even larger. To further improve performance, we can increase the level of denormalization by creating a pre-aggregated summary table that stores the result of the revenue calculations. This avoids calculating aggregates on-the-fly.**
```sql
CREATE TABLE category_revenue (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(255),
    total_revenue NUMERIC
);

-- Insert Data
INSERT INTO category_revenue (category_id, category_name, total_revenue)
SELECT c.category_name, SUM(o.total_price) AS category_revenue
FROM category c
LEFT JOIN product p ON c.category_id = p.category_id
LEFT JOIN order_detail od ON p.product_id = od.product_id
LEFT JOIN orders o ON od.order_id = o.order_id
GROUP BY c.category_name;
```
Once the data is inserted into the category_revenue table, you can query it directly to get the pre-computed results:
<img src="DOCs/Query%20Optimization/Q4_after4.png" alt="After Optimization" width="70%" />  
  
We can use a trigger to update the category_revenue table whenever there are changes in the order_detail table:
```sql
CREATE OR REPLACE FUNCTION trg_update_category_revenue_func()
RETURNS TRIGGER AS $$
BEGIN
    -- Update category_revenue table based on the new order details
    UPDATE category_revenue cr
    SET total_revenue = (
        SELECT SUM(o.total_price)
        FROM category c
        LEFT JOIN product p ON c.category_id = p.category_id
        LEFT JOIN order_detail od ON p.product_id = od.product_id
        LEFT JOIN orders o ON od.order_id = o.order_id
        WHERE c.category_id = cr.category_id
        GROUP BY c.category_id
    )
    -- Only the affected categories table are updated in the category_revenue.
    WHERE cr.category_id IN (
        SELECT c.category_id
        FROM category c
        LEFT JOIN product p ON c.category_id = p.category_id
        LEFT JOIN order_detail od ON p.product_id = od.product_id
        WHERE od.order_id = NEW.order_id
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trg_update_category_revenue
AFTER INSERT OR UPDATE ON order_detail
FOR EACH ROW
EXECUTE FUNCTION trg_update_category_revenue_func();
```
🟢🟢 Feeling a bit overwhelmed by all the solutions? Here's a clear comparison to simplify things for you:

| **Criteria / Solutions**              | **Indexing & Clustering**                | **Subquery Pre-Aggregation**             | **Simple Denormalization**                      | **Pre-Aggregated Summary Table(Next Level Of Denormalization)**  |
|---------------------------------------|------------------------------------------|------------------------------------------|------------------------------------------|------------------------------------------|
| **Execution Time**                              | **7826.924** ms             | **5254.025** ms            | **2964.587** ms          | **0.065** ms|
| **Cons**                              | Extra storage, maintenance required, may still be slow for large aggregations. | More complex query logic; still needs joins. | Redundant data, harder to maintain, increases storage usage. | Extra storage, triggers needed to keep updated. |

