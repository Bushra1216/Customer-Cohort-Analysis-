# Non-Store Retail Customer Cohort and Retention Analysis

_Mapping customer behavior through retention patterns, churn identification, and spending trends to help retailers grow sustainable revenue and strengthen customer loyalty_

---

<h2><a class="anchor" id="overview"></a>Introduction</h2>
<p align=justify>
Retail businesses often struggle to understand why customers stop purchasing and which customer groups contribute most to the long-term revenue. Without clear visibility into retention, churn, and returning customer behavior—businesses cannot design effective strategies to sustain growth. Cohort Analysis is the process of analyzing customer behavior that allows us to gain a deeper understanding of customer movement and business performance by grouping individuals based on a shared characteristic—most commonly the month they made their first purchase and tracking their behavior over subsequent periods.

By analyzing Cohorts, businesses can-
- Identify churn and recovery behaviors of customer
- Detect retention patterns
- Understand spending trends across months

Monitoring these Cohorts help businesses pinpoint opportunities to improve customer engagement and revenue generation.
In this project, customers are segmented based on their first purchasing month and their activity is monitored across following months to gain valuable insights, which help measure the effectiveness of retention strategies and identify areas for improvement.<p>


<br>
<h2><a class="anchor" id="set_goal"></a>Aim Of The Project</h2>
<p align=justify>
The purpose of this project is to utilize Cohort Analysis across both customer and revenue dimensions to reveal how customer groups behave after acquisition and how their value changes over time. By observing how each cohort progresses over subsequent months, the analysis uncover insights into retention, churn, and spending behaviors of customer that support the effectiveness of their retention strategies and identify opportunities for improvement.

**🔸Customer-Level Cohort Analysis**<br>
By grouping customers into cohorts based on their initial purchase month, this examines how cohorts evolve over time in terms of customer count focusing on customer retention. Observing how many customers remain active in each cohort, businesses can evaluate the effectiveness of retention strategies, identify when and where customer begin to churn and highlight gaps in customer engagement. and uncover opportunities to re-engage lost customers.<br>

**🔸Revenue-Level Cohort Analysis**<br>
This component analyzes how revenue changes across different cohorts subsequent months. Examining revenue generation across cohorts, this will help businesses to identify cohorts that contribute significantly on revenue growth and detect declining cohorts that may require targeted marketing or retention efforts to enhance their value.<br>

Overall, this extensive analysis provides a clear understanding of customer lifetime value, customer retention behavior, and spending patterns. These insights enable retailers to implement targeted engagement strategies, reduce churn and improve revenue forecasting, that ultimately leading to profit and customer satisfaction.</p><br>

<h2><a class="anchor" id="workflow"></a>Project Workflow</h2>


This project follows a complete analytics workflow — including data preparation, extraction, modelling and visualization:

- **Data Preparation -** Cleaned and preprocessed UK based non-store retail dataset using Pandas, handling missing values, outliers, invalid quantity, and preparing refined data for analysis.

- **Loading Data into MSSQL Server -** Exported cleaned data from Python and imported into Microsoft SQL Server using `BULK INSERT` method

- **Perform Cohort Analysis -** Flag duplicates and filter out necessary records to implement cohort-based at both customer level and revenue level using sql queries.
  The cohort analysis serves as a powerful tool for comprehending customer behavior over time. When observing the table, several observations can be made:

- **Visualization in Power BI -** Imported the refined cohort tables into Power BI, built a calendar table, established relationship, and created DAX measures to calculate retained customers, lost customers and recovered customers. Then visualized customer movement and spending patterns over time to help retailers improve in retention and revenue generation.

<br>
<h2><a class="anchor" id="customerLevel"></a>Cohort Analysis based on Customer Counts</h2>
Assess customer retention by counting distinct customers in each cohort across subsequent months

**Query Breakdown:**
```sql
--In CTE1 we defined customer's purchasing date and first purchasing date as cohorts by customer id
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
INTO #CohortTable
FROM CTE2
GROUP BY Cohort_Month, Cohort_Index
ORDER BY Cohort_Month, Cohort_Index ASC;


  ```




