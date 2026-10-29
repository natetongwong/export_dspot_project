{{
  config({    
    "materialized": "table",
    "alias": "products_output",
    "database": "ProphecyCompute",
    "schema": "main"
  })
}}

WITH purchase_order_supply_chain_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'purchase_order_supply_chain_csv') }}

),

inbound_shipments AS (

  SELECT 
    item_id,
    quantity_units,
    mfg_cost
  
  FROM purchase_order_supply_chain_csv AS inbound_shipments_source

),

valid_inbound_costs AS (

  SELECT * 
  
  FROM inbound_shipments AS inbound_weighted_costs_from_000
  
  WHERE item_id IS NOT NULL AND quantity_units IS NOT NULL

),

weighted_product_costs AS (

  SELECT 
    item_id AS "Product",
    SUM(TRY_CAST(quantity_units AS DOUBLE) * COALESCE(TRY_CAST(mfg_cost AS DOUBLE), 0)) AS total_cost_weighted,
    SUM(TRY_CAST(quantity_units AS DOUBLE)) AS total_inbound_quantity,
    CASE
      WHEN SUM(TRY_CAST(quantity_units AS DOUBLE)) > 0
        THEN SUM(TRY_CAST(quantity_units AS DOUBLE) * COALESCE(TRY_CAST(mfg_cost AS DOUBLE), 0))
        / SUM(TRY_CAST(quantity_units AS DOUBLE))
      ELSE 0
    END AS weighted_avg_cost
  
  FROM valid_inbound_costs AS inbound_weighted_costs_filter_001
  
  GROUP BY item_id

),

product_master_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'product_master_csv') }}

),

{#Step 1: Transform product master base (Alteryx Reformat + Formula tools)#}
product_master_enriched AS (

  SELECT 
    {{ var('max_shelf_life') }} AS "Max Shelf Life",
    country_of_origin AS "Grouping 2",
    standard_cost,
    unit_volume,
    selling_item_number AS "Name",
    item_class AS "Grouping 1",
    unit_weight,
    NULL AS "Grouping 3",
    NULL AS "Freight Class",
    selling_item_number,
    'Y' AS "Active",
    COALESCE(TRY_CAST(unit_weight AS DOUBLE), 0) AS "Weight",
    CASE
      WHEN COALESCE(TRY_CAST(unit_volume AS DOUBLE), 0) > 0
        THEN 1.0 / TRY_CAST(unit_volume AS DOUBLE)
      ELSE 0
    END AS "Shipment Volume",
    COALESCE(TRY_CAST(unit_volume AS DOUBLE), 0) AS "Warehouse Volume",
    CASE
      WHEN COALESCE(TRY_CAST(unit_volume AS DOUBLE), 0) > 0
        THEN 1.0 / TRY_CAST(unit_volume AS DOUBLE)
      ELSE 0
    END AS "Adjusted Volume",
    COALESCE(TRY_CAST(standard_cost AS DOUBLE), 0) AS "Value"
  
  FROM product_master_csv AS product_master_source

),

{#Step 2: Filter valid products#}
sellable_products AS (

  SELECT * 
  
  FROM product_master_enriched AS product_base
  
  WHERE selling_item_number IS NOT NULL

),

{#Step 3: Project base product columns#}
product_specifications AS (

  SELECT 
    "Name",
    'Y' AS "Active",
    "Weight",
    "Shipment Volume",
    "Warehouse Volume",
    "Adjusted Volume",
    "Freight Class",
    "Value",
    "Max Shelf Life",
    "Grouping 1",
    "Grouping 2",
    "Grouping 3"
  
  FROM sellable_products AS product_base_filtered

),

sales_fulfillment_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'sales_fulfillment_csv') }}

),

outbound_shipments AS (

  SELECT 
    item_bigint_key,
    shipment_method,
    quantity_units,
    transportation_cost
  
  FROM sales_fulfillment_csv AS outbound_shipments_source

),

valid_freight_metrics AS (

  SELECT * 
  
  FROM outbound_shipments AS outbound_freight_metrics_from_000
  
  WHERE item_bigint_key IS NOT NULL AND quantity_units IS NOT NULL

),

outbound_freight_analytics AS (

  SELECT 
    item_bigint_key AS "Product",
    SUM(COALESCE(TRY_CAST(quantity_units AS DOUBLE), 0)) AS total_outbound_quantity,
    AVG(COALESCE(TRY_CAST(transportation_cost AS DOUBLE), 0)) AS avg_freight_cost,
    COUNT(DISTINCT shipment_method) AS carrier_count
  
  FROM valid_freight_metrics AS outbound_freight_metrics_filter_001
  
  GROUP BY item_bigint_key

),

{#Step 6: Join product base with weighted costs#}
product_metrics_enriched AS (

  SELECT 
    pb."Name",
    pb."Active",
    pb."Weight",
    pb."Shipment Volume",
    pb."Warehouse Volume",
    pb."Adjusted Volume",
    COALESCE(ofm.avg_freight_cost, pb."Freight Class") AS "Freight Class",
    COALESCE(iwc.weighted_avg_cost, pb."Value") AS "Value",
    pb."Max Shelf Life",
    pb."Grouping 1",
    pb."Grouping 2",
    pb."Grouping 3"
  
  FROM product_specifications AS pb
  LEFT JOIN weighted_product_costs AS iwc
     ON pb."Name" = iwc."Product"
  LEFT JOIN outbound_freight_analytics AS ofm
     ON pb."Name" = ofm."Product"

),

{#Step 7: Add remaining grouping columns (Alteryx Select tool 450)#}
product_catalog AS (

  {#Standardizes product catalog data by extracting key attributes and preparing empty fields for future categorization.#}
  SELECT 
    "Name",
    "Active",
    "Weight",
    "Shipment Volume",
    "Warehouse Volume",
    "Adjusted Volume",
    TRY_CAST("Freight Class" AS VARCHAR) AS "Freight Class",
    "Value",
    "Max Shelf Life",
    "Grouping 1",
    "Grouping 2",
    TRY_CAST("Grouping 3" AS VARCHAR) AS "Grouping 3",
    CAST(NULL AS VARCHAR) AS "Grouping 4",
    CAST(NULL AS VARCHAR) AS "Grouping 5",
    CAST(NULL AS VARCHAR) AS "Grouping 6",
    CAST(NULL AS VARCHAR) AS "Grouping 7",
    CAST(NULL AS VARCHAR) AS "Grouping 8",
    CAST(NULL AS VARCHAR) AS "Grouping 9",
    CAST(NULL AS VARCHAR) AS "Grouping 10",
    CAST(NULL AS VARCHAR) AS "Notes"
  
  FROM product_metrics_enriched AS products_with_costs

),

{#Step 8: Deduplicate products (Alteryx Unique tools)#}
products_deduplicated AS (

  SELECT * 
  
  FROM product_catalog AS products_with_groupings
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "Name") = 1

),

{#Step 9: Final ordering#}
sorted_products AS (

  SELECT * 
  
  FROM products_deduplicated AS products_deduped
  
  ORDER BY "Name" ASC

)

{#Writes processed product data to the products_output table in overwrite mode..#}
SELECT *

FROM sorted_products
