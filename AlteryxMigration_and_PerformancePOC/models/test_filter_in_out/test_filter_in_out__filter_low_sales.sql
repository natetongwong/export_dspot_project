{{
  config({    
    "materialized": "ephemeral",
    "database": "ProphecyCompute",
    "schema": "schema"
  })
}}

WITH filter_test_data AS (

  SELECT * 
  
  FROM {{ ref('filter_test_data')}}

),

filter_low_sales AS (

  SELECT * 
  
  FROM filter_test_data AS low_source_data
  
  WHERE "Sales" <= 100

)

SELECT *

FROM filter_low_sales
