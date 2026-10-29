from prophecy_pipeline_sdk.graph import *
from prophecy_pipeline_sdk.properties import *
args = PipelineArgs(label = "test_filter_in_out", version = 1, auto_layout = False)

with Pipeline(args) as pipeline:
    filter_test_data = Process(
        name = "filter_test_data",
        properties = Dataset(table = Dataset.DBTSource(name = "filter_test_data", sourceType = "Seed")),
        input_ports = None
    )
    test_filter_in_out__filter_high_sales = Process(
        name = "test_filter_in_out__filter_high_sales",
        properties = ModelTransform(modelName = "test_filter_in_out__filter_high_sales")
    )
    test_filter_in_out__filter_low_sales = Process(
        name = "test_filter_in_out__filter_low_sales",
        properties = ModelTransform(modelName = "test_filter_in_out__filter_low_sales")
    )
    viz_high_sales = Process(name = "viz_high_sales", properties = Visualize(), output_ports = None)
    viz_low_sales = Process(name = "viz_low_sales", properties = Visualize(), output_ports = None)
    (
        filter_test_data._out(0)
        >> [test_filter_in_out__filter_high_sales._in(0), test_filter_in_out__filter_low_sales._in(0)]
    )
    test_filter_in_out__filter_high_sales >> viz_high_sales
    test_filter_in_out__filter_low_sales >> viz_low_sales
