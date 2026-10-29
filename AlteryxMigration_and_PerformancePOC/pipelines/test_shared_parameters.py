from prophecy_pipeline_sdk.graph import *
from prophecy_pipeline_sdk.properties import *
args = PipelineArgs(
    label = "test_shared_parameters",
    version = 1,
    auto_layout = False,
    params = Parameters(cutoff_date = DateParam("'2026-07-01'"))
)

with Pipeline(args) as pipeline:
    sales_source = Process(
        name = "sales_source",
        properties = Dataset(table = Dataset.DBTSource(name = "sales_with_dates", sourceType = "Seed")),
        input_ports = None
    )
    test_shared_parameters__filter_after_cutoff = Process(
        name = "test_shared_parameters__filter_after_cutoff",
        properties = ModelTransform(modelName = "test_shared_parameters__filter_after_cutoff")
    )
    test_shared_parameters__filter_before_cutoff = Process(
        name = "test_shared_parameters__filter_before_cutoff",
        properties = ModelTransform(modelName = "test_shared_parameters__filter_before_cutoff")
    )
    viz_after_cutoff = Process(name = "viz_after_cutoff", properties = Visualize(), output_ports = None)
    viz_before_cutoff = Process(name = "viz_before_cutoff", properties = Visualize(), output_ports = None)
    (
        sales_source._out(0)
        >> [test_shared_parameters__filter_after_cutoff._in(0), test_shared_parameters__filter_before_cutoff._in(0)]
    )
    test_shared_parameters__filter_after_cutoff >> viz_after_cutoff
    test_shared_parameters__filter_before_cutoff >> viz_before_cutoff
