--Overview of the the sales_data_sample table
SELECT 
	   *
 FROM [PortfolioProjects].[dbo].[sales_data_sample2]

--Checking Unique Values in the relevant columns
SELECT DISTINCT status FROM [dbo].[sales_data_sample2]
SELECT DISTINCT YEAR_ID FROM [dbo].[sales_data_sample2]
SELECT DISTINCT PRODUCTLINE FROM [dbo].[sales_data_sample2]
SELECT DISTINCT COUNTRY FROM [dbo].[sales_data_sample2]
SELECT DISTINCT DEALSIZE FROM [dbo].[sales_data_sample2]
SELECT DISTINCT TERRITORY FROM [dbo].[sales_data_sample2]

--ANALYSIS
--Sales by Product
SELECT 
	PRODUCTLINE,
	ROUND(SUM(sales),2) AS Revenue
FROM [dbo].[sales_data_sample2]
GROUP BY PRODUCTLINE
ORDER BY Revenue DESC


----Sales by Year
SELECT 
	YEAR_ID,
	ROUND(SUM(sales),2) AS Revenue
FROM [dbo].[sales_data_sample2]
GROUP BY YEAR_ID
ORDER BY Revenue DESC


--Sales by Month 2005
SELECT 
	MONTH_ID,
	ROUND(SUM(sales),2) AS Revenue
FROM [dbo].[sales_data_sample2]
WHERE YEAR_ID='2005'
GROUP BY MONTH_ID
ORDER BY Revenue DESC


--Revenue by Deal Size
SELECT 
	DEALSIZE,
	ROUND(SUM(sales),2) AS Revenue
FROM [dbo].[sales_data_sample2]
GROUP BY DEALSIZE
ORDER BY Revenue DESC


--Sales and order frequency by year, month and product line
SELECT 
	YEAR_ID,
	month_Id,
	PRODUCTLINE,
	ROUND(SUM(sales),2) AS Revenue,
	COUNT(ORDERNUMBER) AS Frequency
FROM [dbo].[sales_data_sample2]
GROUP BY YEAR_ID,MONTH_ID,PRODUCTLINE
ORDER BY Revenue DESC

--Best Customers Using RFM Analysis
--Use DATEDIFF() to calculate recency (time between customer last order and most recent date in table)

SELECT 
	CUSTOMERNAME,
	ROUND(SUM(sales),2) AS MonetaryValue,
	ROUND(AVG(sales),2) AS AvgValue,
	COUNT(ORDERNUMBER) AS Frequency,
	DATEDIFF(dd, max(ORDERDATE), (SELECT max(ORDERDATE) FROM [dbo].[sales_data_sample2])) AS Recency,
	MAX(ORDERDATE) AS last_order_date	
FROM [dbo].[sales_data_sample2]
GROUP BY CUSTOMERNAME
ORDER BY MonetaryValue DESC

--Pass the above query to a CTE rfm
--leverage the NTILE() function split rfm values into 4 buckets
--Pass result to a temp table #rfm
DROP TABLE IF EXISTS #rfm
;WITH rfm AS (
SELECT 
	CUSTOMERNAME,
	ROUND(SUM(sales),2) AS MonetaryValue,
	ROUND(AVG(sales),2) AS AvgValue,
	COUNT(ORDERNUMBER) AS Frequency,
	MAX(ORDERDATE) AS last_order_date,
	DATEDIFF(dd, max(ORDERDATE), (SELECT max(ORDERDATE) FROM [dbo].[sales_data_sample2])) AS Recency
FROM [dbo].[sales_data_sample2]
GROUP BY CUSTOMERNAME
),
rfm_calc AS
(
--retrieve all columns from rfm CTE then split rfm_ values into 4 buckets
SELECT 
	r.*,
	NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
	NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
	NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
FROM rfm AS r
)
--retrieve all columns from rfm-calc CTE 
--derive the rfm_cell & rfm_cell_string columns
SELECT c.*, 
	   rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
	   CAST(rfm_recency AS varchar) + CAST(rfm_frequency AS varchar)+CAST(rfm_monetary AS varchar) AS rfm_cell_string
--pass CTEs into temp table
INTO #rfm 
FROM rfm_calc AS c


SELECT * FROM #rfm


--Segmentation
--Now that we have organized our data, we can divide it into specific groups for easier analysis.
--leverage case statements to segment by customer groups
SELECT
	CUSTOMERNAME,
	rfm_recency,
	rfm_frequency,
	rfm_monetary,
	rfm_cell_string,
CASE 
	WHEN rfm_cell_string IN (111,112,121,122,123,132,211,212,114,141) THEN 'lost_customers' --lost customers
	WHEN rfm_cell_string IN (133,134,143,244,334,343,344,144) THEN 'slipping away, cannot lose' --(big spenders that havent purchased lately)
	WHEN rfm_cell_string IN (311,411,331) THEN 'new_customers'
	WHEN rfm_cell_string IN (222,223,233,322) THEN 'potential_customers'
	WHEN rfm_cell_string IN (323,333,321,422,332,432) THEN 'active'--customers that buy often at lower price points
	WHEN rfm_cell_string IN (433,434,443,444) THEN 'loyal'
	END rfm_segment
FROM #rfm;

--Products Sold Together
--Gives the Number of products per order.
SELECT
	[ORDERNUMBER],
	COUNT(*) AS rn
FROM [dbo].[sales_data_sample2]
WHERE status ='Shipped'
GROUP BY ORDERNUMBER;

--Filter for ordernumber 10411 to verify there are 9 products in it
SELECT
	*
FROM [dbo].[sales_data_sample2]
WHERE ORDERNUMBER = 10411;

--Build a subquery that gives us the order numbers when two products are ordered together(rn=2)
SELECT ORDERNUMBER
FROM (
SELECT
	[ORDERNUMBER],
	COUNT(*) AS rn
FROM [dbo].[sales_data_sample2]
WHERE status ='Shipped'
GROUP BY ORDERNUMBER
) AS m
WHERE rn=2;

--Building a 2nd subquery where we will utilize our first subquery "m" 
--Leverage STRING_AGG() allowing for an order containing two product codes to be represented in the same record.

SELECT 
	 ORDERNUMBER, 
	 STRING_AGG(PRODUCTCODE,',') AS Products
FROM [dbo].[sales_data_sample2] AS p
WHERE ORDERNUMBER IN (
SELECT ORDERNUMBER
FROM (
SELECT
	[ORDERNUMBER],
	COUNT(*) AS rn
FROM [dbo].[sales_data_sample2]
WHERE status ='Shipped'
GROUP BY ORDERNUMBER
) AS m
WHERE rn=2
)
GROUP BY ORDERNUMBER
ORDER BY Products;

























