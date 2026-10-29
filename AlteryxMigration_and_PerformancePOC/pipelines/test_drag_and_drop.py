from prophecy_pipeline_sdk.graph import *
from prophecy_pipeline_sdk.properties import *
args = PipelineArgs(label = "test_drag_and_drop", version = 1, auto_layout = False)

with Pipeline(args) as pipeline:
    test_drag_and_drop__avg_demand = Process(
        name = "test_drag_and_drop__avg_demand",
        properties = ModelTransform(modelName = "test_drag_and_drop__avg_demand")
    )

