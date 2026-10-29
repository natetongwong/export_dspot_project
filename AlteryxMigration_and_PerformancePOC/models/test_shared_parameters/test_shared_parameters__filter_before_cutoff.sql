{{
  config({    
    "materialized": "ephemeral",
    "database": "ProphecyCompute",
    "schema": "schema"
  })
}}

WITH sales_source AS (

  SELECT * 
  
  FROM {{ ref('sales_with_dates')}}

),

filter_before_cutoff AS (

  SELECT * 
  
  FROM sales_source
  
  WHERE "TransactionDate" < {{ var('cutoff_date') }}

)

SELECT *

FROM filter_before_cutoff
