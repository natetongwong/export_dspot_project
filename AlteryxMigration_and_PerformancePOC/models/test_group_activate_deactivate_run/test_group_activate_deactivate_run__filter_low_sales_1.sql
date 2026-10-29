{{
  config({    
    "materialized": "ephemeral",
    "database": "ProphecyCompute",
    "schema": "schema"
  })
}}

WITH filter_test_data_1 AS (

  SELECT * 
  
  FROM {{ ref('filter_test_data')}}

),

filter_low_sales_1 AS (

  SELECT * 
  
  FROM filter_test_data_1 AS low_source_data
  
  WHERE "Sales" <= 100

)

SELECT *

FROM filter_low_sales_1
