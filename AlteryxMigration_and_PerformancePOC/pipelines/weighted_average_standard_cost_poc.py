from prophecy_pipeline_sdk.graph import *
from prophecy_pipeline_sdk.properties import *
args = PipelineArgs(
    label = "weighted_average_standard_cost_poc",
    version = 1,
    auto_layout = False,
    params = Parameters(holding_cost_rate = 0.14, filter_year_start = 2024, filter_year_end = 2025)
)

with Pipeline(args) as pipeline:
    foresta_products_1039_26_10_2026_20_14_34_932 = Process(
        name = "foresta_products_1039_26_10_2026_20_14_34_932",
        properties = Dataset(
          table = Dataset.DBTSource(
            name = "foresta_products_1039_26_10_2026_20_14_34_932",
            sourceName = "ProphecyCompute_main",
            sourceType = "Table"
          ),
          writeOptions = {"writeMode" : "overwrite"}
        )
    )
    inbound_shipments = Process(
        name = "inbound_shipments",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(includeFileNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/DS__v6_Inbound_Shipments.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            description = "Supply chain procurement records capturing purchase orders, supplier details, item information, and delivery metrics across global sourcing operations.",
            schema = "external_sources/weighted_average_standard_cost_poc/inbound_shipments.yml"
          )
        ),
        input_ports = None,
        comment = "Ingests global supply chain procurement records including purchase orders, supplier details, and delivery metrics from SharePoint."
    )
    product_inventory_postgres = Process(
        name = "product_inventory_postgres",
        properties = PostgresTarget(
          connector = "postgres_test_write",
          format = PostgresTarget.PostgresWriteFormat(),
          properties = PostgresTarget.PostgresTargetInternal(
            tableFullName = PostgresTarget.WarehouseTableName(
              name = {
                "type": "concat_operation",
                "properties": {"elements" : [{"type" : "literal", "properties" : {"value" : "i_products"}}]}
              },
              schema = {
                "type": "concat_operation",
                "properties": {"elements" : [{"type" : "literal", "properties" : {"value" : "s0h7e"}}]}
              }
            )
          )
        ),
        output_ports = None,
        comment = "Writes product inventory data to a PostgreSQL database table by overwriting existing records."
    )
    product_master = Process(
        name = "product_master",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(includeFileNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/new_DS__Product_Master.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            schema = "external_sources/weighted_average_standard_cost_poc/product_master.yml"
          )
        ),
        input_ports = None,
        comment = "Imports product master data from SharePoint containing item details and cost breakdowns."
    )
    weighted_average_standard_cost_poc__weighted_avg_calc_final_projection_002 = Process(
        name = "weighted_average_standard_cost_poc__weighted_avg_calc_final_projection_002",
        properties = ModelTransform(modelName = "weighted_average_standard_cost_poc__weighted_avg_calc_final_projection_002"),
        input_ports = ["in_0", "in_1"]
    )
    foresta_products_1039_26_10_2026_20_14_34_932 >> product_inventory_postgres
    inbound_shipments >> weighted_average_standard_cost_poc__weighted_avg_calc_final_projection_002._in(0)
    product_master >> weighted_average_standard_cost_poc__weighted_avg_calc_final_projection_002._in(1)
