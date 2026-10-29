{{
  config({    
    "materialized": "ephemeral",
    "database": "ProphecyCompute",
    "schema": "schema"
  })
}}

WITH source_records AS (

  SELECT * 
  
  FROM {{ ref('sample_records')}}

),

reformat_step AS (

  SELECT 
    "ID",
    "Name",
    "Amount",
    "Category",
    "Amount" * 1.1 AS "Amount_With_Tax"
  
  FROM source_records

),

filter_step AS (

  SELECT * 
  
  FROM reformat_step
  
  WHERE "Amount" > 50

),

aggregate_step AS (

  SELECT 
    "Category",
    COUNT(*) AS "Record_Count",
    SUM("Amount") AS "Total_Amount",
    SUM("Amount_With_Tax") AS "Total_With_Tax"
  
  FROM filter_step
  
  GROUP BY "Category"

)

SELECT *

FROM aggregate_step
