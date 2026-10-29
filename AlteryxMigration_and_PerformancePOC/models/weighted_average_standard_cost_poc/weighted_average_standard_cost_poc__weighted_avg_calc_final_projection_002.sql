{{
  config({    
    "materialized": "ephemeral",
    "database": "ProphecyCompute",
    "schema": "schema"
  })
}}

WITH inbound_shipments AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('weighted_average_standard_cost_poc', 'inbound_shipments') }}

),

wa_shipments_selected AS (

  SELECT 
    delivery_date,
    origin_supplier_number,
    origin_supplier_site_code,
    origin_supplier_loading_port_actual,
    origin_supplier_loading_port,
    item_bigint_key,
    CAST(quantity_units AS DOUBLE) AS quantity_units
  
  FROM inbound_shipments AS wa_inbound_shipments

),

wa_shipments_filtered_year AS (

  SELECT * 
  
  FROM wa_shipments_selected
  
  WHERE EXTRACT(YEAR FROM TRY_CAST(delivery_date AS DATE)) IN ({{ var('filter_year_start') }}, {{ var('filter_year_end') }})

),

wa_shipments_positive_qty AS (

  SELECT * 
  
  FROM wa_shipments_filtered_year
  
  WHERE quantity_units > 0

),

wa_shipments_aggregated AS (

  SELECT 
    item_bigint_key,
    SUM(quantity_units) AS sum_quantity_units
  
  FROM wa_shipments_positive_qty
  
  GROUP BY item_bigint_key

),

product_master AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('weighted_average_standard_cost_poc', 'product_master') }}

),

wa_product_master_cleaned AS (

  SELECT 
    item_bigint_key,
    item_id,
    selling_item_number,
    item_class,
    COALESCE(TRY_CAST(unit_weight AS DOUBLE), 0) AS unit_weight,
    COALESCE(TRY_CAST(units_per_case AS DOUBLE), 0) AS units_per_case,
    COALESCE(TRY_CAST(units_per_pallet AS DOUBLE), 0) AS units_per_pallet,
    COALESCE(TRY_CAST(units_per_container AS DOUBLE), 0) AS units_per_container,
    COALESCE(TRY_CAST(applied_standard_cost AS DOUBLE), 0) AS applied_standard_cost,
    COALESCE(TRY_CAST(direct_material_cost AS DOUBLE), 0) AS direct_material_cost
  
  FROM product_master AS wa_product_master

),

wa_finished_goods AS (

  SELECT * 
  
  FROM wa_product_master_cleaned
  
  WHERE item_class = 'Finished Goods'

),

wa_joined AS (

  SELECT 
    pm.selling_item_number,
    sa.sum_quantity_units,
    pm.unit_weight,
    pm.units_per_case,
    pm.units_per_pallet,
    pm.units_per_container,
    pm.applied_standard_cost,
    pm.direct_material_cost,
    pm.item_class
  
  FROM wa_shipments_aggregated AS sa
  INNER JOIN wa_finished_goods AS pm
     ON sa.item_bigint_key = pm.item_bigint_key

),

wa_numerator_denom AS (

  SELECT 
    selling_item_number,
    sum_quantity_units,
    CASE
      WHEN unit_weight != 0
        THEN unit_weight * sum_quantity_units
      ELSE 0
    END AS weight_num,
    CASE
      WHEN unit_weight != 0
        THEN sum_quantity_units
      ELSE 0
    END AS weight_denom,
    CASE
      WHEN units_per_pallet != 0
        THEN units_per_pallet * sum_quantity_units
      ELSE 0
    END AS units_per_pallet_num,
    CASE
      WHEN units_per_pallet != 0
        THEN sum_quantity_units
      ELSE 0
    END AS units_per_pallet_denom,
    CASE
      WHEN units_per_container != 0
        THEN units_per_container * sum_quantity_units
      ELSE 0
    END AS units_per_container_num,
    CASE
      WHEN units_per_container != 0
        THEN sum_quantity_units
      ELSE 0
    END AS units_per_container_denom,
    CASE
      WHEN applied_standard_cost != 0
        THEN applied_standard_cost * sum_quantity_units
      ELSE 0
    END AS standard_cost_num,
    CASE
      WHEN applied_standard_cost != 0
        THEN sum_quantity_units
      ELSE 0
    END AS standard_cost_denom
  
  FROM wa_joined

),

wa_aggregated AS (

  SELECT 
    selling_item_number,
    SUM(sum_quantity_units) AS sum_quantity_units,
    SUM(weight_num) AS sum_weight_num,
    SUM(weight_denom) AS sum_weight_denom,
    SUM(units_per_pallet_num) AS sum_units_per_pallet_num,
    SUM(units_per_pallet_denom) AS sum_units_per_pallet_denom,
    SUM(units_per_container_num) AS sum_units_per_container_num,
    SUM(units_per_container_denom) AS sum_units_per_container_denom,
    SUM(standard_cost_num) AS sum_standard_cost_num,
    SUM(standard_cost_denom) AS sum_standard_cost_denom
  
  FROM wa_numerator_denom
  
  GROUP BY selling_item_number

),

wa_weighted_averages AS (

  SELECT 
    selling_item_number,
    sum_quantity_units,
    CASE
      WHEN sum_weight_denom = 0
        THEN NULL
      ELSE sum_weight_num / sum_weight_denom
    END AS weight_wa,
    CASE
      WHEN sum_units_per_pallet_denom = 0
        THEN NULL
      ELSE sum_units_per_pallet_num / sum_units_per_pallet_denom
    END AS units_per_pallet_wa,
    CASE
      WHEN sum_units_per_container_denom = 0
        THEN NULL
      ELSE sum_units_per_container_num / sum_units_per_container_denom
    END AS units_per_container_wa,
    CASE
      WHEN sum_standard_cost_denom = 0
        THEN NULL
      ELSE sum_standard_cost_num / sum_standard_cost_denom
    END AS weighted_average_standard_cost
  
  FROM wa_aggregated

),

weighted_avg_calc_final_from_000 AS (

  SELECT 
    units_per_pallet_wa,
    weighted_average_standard_cost,
    sum_quantity_units,
    weight_wa,
    units_per_container_wa,
    selling_item_number
  
  FROM wa_weighted_averages

),

weighted_avg_calc_final_filter_001 AS (

  SELECT * 
  
  FROM weighted_avg_calc_final_from_000
  
  WHERE sum_quantity_units > 0

),

weighted_avg_calc_final_projection_002 AS (

  SELECT 
    DISTINCT selling_item_number,
    weight_wa,
    units_per_pallet_wa,
    units_per_container_wa,
    weighted_average_standard_cost,
    sum_quantity_units
  
  FROM weighted_avg_calc_final_filter_001

)

SELECT *

FROM weighted_avg_calc_final_projection_002
