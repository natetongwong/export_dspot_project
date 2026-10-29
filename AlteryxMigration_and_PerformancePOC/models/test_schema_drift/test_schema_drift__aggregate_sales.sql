{{
  config({    
    "materialized": "ephemeral",
    "database": "ProphecyCompute",
    "schema": "schema"
  })
}}

WITH sales_source AS (

  SELECT * 
  
  FROM {{ ref('schema_drift_test')}}

),

reformat_calc AS (

  SELECT 
    "Product",
    "Quantity",
    "Unit_Price",
    "Quantity" * "Unit_Price" AS "Line_Total"
  
  FROM sales_source

),

aggregate_sales AS (

  SELECT 
    "Product",
    SUM("Quantity") AS "Total_Quantity",
    SUM("Line_Total") AS "Total_Sales"
  
  FROM reformat_calc
  
  GROUP BY "Product"

)

SELECT *

FROM aggregate_sales
