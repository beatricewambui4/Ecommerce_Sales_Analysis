CREATE DATABASE KALUNDUSALES;
USE KALUNDUSALES;

#creating a table
CREATE TABLE KALUNDUSALESTABLE (
Order_ID	VARCHAR(100),
Year_Num INT,
Order_Date DATE,
Ship_Date	DATE,
Ship_Mode	VARCHAR(100),
Customer_ID	VARCHAR(50),
Customer_Name	VARCHAR(100),
Segment	VARCHAR(100),
Country	VARCHAR(100),
City	VARCHAR(100),
State	VARCHAR(100),
Postal_Code	VARCHAR(100),
Region	VARCHAR(100),
Product_ID	VARCHAR(100),
Category VARCHAR(100),
Sub_Category	VARCHAR(100),
Product_Name	VARCHAR(500),
Sales	DOUBLE(10,4),
Quantity	INT,
Discount	DOUBLE(10,4),
Profit DOUBLE(10,4)
);

#loading data into the table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Ecommerce Sales Analysis.csv'
INTO TABLE kalundusalestable
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
  Order_ID, Year_Num, @Order_Date, @Ship_Date, Ship_Mode,
  Customer_ID, Customer_Name, Segment, Country, City, State,
  Postal_Code, Region, Product_ID, Category, Sub_Category,
  Product_Name, Sales, Quantity, Discount, Profit
)
SET
  Order_Date = CASE
                 WHEN @Order_Date = '' THEN NULL
                 ELSE STR_TO_DATE(@Order_Date, '%m/%d/%Y')
               END,
  Ship_Date  = CASE
                 WHEN @Ship_Date = '' THEN NULL
                 ELSE STR_TO_DATE(@Ship_Date, '%m/%d/%Y')
               END;
               
ALTER TABLE kalundusalestable
DROP COLUMN  Discount_Band;
               
-- Add the column before trying to update it
ALTER TABLE kalundusalestable
ADD COLUMN Discount_Band VARCHAR(25);

               
-- Fill Discount_Band based on Discount values
UPDATE kalundusalestable
SET Discount_Band = CASE
    WHEN Discount = 0         THEN '0% - No Discount'
    WHEN Discount <= 0.10     THEN '1-10%'
    WHEN Discount <= 0.20     THEN '11-20%'
    WHEN Discount <= 0.40     THEN '21-40%'
    ELSE '40%+ Heavy Discount'
END;


SELECT 
  Discount_Band,
  COUNT(*) AS Total
FROM kalundusalestable
GROUP BY Discount_Band;
               

#Analysis
#total Revenue
SELECT
SUM(Sales) AS Total_Revenue
FROM kalundusalestable;

#Total Quantity sold
SELECT
SUM(Quantity) AS TotalQuantity
FROM kalundusalestable;

#Count of customers
SELECT
COUNT(DISTINCT Customer_ID) AS Total_Customers
FROM kalundusalestable;

#No of orders
SELECT
COUNT(DISTINCT Order_ID) AS TotalOrders
FROM kalundusalestable;

#Profit 
SELECT 
SUM(Profit) AS TotalProfit
FROM kalundusalestable;

#Profit Margin
SELECT
ROUND(SUM(Profit)/SUM(Sales)*100,2) AS Profit_Margin
FROM kalundusalestable;

#average order value
SELECT
SUM(Sales)/COUNT(DISTINCT Order_ID) AS Average_Order_Value
FROM kalundusalestable;

#Top 10 Cities that generates most revenue
SELECT
City,
SUM(Sales) AS Total_Revenue_Per_City
FROM kalundusalestable
GROUP BY City
ORDER BY Total_Revenue_Per_City DESC
LIMIT 10;

#Top 10 cities that sells most units
SELECT
City,
SUM(Quantity) AS Total_Orders_BY_City
FROM kalundusalestable
GROUP BY City
ORDER BY Total_Orders_BY_City DESC
LIMIT 10;

#Category that generates most revenue
SELECT
Category,
SUM(Sales) AS Revenue_By_Category
FROM kalundusalestable
GROUP BY Category
ORDER BY Revenue_By_Category DESC;

#units sold by category
SELECT
Category,
SUM(Quantity) AS Total_Orders_By_Category
FROM kalundusalestable
GROUP BY Category
ORDER BY Total_Orders_By_Category DESC;

#revenue by sub_category
SELECT
Sub_Category,
SUM(Sales) AS Revenue_By_Subcategory
FROM kalundusalestable
GROUP BY Sub_Category
ORDER BY Revenue_By_Subcategory DESC;

#units sold by subcategory
SELECT
Sub_Category,
SUM(Quantity) AS Total_orders_by_subcategory
FROM kalundusalestable
GROUP BY Sub_Category
ORDER BY Total_orders_by_subcategory DESC;

#Top 10 Customers That generates most revenue
SELECT
Customer_Name,
SUM(Sales) AS Revenue_by_Customer
FROM kalundusalestable
GROUP BY Customer_Name
ORDER BY Revenue_by_Customer DESC
LIMIT 10;

#Revenue generated per day
SELECT
DAYNAME(Order_Date) AS Day_Generates_Most_Revenue,
SUM(Sales) AS Total_Revenue
FROM kalundusalestable
GROUP BY Day_Generates_Most_Revenue
ORDER BY Total_Revenue DESC;

#Revenue generated per month
SELECT
MONTHNAME(Order_Date) AS Month_Name,
SUM(Sales) AS Monthly_Sales
FROM kalundusalestable
GROUP BY Month_Name
ORDER BY Monthly_Sales DESC;

#YOY GROWTH
SELECT
  Year_Num,
  ROUND(SUM(Sales), 2) AS SalesPerYear,
  ROUND(
    (SUM(Sales) - LAG(SUM(Sales)) OVER (ORDER BY Year_Num)) /
     LAG(SUM(Sales)) OVER (ORDER BY Year_Num) * 100, 2
  ) AS YOY_Growth_Pct
FROM kalundusalestable
GROUP BY Year_Num
ORDER BY Year_Num ASC;

#Which ship mode is most used and most profitable
SELECT
Ship_Mode,
COUNT(DISTINCT Order_ID) AS Total_Orders,
SUM(Profit) AS Total_Profit,
SUM(Sales) AS Total_Revenue,
ROUND(SUM(Profit)/SUM(Sales)*100,2) AS Profit_Margin,
CEIL(AVG(DATEDIFF(Ship_Date,Order_Date))) AS Average_Days_To_Deliver
FROM kalundusalestable
GROUP BY Ship_Mode
ORDER BY Total_Revenue DESC;

#Segment that drives most value
SELECT
Segment,
COUNT(DISTINCT Order_ID) AS Total_Orders,
SUM(Profit) AS Total_Profit,
SUM(Sales) AS Total_Revenue,
ROUND(SUM(Profit)/SUM(Sales)*100,2) AS Profit_Margin,
ROUND(SUM(Sales)/COUNT(DISTINCT Customer_ID), 2) AS Revenue_Per_Customer
FROM kalundusalestable
GROUP BY Segment
ORDER BY Total_Revenue DESC;

#impact of discount on revenue and orders made
SELECT
  CASE
    WHEN Discount = 0            THEN '0% - No Discount'
    WHEN Discount <= 0.10        THEN '1–10%'
    WHEN Discount <= 0.20        THEN '11–20%'
    WHEN Discount <= 0.40        THEN '21–40%'
    ELSE '40%+ Heavy Discount'
  END AS Discount_Band,
  COUNT(DISTINCT Order_ID)       AS Total_Orders,
  ROUND(SUM(Sales), 2)           AS Total_Revenue,
  ROUND(SUM(Profit), 2)          AS Total_Profit,
  ROUND(AVG(Profit), 2)          AS Avg_Profit_Per_Order
FROM kalundusalestable
GROUP BY Discount_Band
ORDER BY Total_Profit DESC;


#region performance
SELECT
  Region,
  COUNT(DISTINCT Order_ID)       AS Total_Orders,
  ROUND(SUM(Sales), 2)           AS Total_Revenue,
  ROUND(SUM(Profit), 2)          AS Total_Profit,
  ROUND(SUM(Profit)/SUM(Sales)*100, 2) AS Profit_Margin_Pct,
  COUNT(DISTINCT Customer_ID)    AS Unique_Customers
FROM kalundusalestable
GROUP BY Region
ORDER BY Total_Profit DESC;

#MOM Growth
SELECT
  MONTHNAME(Order_Date)          AS Month_Name,
  MONTH(Order_Date)              AS Month_Num,
  ROUND(SUM(Sales), 2)           AS Monthly_Revenue,
  ROUND(SUM(Profit), 2)          AS Monthly_Profit,
  COUNT(DISTINCT Order_ID)       AS Orders_Count
FROM kalundusalestable
GROUP BY  Month_Name, Month_Num
ORDER BY Month_Num ASC;
                                                           






























