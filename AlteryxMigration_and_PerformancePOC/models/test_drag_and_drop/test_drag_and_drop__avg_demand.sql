{{
  config({    
    "materialized": "ephemeral",
    "database": "ProphecyCompute",
    "schema": "schema"
  })
}}

WITH solution_2026_aug_22_9_2026_8_21_33_175 AS (

  SELECT * 
  
  FROM {{ source('ProphecyCompute_main', 'solution_2026_aug_22_9_2026_8_21_33_175') }}

),

avg_demand AS (

  SELECT AVG("Total Historical Demand") AS avg_total_historical_demand
  
  FROM solution_2026_aug_22_9_2026_8_21_33_175 AS solution_source

)

SELECT *

FROM avg_demand
