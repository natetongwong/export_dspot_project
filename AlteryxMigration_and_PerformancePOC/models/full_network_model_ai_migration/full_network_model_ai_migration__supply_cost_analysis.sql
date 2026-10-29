{{
  config({    
    "materialized": "table",
    "alias": "production_output",
    "database": "ProphecyCompute",
    "schema": "main"
  })
}}

WITH supplier_locations_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'supplier_locations_csv') }}

),

purchase_order_supply_chain_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'purchase_order_supply_chain_csv') }}

),

supplier_cost_mapping AS (

  SELECT 
    item_id,
    origin_supplier_number,
    item_id AS "Product",
    origin_supplier_site_code,
    mfg_cost,
    origin_supplier_number || '_' || origin_supplier_site_code AS supplier_key,
    COALESCE(TRY_CAST(mfg_cost AS DOUBLE), 0) AS "Cost"
  
  FROM purchase_order_supply_chain_csv AS inbound_shipments_source

),

valid_supplier_products AS (

  SELECT * 
  
  FROM supplier_cost_mapping AS supplier_product_pairs_from_000
  
  WHERE origin_supplier_number IS NOT NULL AND origin_supplier_site_code IS NOT NULL AND item_id IS NOT NULL

),

supplier_product_costs AS (

  SELECT 
    DISTINCT supplier_key,
    "Product",
    "Cost"
  
  FROM valid_supplier_products AS supplier_product_pairs_filter_001

),

product_master_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'product_master_csv') }}

),

{#Step 2: Join with suppliers to get Supplier Key (keyed join, not CROSS JOIN)#}
supplier_product_supply_config AS (

  SELECT 
    sup.supplier_site_bigint_key AS "Site",
    spp."Product",
    '*all*' AS "Time_Period",
    0 AS "Min_Supply",
    {{ var('max_supply_default') }} AS "Max_Supply",
    COALESCE(spp."Cost", TRY_CAST(pm.standard_cost AS DOUBLE), 0) AS "Cost",
    {{ var('rate_default') }} AS "Rate",
    0 AS "Tiered_Cost"
  
  FROM supplier_product_costs AS spp
  INNER JOIN supplier_locations_csv AS sup
     ON spp.supplier_key = sup.supplier_number || '_' || sup.supplier_site_code
  LEFT JOIN product_master_csv AS pm
     ON spp."Product" = pm.item_id

),

product_cost_data AS (

  SELECT 
    selling_item_number AS "Product",
    standard_cost,
    selling_item_number,
    COALESCE(TRY_CAST(standard_cost AS DOUBLE), 0) AS "Cost"
  
  FROM product_master_csv AS product_master_source

),

transfer_order_logistics_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'transfer_order_logistics_csv') }}

),

transfer_inventory AS (

  SELECT 
    CAST(source_organization_code AS VARCHAR) AS source_site,
    item_id,
    shipped_quantity AS quantity
  
  FROM transfer_order_logistics_csv AS transfers_source

),

valid_transfers AS (

  SELECT * 
  
  FROM transfer_inventory AS transfer_volumes_from_000
  
  WHERE source_site IS NOT NULL AND item_id IS NOT NULL

),

organization_facilities_locations_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'organization_facilities_locations_csv') }}

),

{#Step 4: Dedupe sites (Alteryx Unique tool 315)#}
unique_sites_by_org AS (

  SELECT * 
  
  FROM organization_facilities_locations_csv AS sites
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY org_name ORDER BY org_name) = 1

),

{#Step 4b: Filter to MT Site only (business_unit = 'MET' indicates Milwaukee Tool sites)#}
met_business_unit_sites AS (

  SELECT * 
  
  FROM unique_sites_by_org AS sites_deduped
  
  WHERE business_unit = 'MET'

),

{#Step 5: Format site names (only MT Sites for CROSS JOIN)#}
active_sites_summary AS (

  SELECT 
    org_name AS "Site",
    'Y' AS "Active"
  
  FROM met_business_unit_sites AS sites_mt_only

),

valid_products AS (

  SELECT * 
  
  FROM product_cost_data AS products_unique_from_000
  
  WHERE selling_item_number IS NOT NULL

),

{#Step 6: Dedupe products by Product name (Alteryx Unique tool 536: Name)#}
products_unique_filtered AS (

  SELECT * 
  
  FROM valid_products AS products_unique_filter_001
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY "Product" ORDER BY "Product") = 1

),

{#Step 7: Cross join MT Sites with unique Products (Alteryx Join 534 on Key=1)#}
site_product_cost_matrix AS (

  SELECT 
    s."Site",
    p."Product",
    p."Cost"
  
  FROM active_sites_summary AS s
  CROSS JOIN products_unique_filtered AS p

),

inbound_shipment_details AS (

  SELECT 
    item_id,
    receiving_org_name,
    quantity_units
  
  FROM purchase_order_supply_chain_csv AS inbound_shipments_source

),

valid_volumes AS (

  SELECT * 
  
  FROM inbound_shipment_details AS inbound_volumes_from_000
  
  WHERE receiving_org_name IS NOT NULL AND item_id IS NOT NULL

),

inbound_quantity_by_site_product AS (

  SELECT 
    receiving_org_name AS "Site",
    item_id AS "Product",
    SUM(COALESCE(TRY_CAST(quantity_units AS DOUBLE), 0)) AS inbound_quantity
  
  FROM valid_volumes AS inbound_volumes_filter_001
  
  GROUP BY 
    receiving_org_name, item_id

),

transfer_volumes_by_site_product AS (

  SELECT 
    source_site AS "Site",
    item_id AS "Product",
    SUM(COALESCE(TRY_CAST(quantity AS DOUBLE), 0)) AS transfer_quantity
  
  FROM valid_transfers AS transfer_volumes_filter_001
  
  GROUP BY 
    source_site, item_id

),

sales_fulfillment_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'sales_fulfillment_csv') }}

),

outbound_shipments_detail AS (

  SELECT 
    item_bigint_key,
    quantity_units,
    inventory_organization_bigint_key
  
  FROM sales_fulfillment_csv AS outbound_shipments_source

),

outbound_volumes_validated AS (

  SELECT * 
  
  FROM outbound_shipments_detail AS outbound_volumes_from_000
  
  WHERE inventory_organization_bigint_key IS NOT NULL AND item_bigint_key IS NOT NULL

),

outbound_quantity_by_site_product AS (

  SELECT 
    inventory_organization_bigint_key AS "Site",
    item_bigint_key AS "Product",
    SUM(COALESCE(TRY_CAST(quantity_units AS DOUBLE), 0)) AS outbound_quantity
  
  FROM outbound_volumes_validated AS outbound_volumes_filter_001
  
  GROUP BY 
    inventory_organization_bigint_key, item_bigint_key

),

{#Step 11: Join base with actual production data#}
site_product_volumes AS (

  SELECT 
    spb."Site",
    spb."Product",
    COALESCE(inv.inbound_quantity, 0) AS "Inbound_Quantity",
    COALESCE(outv.outbound_quantity, 0) AS "Outbound_Quantity",
    COALESCE(trv.transfer_quantity, 0) AS "Transfer_Quantity",
    spb."Cost"
  
  FROM site_product_cost_matrix AS spb
  LEFT JOIN inbound_quantity_by_site_product AS inv
     ON spb."Site" = inv."Site" AND spb."Product" = inv."Product"
  LEFT JOIN outbound_quantity_by_site_product AS outv
     ON spb."Site" = outv."Site" AND spb."Product" = outv."Product"
  LEFT JOIN transfer_volumes_by_site_product AS trv
     ON spb."Site" = trv."Site" AND spb."Product" = trv."Product"

),

{#Step 12: Filter to active site-product combos (has any activity)#}
active_production_volumes AS (

  SELECT * 
  
  FROM site_product_volumes AS production_with_volumes
  
  WHERE "Inbound_Quantity" > 0 OR "Outbound_Quantity" > 0 OR "Transfer_Quantity" > 0

),

{#Step 3: Dedupe supplier production by Site, Product#}
deduplicated_supplier_production AS (

  SELECT * 
  
  FROM supplier_product_supply_config AS supplier_production_keyed
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY "Site", "Product" ORDER BY "Site") = 1

),

{#Step 13: Add production parameters (Alteryx Formula tool 316)#}
production_supply_config AS (

  SELECT 
    "Site",
    "Product",
    '*all*' AS "Time_Period",
    0 AS "Min_Supply",
    {{ var('max_supply_default') }} AS "Max_Supply",
    COALESCE(TRY_CAST("Cost" AS DOUBLE), 0) AS "Cost",
    {{ var('rate_default') }} AS "Rate",
    0 AS "Tiered_Cost"
  
  FROM active_production_volumes AS production_active

),

{#Step 14: Combine warehouse and supplier production (Alteryx Union tool 442)#}
combined_production_data AS (

  SELECT * 
  
  FROM production_supply_config AS warehouse_production
  
  UNION ALL
  
  SELECT * 
  
  FROM deduplicated_supplier_production AS supplier_production_deduped

),

{#Step 15: Final deduplication by Site, Product, Time_Period (Alteryx Unique tool 533)#}
deduplicated_production_data AS (

  SELECT * 
  
  FROM combined_production_data AS production_combined
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY "Site", "Product", "Time_Period" ORDER BY "Site") = 1

),

{#Step 16: Final projection#}
production_specs AS (

  SELECT 
    "Site",
    "Product",
    "Time_Period",
    "Min_Supply",
    "Max_Supply",
    "Cost",
    "Rate",
    "Tiered_Cost"
  
  FROM deduplicated_production_data AS production_final_deduped

)

SELECT *

FROM production_specs
