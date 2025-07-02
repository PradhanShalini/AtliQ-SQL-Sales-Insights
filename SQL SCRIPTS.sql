| On-Demand Analysis Of AtliQ Hardware |

````````````````````````````````````````````````````TASK -1 `````````````````````````````````````````````````````````````````````
Generate a monthly aggregated product-level sales report for Croma India customers for Fiscal Year 2021.
The report is structured to include the following fields:
1)Month
2)Product Name
3)Variant
4)Sold Quantity
5)Gross Price Per Item
6)Gross Price Total

-->SOLUTION

SELECT 
    s.date, s.product_code, s.sold_quantity,
    p.product, p.variant,
    g.gross_price,
    ROUND(s.sold_quantity * g.gross_price, 2) AS gross_price_total
 FROM 
    fact_sales_monthly AS s
 JOIN 
    dim_product AS p 
    USING (product_code)
 JOIN 
    fact_gross_price AS g 
    ON g.product_code = s.product_code
    AND g.fiscal_year = get_fiscal_year(s.date)
 WHERE 
    s.customer_code = 90002002
    AND YEAR(DATE_ADD(s.date, INTERVAL 4 MONTH)) = 2021
 ORDER BY s.date DESC
 LIMIT 1000;


#However, to improve query readability, maintainability, and eliminate repetitive logic, we create a reusable fiscal_year() function to avoid rewriting fiscal year calculations in every query.

#Function of fiscal year
CREATE FUNCTION `get_fiscal_year`(calendar_date DATE) 
	RETURNS int
    	DETERMINISTIC
   BEGIN
        DECLARE fiscal_year INT;
        SET fiscal_year = YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH));
        RETURN fiscal_year;
   END;


#Query to Generate Croma Sales Report – FY 2021
SELECT 
    s.date, s.product_code, s.sold_quantity,
    p.product, p.variant,
    g.gross_price,
    ROUND(s.sold_quantity * g.gross_price, 2) AS gross_price_total
  FROM 
    fact_sales_monthly AS s
  JOIN 
    dim_product AS p 
    USING (product_code)
  JOIN 
    fact_gross_price AS g 
    ON g.product_code = s.product_code
    AND g.fiscal_year = get_fiscal_year(s.date)
  WHERE 
    s.customer_code = 90002002
    AND get_fiscal_year(s.date) = 2021
  ORDER BY s.date ASC
  LIMIT 10000;

```````````````````````````````````````````````````````````TASK -2```````````````````````````````````````````````````````````````````
Create SQL Function to Determine Calendar Quarter from a Date


--> SOLUTION
#Function for Quarter
CREATE FUNCTION `get_quarter`(calender_date date) 
          RETURNS char(2);
DETERMINISTIC
BEGIN
     declare m tinyint;
     declare qtr char(2);
     set m= month(calender_date);

case
      when m  in (9,10,11) then
           set qtr="q1";
      when m   in (12,1,2) then
           set qtr ="q2";
      when m  in  (3,4,5) then
            set  qtr="q3";
      else
            set qtr="q4";
end case; 
return  qtr;
END;

``````````````````````````````````````````````````````````````TASK -3``````````````````````````````````````````````````````````````````````````````````
Retrieve Monthly gross sales report for any customer


--> SOLUTION
#Instead of writing separate queries for each customer like Zepto, Flipkart, or Neptune, we can use a Stored Procedure to retrieve data for any set of customers.

#Create the stored procedure
CREATE PROCEDURE `get_monthly_gross_sales` (IN c_code INT)
BEGIN
SELECT
     s.date,
     ROUND(SUM(g.gross_price * s.sold_quantity), 2) AS monthly_sales
FROM  fact_sales_monthly AS s
JOIN fact_gross_price AS g 
      ON g.product_code = s.product_code
      AND g.fiscal_year = get_fiscal_year(s.date)
WHERE  s.customer_code = c_code
GROUP BY  s.date
ORDER BY  s.date ASC;
END 

``````````````````````````````````````````````````````````````````````TASK -4``````````````````````````````````````````````````````````````````
Create a stored procedure that assigns a market badge to each region based on its total sold quantity.
Badge Logic: If a region's total sold quantity exceeds 5 million units, assign it a 'Gold' badge; otherwise, assign 'Silver'.


--> SOLUTION

CREATE PROCEDURE `get_market_badge`(
        	IN in_market VARCHAR(45), IN in_fiscal_year YEAR,
        	OUT out_market_badge VARCHAR(45)
	)
BEGIN
     DECLARE qty_sold INT DEFAULT 0;
    
  # Default market is India
    	     IF in_market = "" THEN
                  SET in_market="India";
           END IF;
    
  # Retrieve total sold quantity for a given market in a given year
           SELECT 
              SUM(s.sold_quantity) INTO qty_sold 
           FROM fact_sales_monthly s
             JOIN dim_customer c
             ON s.customer_code=c.customer_code
           WHERE 
                  get_fiscal_year(s.date)=in_fiscal_year AND
                  c.market=in_market;
      
 # Market Badge Either Gold or  Silver
          IF qty_sold  > 5000000 THEN
               SET out_market_badge = 'Gold';
          ELSE
              SET out_market_badge= 'Silver';
          END IF;
END;


````````````````````````````````````````````````````````````````TASK-5```````````````````````````````````````````````````````
Generate a bar chart report that visualizes the Top 10 Customers in Fiscal Year 2021 based on their total net sales.

-->SOLUTION
WITH cte1 as (
 SELECT 
     customer, 
     ROUND(SUM(net_sales)/1000000,2) as net_sales_mln		
 FROM gdb0041.net_sales n
 JOIN dim_customer c
 ON
   n.customer_code = c.customer_code
 WHERE fiscal_year = 2021
 GROUP BY customer)
 
 SELECT *, ROUND((net_sales_mln)*100/sum(net_sales_mln) over(),2) as Percentage
 FROM cte1
 ORDER BY net_sales_mln DESC
 LIMIT 10;

#We use Common Table Expressions (CTEs) for reusability and to separate sales aggregation from percentage calculations. The final output is exported as a CSV and visualized using a bar chart.


````````````````````````````````````````````````````````````TASK-6````````````````````````````````````````````````````````````````
Create a stored procedure that returns the top N products based on total net sales for a specified fiscal year.

-->SOLUTION

CREATE PROCEDURE `top_product_by_netsales`( 
         in_fiscal_year INT,
         in_top_n INT
       )
BEGIN
SELECT 
     product, 
     ROUND(SUM(net_sales)/1000000,2) as net_sales_mln		
FROM net_sales n
WHERE fiscal_year = in_fiscal_year
GROUP BY product
ORDER BY net_sales_mln DESC
LIMIT in_top_n;
END;

By using a stored procedure, you gain flexibility and reusability. When executed, the stored procedure allows you to specify any fiscal year and dynamically choose the Top N products or markets (e.g., Top 5, 10, or 20), based on your business requirement. This makes it more scalable and adaptable compared to writing a hardcoded query each time.

```````````````````````````````````````````````````````````````TASK-7```````````````````````````````````````````````````
Write a query to fetch the top 2 markets within each region based on the total gross sales for the fiscal year 2021.

-->SOLUTION

WITH CTE1 as
  (SELECT
	   c.region,
       c.market,
       ROUND(SUM(total_gross_price)/1000000,2) as gross_sales_mln
   FROM gross_sales s
   JOIN dim_customer c
   ON
       c.customer_code = s.customer_code
   WHERE fiscal_year = 2021
   GROUP BY c.region,c.market
   ORDER BY gross_sales_mln DESC),
   
CTE2 as (SELECT *,
         DENSE_RANK() OVER(PARTITION BY region ORDER BY gross_sales_mln DESC) as drnk
FROM CTE1)

SELECT * FROM CTE2 WHERE drnk <= 2;


````````````````````````````````````````````````````````TASK-8````````````````````````````````````````````````
Write a stored procedure that returns the Top 3 Products (by Quantity Sold) for each Division.

-->SOLUTION
CREATE PROCEDURE `top_products_nsales_share_perdivision`( 
            in_fiscal_year INT,
            in_top_n INT
          )
BEGIN
WITH CTE1 as
  (SELECT
	   p.division,
       p.product,
       SUM(sold_quantity) as total_sales
   FROM fact_sales_monthly s
   JOIN dim_product p
   ON
       p.product_code = s.product_code
   WHERE fiscal_year = in_fiscal_year
   GROUP BY p.product,p.division),
  
 CTE2 as (SELECT *,
      DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sales DESC) as drnk
FROM CTE1)

SELECT * FROM CTE2 WHERE drnk <= in_top_n;
END


``````````````This concludes the update. I hope you found it useful. Thank you!```````````````````````````````````````