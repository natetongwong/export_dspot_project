{{
  config({    
    "materialized": "ephemeral",
    "database": "ProphecyCompute",
    "schema": "schema"
  })
}}

WITH purchase_order_supply_chain_csv AS (

  SELECT *
  
  FROM {{ prophecy_tmp_source('full_network_model_ai_migration', 'purchase_order_supply_chain_csv') }}

),

supplier_ports AS (

  SELECT origin_supplier_loading_port
  
  FROM purchase_order_supply_chain_csv AS inbound_shipments

),

supplier_ports_filtered AS (

  SELECT * 
  
  FROM supplier_ports AS supplier_ports_from_000
  
  WHERE origin_supplier_loading_port IS NOT NULL

),

origin_loading_ports AS (

  SELECT DISTINCT origin_supplier_loading_port
  
  FROM supplier_ports_filtered AS supplier_ports_filter_001

)

SELECT *

FROM origin_loading_ports
