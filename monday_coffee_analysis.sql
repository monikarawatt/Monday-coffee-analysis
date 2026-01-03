CREATE DATABASE Monday_coffee;
USE Monday_coffee;

CREATE TABLE city(
city_id int PRIMARY KEY, 
city_name varchar(20),
population int,
estimated_rate float,
city_rank int);

SELECT*
FROM city;

CREATE TABLE customers(
customer_id int PRIMARY KEY,
customer_name varchar(20),
city_id int,
FOREIGN KEY(city_id) references city(city_id)
);

SELECT* 
FROM customers;

CREATE TABLE products(
product_id int PRIMARY KEY,
product_name varchar(50),
price int);

SELECT* 
FROM products;

ALTER TABLE customers
ADD PRIMARY KEY (customer_id);

CREATE TABLE sales(
sale_id int PRIMARY KEY,
sale_date date,
product_id int,
customer_id int,
total float,
rating int,
FOREIGN KEY (product_id) REFERENCES products(product_id),
FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
 );
 
 -- Reports and Data Analysis
 
 -- Q1 Coffee consumers count
 -- How many people in each city are estimated to consume coffee, given that 25% of the population
 
 SELECT 
	 city_name, 
	 population * 0.25 AS estimate_coffee_consumer,
	 city_rank
 FROM city
	ORDER BY 2 desc
 ;
 
 -- Q2 Total Revenue from coffee sale(2023)
 -- What is the total revenue generated from coffee sales across all cities in last quarter of 2023

 SELECT 
	SUM(total) AS total_revenue_q4_2023
 FROM sales 
	WHERE sale_date BETWEEN "2023-01-01" AND
	"2023-12-31";
 
 -- Q3 Sales count for each product
 -- How many units of each coffee product have been sold.
 
 SELECT p.product_name,
	SUM(s.total) AS total_unit_sold
 FROM sales s
	 JOIN products p
	 ON s.product_id = p.product_id
	 GROUP BY p.product_name;
 
 -- Q4 Average sales amount per city 
 -- What is the average sales amount per customer in the each city
 
 SELECT c.city_name,
	ROUND(AVG(s.total),2) avg_sale_per_customers
 FROM sales s 
	 JOIN customers cu
	 ON s.customer_id = cu.customer_id
	 JOIN city c
	 ON cu.city_id = c.city_id
	 GROUP BY c.city_name
	 ORDER BY avg_sale_per_customers desc;
 
 -- Q5 City population and coffee consume
 -- Provide a list of cities among with their population and estimated coffee consume
 
 SELECT 
	 city_name,
	 population,
	 ROUND(population * 0.25)/1000000 AS total_coffee_consumer
 FROM city 
	ORDER BY total_coffee_consumer;
 
 -- Q6 Top selling products
 -- What are the top 3 selling products in each city based on the sales volume
 
 WITH product_sales AS(
	SELECT
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) AS total_sales
	FROM sales s 
		JOIN customers c ON s.customer_id = c.customer_id
	 JOIN city ci On c.city_id = ci.city_id
	 JOIN products p ON s.product_id = p.product_id
	 GROUP BY ci.city_name, p.product_name
 ),
 ranked_products AS (
	SELECT*,
		DENSE_RANK() OVER (
		PARTITION BY city_name
		ORDER BY total_sales DESC
		) AS rnk
	FROM product_sales
 )
	SELECT 
		city_name,
		product_name,
		total_sales
	FROM ranked_products
		WHERE rnk <= 3
		ORDER BY city_name, total_sales desc;
 
 
 -- Q7 Customer Segmentation by city
 -- How many unique customer sare in each city who hav epurchase coffee products
WITH monthly_sales AS (
    SELECT
        ci.city_name,
        YEAR(s.sale_date) AS year,
        MONTH(s.sale_date) AS month,
        SUM(s.total) AS current_month_sales
    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON c.city_id = ci.city_id
    GROUP BY
        ci.city_name,
        YEAR(s.sale_date),
        MONTH(s.sale_date)
),

sales_with_lag AS (
    SELECT
        city_name,
        year,
        month,
        current_month_sales,
        LAG(current_month_sales) OVER (
            PARTITION BY city_name
            ORDER BY year, month
        ) AS previous_month_sales
    FROM monthly_sales
)

SELECT
    city_name,
    year,
    month,
    current_month_sales,
    previous_month_sales,
    ROUND(
        ((current_month_sales - previous_month_sales)
        / previous_month_sales) * 100, 2
    ) AS monthly_growth_percentage
FROM sales_with_lag
WHERE previous_month_sales IS NOT NULL
ORDER BY city_name, year, month;

-- Q8 Impact of estimated Rent on the sales
-- Find each city and their average sales per customer and avg rent per customer

SELECT 
    c.city_name,
    ROUND(SUM(p.price) / COUNT(DISTINCT cu.customer_id),2) AS avg_sales_per_customer,
    ROUND(c.estimated_rate / COUNT(DISTINCT cu.customer_id),2) AS avg_rent_per_customer
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN customers cu ON s.customer_id = cu.customer_id
JOIN city c ON cu.city_id = c.city_id
GROUP BY c.city_name, c.estimated_rate;

-- Q9 Customer segmentation by city
-- How many unique customer are there in each city who have purchased coffee product

SELECT
ci.city_name,
COUNT(DISTINCT c.customer_id) AS unique_customer
FROM customers c
JOIN city ci ON c.city_id = ci. city_id 
GROUP BY ci.city_name;


-- Q10 Market potential analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, and estimated cofee consumers

SELECT
    c.city_name,
    COUNT(s.sale_id) AS total_sales,
    COUNT(DISTINCT cu.customer_id) AS total_customers,
    SUM(c.estimated_rate) AS total_rent,
    ROUND(c.population * 0.25) AS estimated_coffee_consumers
FROM sales s
JOIN customers cu
    ON s.customer_id = cu.customer_id
JOIN city c
    ON cu.city_id = c.city_id
GROUP BY
    c.city_name,
    c.population
ORDER BY total_sales DESC
LIMIT 3;

 -- PUNE
-- Highest total sales: 2135 (Top among all cities)
-- Highest customer base: 52 customers
-- High estimated coffee consumers: 18,75,000
-- Moderate rent: 32,66,500 (sales ke comparison me balanced)
-- Conclusion:
-- Pune shows strong demand, large customer base, and good cost-to-revenue balance, making it the best city for expensions.

-- CHENNAI
-- Strong total sales: 1601
-- Good number of customers: 42
-- Estimated coffee consumers: 27,75,000 (highest among top cities)
-- Rent slightly high: 27,37,100 but justified by market size
-- Conclusion:
-- Chennai has a large potential coffee-drinking population and stable sales, suitable for scaling operations.

 -- BANGALORE
-- Total sales: 1464
-- Customers: 39
-- Estimated coffee consumers: 30,75,000 (very high)
-- Highest rent: 43,48,000
-- Conclusion:
-- Bangalore has a huge coffee-loving population, but high rental cost slightly reduces profitability, placing it at rank 3.





