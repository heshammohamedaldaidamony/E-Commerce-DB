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
- [5. Indexing](#5-indexing)
- [6. Challenges Faced](#6-challenges-faced-)
  - [6.1 Handling Recursive Categories](#61-handling-retrieving-recursive-categories)
  - [6.2 High Read Operations - Denormalization](#62-denormalization-for-performance-improvement)
  - [6.3 Null Values and Union Operation](#63-null-values-and-union-operation)
  

## 1. Introduction
This repository provides a detailed framework for developing and optimizing an e-commerce database using PostgreSQL. It includes a variety of SQL queries, database design principles, and strategies for performance enhancement. You'll find insights into indexing techniques, denormalization, and other advanced methods to handle and analyze data efficiently, ensuring your system is robust and scalable.


## 2. Entity Relationship Diagram 📊  
- **Logical ERD**
![ERD](DOCs/ERD.png)  
- **Physical ERD**
![ERD](DOCs/Physical%20ERD.png)



## 3. Schema DDL
The Schema DDL SQL code can be reviewed in detail in the following document: [Schema DDL](DOCs/Schema%20DDL.txt)



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
**🛑🛑 The following query is inefficient due to the use of leading wildcards. The database is unable to effectively utilize indexes.**  
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



## 5. Indexing
While primary key indexing is automatic, effective indexing should be query-driven. In many cases, it may be more beneficial to create indexes on other columns, such as foreign keys or frequently queried normal columns, rather than relying solely on primary key indexing. This ensures that we are optimizing our database for actual use cases.  
Excessive indexing can lead to unnecessary consumption of disk space and could degrade performance during write operations (inserts, updates, and deletes).  
  
**Indexing Composite Keys**  
In our e-commerce system, we have a composite key for Order_Details, which consists of (order_id, product_id). By default, the DBMS only indexes order_id. However, since we often query product_id (e.g., to retrieve the top-selling products or product-specific order details), we have added a secondary index on product_id to optimize those queries.
```sql
CREATE INDEX idx_product_id ON Order_Details(product_id);
```


# 6. Challenges Faced 🤔
## 6.1 Handling Retrieving Recursive Categories 
In our e-commerce system, categories can have multiple levels of subcategories, forming a hierarchical tree structure. For example:  
  
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


## 6.2 Denormalization for Performance Improvement  
In our e-commerce system, we encountered a specific case where the volume of read operations for certain attributes—such as customer details, product information, and sales data—was significantly high. To address this, we implemented denormalization to optimize performance.

For example, rather than executing multiple joins across various tables to generate sales history reports, We created a denormalized sale_history table that consolidates these frequently accessed attributes into a single table. This approach reduces the need for complex joins and speeds up data retrieval, particularly for reports and queries that require this specific information.
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

## 6.3 Null Values and Union Operation
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
![Query Result](DOCs/Unoin_Nulls.png)

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
![Query Result](DOCs/Unoin_Cash_Sale.png)

