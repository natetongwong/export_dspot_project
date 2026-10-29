from prophecy_pipeline_sdk.graph import *
from prophecy_pipeline_sdk.properties import *
args = PipelineArgs(label = "test_group_activate_deactivate_run", version = 1, auto_layout = False)

with Pipeline(args) as pipeline:
    filter_test_data = Process(
        name = "filter_test_data",
        properties = Dataset(table = Dataset.DBTSource(name = "filter_test_data", sourceType = "Seed")),
        input_ports = None
    )
    filter_test_data_1 = Process(
        name = "filter_test_data_1",
        properties = Dataset(table = Dataset.DBTSource(name = "filter_test_data", sourceType = "Seed")),
        input_ports = None
    )
    filter_test_data_2 = Process(
        name = "filter_test_data_2",
        properties = Dataset(table = Dataset.DBTSource(name = "filter_test_data", sourceType = "Seed")),
        input_ports = None
    )
    test_group_activate_deactivate_run__filter_high_sales = Process(
        name = "test_group_activate_deactivate_run__filter_high_sales",
        properties = ModelTransform(modelName = "test_group_activate_deactivate_run__filter_high_sales")
    )
    test_group_activate_deactivate_run__filter_high_sales_1 = Process(
        name = "test_group_activate_deactivate_run__filter_high_sales_1",
        properties = ModelTransform(modelName = "test_group_activate_deactivate_run__filter_high_sales_1")
    )
    test_group_activate_deactivate_run__filter_high_sales_2 = Process(
        name = "test_group_activate_deactivate_run__filter_high_sales_2",
        properties = ModelTransform(modelName = "test_group_activate_deactivate_run__filter_high_sales_2")
    )
    test_group_activate_deactivate_run__filter_low_sales = Process(
        name = "test_group_activate_deactivate_run__filter_low_sales",
        properties = ModelTransform(modelName = "test_group_activate_deactivate_run__filter_low_sales")
    )
    test_group_activate_deactivate_run__filter_low_sales_1 = Process(
        name = "test_group_activate_deactivate_run__filter_low_sales_1",
        properties = ModelTransform(modelName = "test_group_activate_deactivate_run__filter_low_sales_1")
    )
    test_group_activate_deactivate_run__filter_low_sales_2 = Process(
        name = "test_group_activate_deactivate_run__filter_low_sales_2",
        properties = ModelTransform(modelName = "test_group_activate_deactivate_run__filter_low_sales_2")
    )
    viz_high_sales = Process(name = "viz_high_sales", properties = Visualize(), output_ports = None)
    viz_high_sales_1 = Process(name = "viz_high_sales_1", properties = Visualize(), output_ports = None)
    viz_high_sales_2 = Process(name = "viz_high_sales_2", properties = Visualize(), output_ports = None)
    viz_low_sales = Process(name = "viz_low_sales", properties = Visualize(), output_ports = None)
    viz_low_sales_1 = Process(name = "viz_low_sales_1", properties = Visualize(), output_ports = None)
    viz_low_sales_2 = Process(name = "viz_low_sales_2", properties = Visualize(), output_ports = None)
    (
        filter_test_data._out(0)
        >> [test_group_activate_deactivate_run__filter_low_sales._in(0),
              test_group_activate_deactivate_run__filter_high_sales._in(0)]
    )
    test_group_activate_deactivate_run__filter_low_sales_2 >> viz_low_sales_2
    test_group_activate_deactivate_run__filter_high_sales_2 >> viz_high_sales_2
    (
        filter_test_data_2._out(0)
        >> [test_group_activate_deactivate_run__filter_low_sales_2._in(0),
              test_group_activate_deactivate_run__filter_high_sales_2._in(0)]
    )
    test_group_activate_deactivate_run__filter_low_sales_1 >> viz_low_sales_1
    (
        filter_test_data_1._out(0)
        >> [test_group_activate_deactivate_run__filter_high_sales_1._in(0),
              test_group_activate_deactivate_run__filter_low_sales_1._in(0)]
    )
    test_group_activate_deactivate_run__filter_high_sales_1 >> viz_high_sales_1
    test_group_activate_deactivate_run__filter_high_sales >> viz_high_sales
    test_group_activate_deactivate_run__filter_low_sales >> viz_low_sales
