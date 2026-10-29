from prophecy_pipeline_sdk.graph import *
from prophecy_pipeline_sdk.properties import *
args = PipelineArgs(label = "test_schema_drift", version = 1, auto_layout = False)

with Pipeline(args) as pipeline:
    output_viz = Process(name = "output_viz", properties = Visualize(), output_ports = None)
    sales_source = Process(
        name = "sales_source",
        properties = Dataset(table = Dataset.DBTSource(name = "schema_drift_test", sourceType = "Seed")),
        input_ports = None
    )
    test_schema_drift__aggregate_sales = Process(
        name = "test_schema_drift__aggregate_sales",
        properties = ModelTransform(modelName = "test_schema_drift__aggregate_sales")
    )
    sales_source >> test_schema_drift__aggregate_sales
    test_schema_drift__aggregate_sales >> output_viz
