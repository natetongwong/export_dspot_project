from prophecy_pipeline_sdk.graph import *
from prophecy_pipeline_sdk.properties import *
args = PipelineArgs(label = "test_partial_execution", version = 1, auto_layout = False)

with Pipeline(args) as pipeline:
    source_records = Process(
        name = "source_records",
        properties = Dataset(table = Dataset.DBTSource(name = "sample_records", sourceType = "Seed")),
        input_ports = None
    )
    target_viz = Process(name = "target_viz", properties = Visualize(), output_ports = None)
    test_partial_execution__aggregate_step = Process(
        name = "test_partial_execution__aggregate_step",
        properties = ModelTransform(modelName = "test_partial_execution__aggregate_step")
    )
    source_records >> test_partial_execution__aggregate_step
    test_partial_execution__aggregate_step >> target_viz
