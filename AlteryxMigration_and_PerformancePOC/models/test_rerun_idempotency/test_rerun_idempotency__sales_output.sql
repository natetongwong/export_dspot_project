{{
  config({    
    "materialized": "incremental",
    "alias": "sales_output_test",
    "database": "ProphecyCompute",
    "incremental_strategy": "merge",
    "schema": "schema",
    "unique_key": ["SaleID"]
  })
}}

WITH sales_source AS (

  SELECT * 
  
  FROM {{ ref('sales_idempotency_test')}}

),

sales_output_final AS (

  SELECT 
    "SaleID",
    "CustomerName",
    "Product",
    CAST("Amount" AS DOUBLE) AS "Amount",
    "SaleDate",
    CURRENT_TIMESTAMP AS "LoadTimestamp"
  
  FROM sales_source

)

SELECT *

FROM sales_output_final
