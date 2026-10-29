{{
  config({    
    "materialized": "ephemeral",
    "database": "ProphecyCompute",
    "schema": "schema"
  })
}}

WITH filter_test_data_2 AS (

  SELECT * 
  
  FROM {{ ref('filter_test_data')}}

),

filter_high_sales_2 AS (

  SELECT * 
  
  FROM filter_test_data_2 AS high_source_data
  
  WHERE "Sales" > 100

)

SELECT *

FROM filter_high_sales_2
