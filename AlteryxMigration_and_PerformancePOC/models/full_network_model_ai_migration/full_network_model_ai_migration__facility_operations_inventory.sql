{{
  config({    
    "materialized": "table",
    "alias": "sites_output",
    "database": "ProphecyCompute",
    "schema": "main"
  })
}}

WITH organization_facilities_locations_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'organization_facilities_locations_csv') }}

),

{#Step 1: Dedupe sites by country and org_name (Alteryx Unique tool 4)#}
deduped_sites AS (

  SELECT * 
  
  FROM organization_facilities_locations_csv AS sites_raw
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY country, org_name ORDER BY org_name) = 1

),

{#Step 2: Format sites with renamed columns (Alteryx Select tool 2)#}
site_configuration_export AS (

  SELECT 
    org_name AS "Name",
    'true' AS "Active",
    lat AS "Latitude",
    lon AS "Longitude",
    'Can Source' AS "Sourcing Status",
    'Fixed' AS "Open Close Status",
    'Allows Inventory Between Periods' AS "Inventory Status",
    '0' AS "Opening Cost",
    '0' AS "Operating Cost",
    '0' AS "Closing Cost",
    postal_code AS "Postal Code",
    country AS "Country",
    CASE
      WHEN business_unit = 'MET'
        THEN 'MT Site'
      ELSE COALESCE(facility_type_name, 'Other')
    END AS "Site Type",
    NULL AS "Zone 1",
    NULL AS "Zone 2",
    NULL AS "Zone 3",
    NULL AS "Zone 4",
    NULL AS "Zone 5",
    NULL AS "Zone 6",
    NULL AS "Zone 7",
    NULL AS "Zone 8",
    NULL AS "Notes"
  
  FROM deduped_sites AS st_sites_deduped

),

country_continent_mapping_xlsx AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'country_continent_mapping_xlsx') }}

),

{#Step 3: Join with country-continent mapping for geographic grouping (Alteryx Join tool 47)#}
sites_with_continent AS (

  SELECT 
    s.*,
    COALESCE(cc."Continent", 'Unknown') AS "Continent"
  
  FROM site_configuration_export AS s
  LEFT JOIN country_continent_mapping_xlsx AS cc
     ON s."Country" = cc."Country Code"

),

sales_fulfillment_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'sales_fulfillment_csv') }}

),

outbound_shipments_1 AS (

  SELECT 
    customer_site_bigint_key,
    ship_date,
    quantity_units
  
  FROM sales_fulfillment_csv AS outbound_shipments_source

),

valid_customer_sites AS (

  SELECT * 
  
  FROM outbound_shipments_1 AS outbound_customer_sites_select_from_000
  
  WHERE customer_site_bigint_key IS NOT NULL

),

{#Step 8b: DEDUPE outbound by customer_site_bigint_key BEFORE join to avoid cartesian expansion#}
latest_customer_sites AS (

  SELECT * 
  
  FROM valid_customer_sites AS outbound_customer_sites_select_filter_001
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_site_bigint_key ORDER BY ship_date DESC) = 1

),

purchase_order_supply_chain_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'purchase_order_supply_chain_csv') }}

),

origin_ports AS (

  SELECT 
    origin_supplier_loading_port AS port_name,
    origin_supplier_country AS port_country,
    origin_supplier_loading_port
  
  FROM purchase_order_supply_chain_csv AS inbound_shipments_source

),

ports_with_loading_location AS (

  SELECT * 
  
  FROM origin_ports AS inbound_ports_select_from_000
  
  WHERE origin_supplier_loading_port IS NOT NULL AND origin_supplier_loading_port != ''

),

customer_site_locations_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'customer_site_locations_csv') }}

),

{#Step 9: Join outbound with customer sites to get site details (Alteryx Join tool 11)#}
formatted_customer_sites AS (

  SELECT 
    cs.location_name AS "Name",
    'true' AS "Active",
    cs.lat AS "Latitude",
    cs.lon AS "Longitude",
    'Multiple' AS "Sourcing Status",
    'Fixed' AS "Open Close Status",
    'Allows Inventory Between Periods' AS "Inventory Status",
    '0' AS "Opening Cost",
    '0' AS "Operating Cost",
    '0' AS "Closing Cost",
    cs.postal_code AS "Postal Code",
    cs.country AS "Country",
    'Customer' AS "Site Type",
    NULL AS "Zone 1",
    NULL AS "Zone 2",
    NULL AS "Zone 3",
    NULL AS "Zone 4",
    NULL AS "Zone 5",
    NULL AS "Zone 6",
    NULL AS "Zone 7",
    NULL AS "Zone 8",
    NULL AS "Notes",
    NULL AS "Continent"
  
  FROM latest_customer_sites AS obs
  INNER JOIN customer_site_locations_csv AS cs
     ON obs.customer_site_bigint_key = cs.customer_site_id

),

{#Step 4: Dedupe customer sites (Alteryx Unique tool 24)#}
unique_customer_locations AS (

  SELECT * 
  
  FROM customer_site_locations_csv AS customer_sites
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY location_name, country, postal_code, lat, lon ORDER BY customer_site_id) = 1

),

{#Step 5: Format customer sites (Alteryx Formula + Select tools)#}
customer_sites_formatted AS (

  SELECT 
    location_name AS "Name",
    'true' AS "Active",
    lat AS "Latitude",
    lon AS "Longitude",
    'Can Source' AS "Sourcing Status",
    'Cannot Open' AS "Open Close Status",
    'Do Not Include' AS "Inventory Status",
    '0' AS "Opening Cost",
    '0' AS "Operating Cost",
    '0' AS "Closing Cost",
    postal_code AS "Postal Code",
    country AS "Country",
    'Customer' AS "Site Type",
    NULL AS "Zone 1",
    NULL AS "Zone 2",
    NULL AS "Zone 3",
    NULL AS "Zone 4",
    NULL AS "Zone 5",
    NULL AS "Zone 6",
    NULL AS "Zone 7",
    NULL AS "Zone 8",
    NULL AS "Notes",
    NULL AS "Continent"
  
  FROM unique_customer_locations AS customer_sites_deduped

),

supplier_locations_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'supplier_locations_csv') }}

),

{#Step 6: Dedupe suppliers by key fields (Alteryx Unique tool 19)#}
unique_supplier_sites AS (

  SELECT * 
  
  FROM supplier_locations_csv AS suppliers
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY supplier_name, supplier_number, supplier_site_code, country, postal_code, latitude, longitude, supplier_type ORDER BY supplier_site_bigint_key) = 1

),

{#Step 7: Format supplier sites as type 'Supplier' (Alteryx formula & select)#}
supplier_site_mapping AS (

  SELECT 
    supplier_name AS "Name",
    'true' AS "Active",
    latitude AS "Latitude",
    longitude AS "Longitude",
    'Can Source' AS "Sourcing Status",
    'Cannot Open' AS "Open Close Status",
    'Do Not Include' AS "Inventory Status",
    '0' AS "Opening Cost",
    '0' AS "Operating Cost",
    '0' AS "Closing Cost",
    postal_code AS "Postal Code",
    country AS "Country",
    'Supplier' AS "Site Type",
    NULL AS "Zone 1",
    NULL AS "Zone 2",
    NULL AS "Zone 3",
    NULL AS "Zone 4",
    NULL AS "Zone 5",
    NULL AS "Zone 6",
    NULL AS "Zone 7",
    NULL AS "Zone 8",
    NULL AS "Notes",
    NULL AS "Continent"
  
  FROM unique_supplier_sites AS suppliers_deduped

),

port_locations AS (

  SELECT 
    port_name,
    port_country
  
  FROM ports_with_loading_location AS inbound_ports_select_filter_001

),

{#Step 12: Dedupe ports#}
unique_ports_by_name AS (

  SELECT * 
  
  FROM port_locations AS inbound_ports_select
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY port_name ORDER BY port_name) = 1

),

{#Step 13: Format ports as site type 'Port' (Alteryx Formula + Select)#}
port_site_attributes AS (

  SELECT 
    port_name AS "Name",
    'true' AS "Active",
    NULL AS "Latitude",
    NULL AS "Longitude",
    'Can Source' AS "Sourcing Status",
    'Cannot Open' AS "Open Close Status",
    'Flow Through Only' AS "Inventory Status",
    '0' AS "Opening Cost",
    '0' AS "Operating Cost",
    '0' AS "Closing Cost",
    NULL AS "Postal Code",
    port_country AS "Country",
    'Port' AS "Site Type",
    NULL AS "Zone 1",
    NULL AS "Zone 2",
    NULL AS "Zone 3",
    NULL AS "Zone 4",
    NULL AS "Zone 5",
    NULL AS "Zone 6",
    NULL AS "Zone 7",
    NULL AS "Zone 8",
    NULL AS "Notes",
    NULL AS "Continent"
  
  FROM unique_ports_by_name AS inbound_ports_deduped

),

{#Step 10: Dedupe outbound customer sites#}
deduplicated_customer_sites AS (

  SELECT * 
  
  FROM formatted_customer_sites AS outbound_customer_sites_joined
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "Name") = 1

),

{#Step 14: Union all site types (Alteryx Union tools 54-56, 59)#}
combined_sites AS (

  SELECT * 
  
  FROM sites_with_continent AS st_sites_with_continent
  
  UNION ALL
  
  SELECT * 
  
  FROM supplier_site_mapping AS supplier_sites_formatted
  
  UNION ALL
  
  SELECT * 
  
  FROM customer_sites_formatted
  
  UNION ALL
  
  SELECT * 
  
  FROM deduplicated_customer_sites AS outbound_customer_sites_deduped
  
  UNION ALL
  
  SELECT * 
  
  FROM port_site_attributes AS ports_formatted

),

supply_chain_parameters_xlsx AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'supply_chain_parameters_xlsx') }}

),

{#Step 15: Join with parameters for zone assignments (Alteryx Join tool 59)#}
site_zone_details AS (

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
    s."Closing Cost",
    s."Postal Code",
    s."Country",
    s."Site Type",
    COALESCE(CAST(p.source_zone AS VARCHAR), CAST(s."Zone 1" AS VARCHAR)) AS "Zone 1",
    COALESCE(CAST(p.destination_zone AS VARCHAR), CAST(s."Zone 2" AS VARCHAR)) AS "Zone 2",
    s."Zone 3",
    s."Zone 4",
    s."Zone 5",
    s."Zone 6",
    s."Zone 7",
    s."Zone 8",
    s."Notes"
  
  FROM combined_sites AS s
  LEFT JOIN supply_chain_parameters_xlsx AS p
     ON s."Site Type" = p.site_type

),

{#Step 16: Final deduplication by Name (Alteryx Unique tool 67)#}
deduplicated_sites AS (

  SELECT * 
  
  FROM site_zone_details AS sites_with_parameters
  
  QUALIFY ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "Name") = 1

),

{#Step 17: Final output format matching expected schema#}
site_details AS (

  SELECT 
    "Name",
    "Active",
    "Latitude",
    "Longitude",
    "Sourcing Status",
    "Open Close Status",
    "Inventory Status",
    "Opening Cost",
    "Operating Cost",
    "Closing Cost",
    "Postal Code",
    "Country",
    "Site Type",
    "Zone 1",
    "Zone 2",
    CAST("Zone 3" AS VARCHAR) AS "Zone 3",
    CAST("Zone 4" AS VARCHAR) AS "Zone 4",
    CAST("Zone 5" AS VARCHAR) AS "Zone 5",
    CAST("Zone 6" AS VARCHAR) AS "Zone 6",
    CAST("Zone 7" AS VARCHAR) AS "Zone 7",
    CAST("Zone 8" AS VARCHAR) AS "Zone 8",
    CAST("Notes" AS VARCHAR) AS "Notes"
  
  FROM deduplicated_sites AS sites_final_deduped

)

SELECT *

FROM site_details
