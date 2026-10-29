{{
  config({    
    "materialized": "table",
    "alias": "sites_demo_output",
    "database": "ProphecyCompute",
    "schema": "schema"
  })
}}

WITH customer_sites_source AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('sites_gem_demo', 'customer_sites_source') }}

),

{#FILTER GEM: Prophecy equivalent of Alteryx Filter tool#}
sites_filter_2 AS (

  SELECT * 
  
  FROM customer_sites_source
  
  WHERE org_name IS NOT NULL AND country IS NOT NULL

),

sites_source AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('sites_gem_demo', 'sites_source') }}

),

{#FILTER GEM: Prophecy equivalent of Alteryx Filter tool#}
sites_filter_1 AS (

  SELECT * 
  
  FROM sites_source
  
  WHERE country IS NOT NULL

),

{#DEDUPLICATE GEM: Prophecy equivalent of Alteryx Unique tool#}
sites_dedupe_1 AS (

  SELECT * 
  
  FROM sites_filter_1
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY country, "Customer Key" ORDER BY "Customer Key") = 1

),

{#DEDUPLICATE GEM: Prophecy equivalent of Alteryx Unique tool#}
customer_dedupe_1 AS (

  SELECT * 
  
  FROM sites_filter_2
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY org_name, country, postal_code ORDER BY customer_site_key) = 1

),

{#REFORMAT GEM: Prophecy equivalent of Alteryx Formula tool#}
customer_reformat_1 AS (

  SELECT 
    org_name AS "Name",
    'Y' AS "Active",
    lat AS "Latitude",
    lon AS "Longitude",
    'Can Source' AS "Sourcing Status",
    'Cannot Open' AS "Open Close Status",
    'Do Not Include' AS "Inventory Status",
    '0' AS "Opening Cost",
    '0' AS "Operating Cost",
    '0' AS "Closing  Cost",
    postal_code AS "Postal Code",
    country,
    'Customer' AS "Site Type",
    'Customer' AS source_type
  
  FROM customer_dedupe_1

),

{#REFORMAT GEM: Prophecy equivalent of Alteryx Select/Formula tool#}
sites_reformat_1 AS (

  SELECT 
    "Customer Key" AS "Name",
    "Active",
    "Latitude",
    "Longitude",
    "Sourcing Status",
    "Open Close Status",
    "Inventory Status",
    "Opening Cost",
    "Operating Cost",
    "Closing  Cost",
    postal_code AS "Postal Code",
    country,
    "Site Type",
    'Site' AS source_type
  
  FROM sites_dedupe_1

),

{#JOIN GEM: Prophecy equivalent of Alteryx Join tool#}
sites_join_1 AS (

  SELECT 
    s."Name",
    s."Active",
    s."Latitude",
    s."Longitude",
    s."Sourcing Status",
    s."Open Close Status",
    s."Inventory Status",
    s."Opening Cost",
    s."Operating Cost",
    s."Closing  Cost",
    s."Postal Code",
    s.country,
    s."Site Type",
    s.source_type
  
  FROM sites_reformat_1 AS s
  LEFT JOIN customer_reformat_1 AS c
     ON s.country = c.country AND s."Postal Code" = c."Postal Code"

),

suppliers_source AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('sites_gem_demo', 'suppliers_source') }}

),

{#DEDUPLICATE GEM: Prophecy equivalent of Alteryx Unique tool#}
supplier_dedupe_1 AS (

  SELECT * 
  
  FROM suppliers_source
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY supplier_name, supplier_number, country ORDER BY "Supplier Key") = 1

),

{#REFORMAT GEM: Prophecy equivalent of Alteryx Formula tool#}
supplier_reformat_1 AS (

  SELECT 
    "Supplier Key" AS "Name",
    'Y' AS "Active",
    latitude AS "Latitude",
    longitude AS "Longitude",
    'Can Source' AS "Sourcing Status",
    'Cannot Open' AS "Open Close Status",
    'Do Not Include' AS "Inventory Status",
    '0' AS "Opening Cost",
    '0' AS "Operating Cost",
    '0' AS "Closing  Cost",
    postal_code AS "Postal Code",
    country,
    'Supplier' AS "Site Type",
    'Supplier' AS source_type
  
  FROM supplier_dedupe_1

),

{#UNION GEM: Prophecy equivalent of Alteryx Union tool#}
sites_union_all AS (

  SELECT * 
  
  FROM sites_join_1
  
  UNION ALL
  
  SELECT * 
  
  FROM supplier_reformat_1
  
  UNION ALL
  
  SELECT * 
  
  FROM sites_reformat_1

),

{#DEDUPLICATE GEM: Prophecy equivalent of Alteryx Unique tool (final)#}
sites_final_dedupe_final AS (

  SELECT * 
  
  FROM sites_union_all
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "Name") = 1

)

SELECT *

FROM sites_final_dedupe_final
