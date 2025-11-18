
USE master;


--Create the database if not exists
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name= 'retail_db')
BEGIN

    CREATE DATABASE retail_db;
END
GO


USE retail_db;


--Create the table if not exists
IF NOT EXISTS(SELECT * FROM sys.tables WHERE name= 'RETAIL')
BEGIN
    CREATE TABLE RETAIL(
      InvoiceNo VARCHAR(20),
      StockCode VARCHAR(20),
      Description VARCHAR(255),
      Quantity INT,
      InvoiceDate DATETIME, 
      UnitPrice DECIMAL(10,2), 
      CustomerID INT, --integer IDs for customers
      Country VARCHAR(20),
      Revenue DECIMAL(18,2)

);
END
GO


select * from RETAIL;
  

--Import data from csv file into the RETAIL table using bulk insert method
BULK INSERT RETAIL FROM 'C:\Users\Shanj\OneDrive\Desktop\data analysis\dataset\cleaned_retail.csv'
WITH (
    FIRSTROW=2,
	  FIELDTERMINATOR='|',
	  ROWTERMINATOR='\n',
	  TABLOCK

);




--Now flag duplicates and filter out unique rows

CREATE PROCEDURE duplicate_check
AS
BEGIN 

-- Drop if table already exists
    IF OBJECT_ID('tempdb..##RETAIL_UNIQUE_DATA') IS NOT NULL  --using global temp table
        DROP TABLE ##RETAIL_UNIQUE_DATA;

WITH CTE AS(
      SELECT *,
	         ROW_NUMBER() OVER(
			      PARTITION BY InvoiceNo, StockCode, CustomerID, QUANTITY 
			      ORDER BY InvoiceDate
			 ) AS duplicate_flg
      FROM RETAIL
)
SELECT * INTO ##RETAIL_UNIQUE_DATA 
FROM CTE  --pass cleaned distinct data into global temp table
WHERE duplicate_flg=1
ORDER BY InvoiceDate;

END

	
EXEC duplicate_check;

SELECT * FROM ##RETAIL_UNIQUE_DATA; 

-- DROP PROCEDURE duplicate_check;



--Customer retention cohort
WITH CTE AS(
     SELECT CustomerID, 
	        DATEFROMPARTS(YEAR(InvoiceDate),MONTH(InvoiceDate),1) AS Purchase_Date,
            MIN(DATEFROMPARTS(YEAR(InvoiceDate),MONTH(InvoiceDate),1)) 
			OVER(PARTITION BY CustomerID ORDER BY InvoiceDate) AS Cohort_Month
     FROM ##RETAIL_UNIQUE_DATA
),
--In CTE2 we find how far the purchase is from the cohort start-how many months since the first purchase.
CTE2 AS(
SELECT CustomerID, Purchase_Date, Cohort_Month,
       DATEDIFF(MONTH,Cohort_Month, Purchase_Date) AS Cohort_Index
FROM CTE
)
--Now count how many unique customers stayed active in each cohort month.
SELECT Cohort_Month, 
       Cohort_Index, 
	   COUNT(DISTINCT CustomerID) AS Active_Customers
INTO #CohortTable -- keep cte result into the temp table
FROM CTE2
GROUP BY Cohort_Month, Cohort_Index
ORDER BY Cohort_Month, Cohort_Index ASC;


SELECT * FROM #CohortTable;



-- pivot to a matrix for visualization
SELECT Cohort_Month,
       [0] AS Month_0, 
	   [1] AS Month_1, 
	   [2] AS Month_2, 
	   [3] AS Month_3, 
	   [4] AS Month_4, 
	   [5] AS Month_5, 
       [6] AS Month_6, 
	   [7] AS Month_7, 
	   [8] AS Month_8, 
	   [9] AS Month_9,
	   [10] AS Month_10, 
	   [11] AS Month_11, 
	   [12] AS Month_12 INTO #pivoted_table
FROM #CohortTable
PIVOT(
     SUM(Active_Customers) 
	 FOR Cohort_Index IN ([0], [1], [2], [3], [4], [5], [6] , [7], [8], [9], [10], [11], [12])
) AS pivot_tbl;

-- view the result
SELECT * FROM #pivoted_table;





-- Now calculating customer retention rate = given period month / customer at the intial month
SELECT FORMAT(Cohort_Month, 'MMM-yyyy') AS COHORT, 
       CAST(100.0 * Month_0 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_0,
       CAST(100.0 * Month_1 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_1, 
       CAST(100.0 * Month_2 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_2,
	   CAST(100.0 * Month_3 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_3,
	   CAST(100.0 * Month_4 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_4,
	   CAST(100.0 * Month_5 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_5,
	   CAST(100.0 * Month_6 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_6,
	   CAST(100.0 * Month_7 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_7,
	   CAST(100.0 * Month_8 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_8,
	   CAST(100.0 * Month_9 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_9,
	   CAST(100.0 * Month_10 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_10,
	   CAST(100.0 * Month_11 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_11,
	   CAST(100.0 * Month_12 / NULLIF(Month_0,0) AS DECIMAL(5,2)) AS Month_12
FROM #pivoted_table;








--Cohort Analysis based on Revenue

WITH CTE1 AS(  
     SELECT DATEFROMPARTS(YEAR(InvoiceDate),MONTH(InvoiceDate),1) AS Purchase_Date,
            MIN(DATEFROMPARTS(YEAR(InvoiceDate),MONTH(InvoiceDate),1)) 
			OVER(PARTITION BY CustomerID ORDER BY InvoiceDate) AS Cohort_Month,
			Revenue
     FROM ##RETAIL_UNIQUE_DATA
),
CTE2 AS(
SELECT Cohort_Month,
       DATEDIFF(MONTH,Cohort_Month, Purchase_Date) AS Cohort_Index, 
	   Revenue
FROM CTE1
)
SELECT Cohort_Month, 
       [0] AS Month_0, [1] AS Month_1, [2] AS Month_2, [3] AS Month_3, [4] AS Month_4, [5] AS Month_5, 
       [6] AS Month_6, [7] AS Month_7, [8] AS Month_8, [9] AS Month_9,[10] AS Month_10, [11] AS Month_11, 
	   [12] AS Month_12
FROM CTE2
PIVOT(
     SUM(Revenue)
	 FOR Cohort_Index IN ([0], [1], [2], [3], [4], [5], [6] , [7], [8], [9], [10], [11], [12])
) AS tb
ORDER BY Cohort_Month;









-- whole table import in power bi
WITH CTE AS(
    SELECT InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country, Revenue, 
	        DATEFROMPARTS(YEAR(InvoiceDate),MONTH(InvoiceDate),1) AS Purchase_Date,
            MIN(DATEFROMPARTS(YEAR(InvoiceDate),MONTH(InvoiceDate),1)) 
			OVER(PARTITION BY CustomerID ORDER BY InvoiceDate) AS Cohort_Date
     FROM ##RETAIL_UNIQUE_DATA),
CTE2 AS(
   SELECT InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country, Revenue,
          Purchase_Date,Cohort_Date, DATEDIFF(MONTH,Cohort_Date, Purchase_Date) AS Cohort_Index
   FROM (
         SELECT * FROM CTE 
	 )subq
)
SELECT * INTO dbo.cleaned_online_retail 
FROM CTE2
ORDER BY Cohort_Index;



SELECT * FROM cleaned_online_retail;

