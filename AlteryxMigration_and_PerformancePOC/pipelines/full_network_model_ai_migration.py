from prophecy_pipeline_sdk.graph import *
from prophecy_pipeline_sdk.properties import *
args = PipelineArgs(
    label = "full_network_model_ai_migration",
    version = 1,
    auto_layout = False,
    params = Parameters(
      holding_cost_rate = 0.14,
      max_supply_default = 999999999,
      max_shelf_life = 999999999,
      rate_default = 99999999
    )
)

with Pipeline(args) as pipeline:
    country_continent_mapping_xlsx = Process(
        name = "country_continent_mapping_xlsx",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(includeSheetNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/Country-continent Mapping.xlsx"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.XLSXReadFormat(
            description = "Country to continent mapping for geographic grouping",
            schema = "external_sources/full_network_model_ai_migration/country_continent_mapping_xlsx.yml"
          )
        ),
        input_ports = None,
        comment = "Country-continent geographic mapping"
    )
    customer_site_locations_csv = Process(
        name = "customer_site_locations_csv",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(includeFileNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/DS customer_site_v2.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            schema = "external_sources/full_network_model_ai_migration/customer_site_locations_csv.yml"
          )
        ),
        input_ports = None,
        comment = "Customer site locations"
    )
    full_network_model_ai_migration__facility_operations_inventory = Process(
        name = "full_network_model_ai_migration__facility_operations_inventory",
        properties = ModelTransform(modelName = "full_network_model_ai_migration__facility_operations_inventory"),
        input_ports = ["in_0", "in_1", "in_2", "in_3", "in_4", "in_5", "in_6", "in_7"]
    )
    full_network_model_ai_migration__origin_loading_ports = Process(
        name = "full_network_model_ai_migration__origin_loading_ports",
        properties = ModelTransform(modelName = "full_network_model_ai_migration__origin_loading_ports")
    )
    full_network_model_ai_migration__product_inventory_logistics = Process(
        name = "full_network_model_ai_migration__product_inventory_logistics",
        properties = ModelTransform(modelName = "full_network_model_ai_migration__product_inventory_logistics"),
        input_ports = ["in_0", "in_1", "in_2"]
    )
    full_network_model_ai_migration__supply_cost_analysis = Process(
        name = "full_network_model_ai_migration__supply_cost_analysis",
        properties = ModelTransform(modelName = "full_network_model_ai_migration__supply_cost_analysis"),
        input_ports = ["in_0", "in_1", "in_2", "in_3", "in_4", "in_5", "in_6", "in_7"]
    )
    organization_facilities_locations_csv = Process(
        name = "organization_facilities_locations_csv",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(includeFileNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/DS__Sites.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            schema = "external_sources/full_network_model_ai_migration/organization_facilities_locations_csv.yml"
          )
        ),
        input_ports = None,
        comment = "Sites master data - locations, zones, costs"
    )
    product_master_csv = Process(
        name = "product_master_csv",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(includeFileNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/new_DS__Product_Master.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            schema = "external_sources/full_network_model_ai_migration/product_master_csv.yml"
          )
        ),
        input_ports = None,
        comment = "Product master - items, weights, volumes, costs"
    )
    products_output_viz = Process(
        name = "products_output_viz",
        properties = Visualize(),
        output_ports = None,
        comment = "Exposes Products output for Analysis dashboards"
    )
    purchase_order_supply_chain_csv = Process(
        name = "purchase_order_supply_chain_csv",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(includeFileNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/DS__v6_Inbound_Shipments.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            schema = "external_sources/full_network_model_ai_migration/purchase_order_supply_chain_csv.yml"
          )
        ),
        input_ports = None,
        comment = "Inbound shipments - purchase orders, suppliers, delivery metrics"
    )
    sales_fulfillment_csv = Process(
        name = "sales_fulfillment_csv",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/DS__outbound_shipments.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            description = "Sales order fulfillment data capturing shipment details including quantities, pricing, transportation methods, and delivery dates for order processing and logistics tracking.",
            schema = "external_sources/full_network_model_ai_migration/sales_fulfillment_csv.yml"
          )
        ),
        input_ports = None,
        comment = "Outbound shipments - replaces 10 split files"
    )
    supplier_locations_csv = Process(
        name = "supplier_locations_csv",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(moveFilesToDestinationFolder = False, includeFileNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/new_DS__Suppliers.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            schema = "external_sources/full_network_model_ai_migration/supplier_locations_csv.yml"
          )
        ),
        input_ports = None,
        comment = "Suppliers master - names, locations, site codes"
    )
    supply_chain_parameters_xlsx = Process(
        name = "supply_chain_parameters_xlsx",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/MT_parameters.xlsx"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.XLSXReadFormat(
            description = "Model parameters - zones, rates, constraints",
            schema = "external_sources/full_network_model_ai_migration/supply_chain_parameters_xlsx.yml"
          )
        ),
        input_ports = None,
        comment = "Model parameters configuration"
    )
    transfer_order_logistics_csv = Process(
        name = "transfer_order_logistics_csv",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(includeFileNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/new_DS__new_transfers.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            schema = "external_sources/full_network_model_ai_migration/transfer_order_logistics_csv.yml"
          )
        ),
        input_ports = None,
        comment = "Transfer records between sites"
    )
    visualize_sites_output = Process(
        name = "visualize_sites_output",
        properties = Visualize(),
        output_ports = None,
        comment = "Exposes Sites output for Analysis dashboards"
    )
    viz_production_output = Process(
        name = "viz_production_output",
        properties = Visualize(),
        output_ports = None,
        comment = "Exposes Production output for Analysis dashboards"
    )
    (
        customer_site_locations_csv._out(0)
        >> [full_network_model_ai_migration__facility_operations_inventory._in(4),
              full_network_model_ai_migration__facility_operations_inventory._in(5)]
    )
    full_network_model_ai_migration__supply_cost_analysis >> viz_production_output
    supply_chain_parameters_xlsx >> full_network_model_ai_migration__facility_operations_inventory._in(7)
    (
        sales_fulfillment_csv._out(0)
        >> [full_network_model_ai_migration__facility_operations_inventory._in(2),
              full_network_model_ai_migration__product_inventory_logistics._in(2),
              full_network_model_ai_migration__supply_cost_analysis._in(7)]
    )
    (
        purchase_order_supply_chain_csv._out(0)
        >> [full_network_model_ai_migration__facility_operations_inventory._in(3),
              full_network_model_ai_migration__product_inventory_logistics._in(0),
              full_network_model_ai_migration__supply_cost_analysis._in(0),
              full_network_model_ai_migration__supply_cost_analysis._in(6),
              full_network_model_ai_migration__origin_loading_ports._in(0)]
    )
    country_continent_mapping_xlsx >> full_network_model_ai_migration__facility_operations_inventory._in(1)
    (
        organization_facilities_locations_csv._out(0)
        >> [full_network_model_ai_migration__facility_operations_inventory._in(0),
              full_network_model_ai_migration__supply_cost_analysis._in(5)]
    )
    transfer_order_logistics_csv >> full_network_model_ai_migration__supply_cost_analysis._in(4)
    full_network_model_ai_migration__facility_operations_inventory >> visualize_sites_output
    (
        product_master_csv._out(0)
        >> [full_network_model_ai_migration__product_inventory_logistics._in(1),
              full_network_model_ai_migration__supply_cost_analysis._in(2),
              full_network_model_ai_migration__supply_cost_analysis._in(3)]
    )
    (
        supplier_locations_csv._out(0)
        >> [full_network_model_ai_migration__facility_operations_inventory._in(6),
              full_network_model_ai_migration__supply_cost_analysis._in(1)]
    )
    full_network_model_ai_migration__product_inventory_logistics >> products_output_viz
