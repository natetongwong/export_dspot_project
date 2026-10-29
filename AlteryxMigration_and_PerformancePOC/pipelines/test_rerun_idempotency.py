from prophecy_pipeline_sdk.graph import *
from prophecy_pipeline_sdk.properties import *
args = PipelineArgs(label = "test_rerun_idempotency", version = 1, auto_layout = False)

with Pipeline(args) as pipeline:
    sales_source = Process(
        name = "sales_source",
        properties = Dataset(table = Dataset.DBTSource(name = "sales_idempotency_test", sourceType = "Seed")),
        input_ports = None
    )
    test_rerun_idempotency__sales_output = Process(
        name = "test_rerun_idempotency__sales_output",
        properties = ModelTransform(modelName = "test_rerun_idempotency__sales_output")
    )
    sales_source >> test_rerun_idempotency__sales_output
