from prophecy_pipeline_sdk.graph import *
from prophecy_pipeline_sdk.properties import *
args = PipelineArgs(label = "sites_gem_demo", version = 1, auto_layout = False)

with Pipeline(args) as pipeline:
    customer_sites_source = Process(
        name = "customer_sites_source",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(includeFileNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/DS customer_site_v2.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            description = "Customer sites",
            schema = "external_sources/sites_gem_demo/customer_sites_source.yml"
          )
        ),
        input_ports = None,
        comment = "Alteryx Tool: UniversalInput"
    )
    sites_gem_demo__sites_final_dedupe = Process(
        name = "sites_gem_demo__sites_final_dedupe",
        properties = ModelTransform(modelName = "sites_gem_demo__sites_final_dedupe"),
        input_ports = ["in_0", "in_1", "in_2"]
    )
    sites_output_viz = Process(
        name = "sites_output_viz",
        properties = Visualize(),
        output_ports = None,
        comment = "Final Sites output"
    )
    sites_source = Process(
        name = "sites_source",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(includeFileNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/DS__Sites.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            description = "Sites master data",
            schema = "external_sources/sites_gem_demo/sites_source.yml"
          )
        ),
        input_ports = None,
        comment = "Alteryx Tool: UniversalInput"
    )
    suppliers_source = Process(
        name = "suppliers_source",
        properties = SharepointSource(
          connector = "sharepoint_1",
          properties = SharepointSource.SharepointSourceInternal(
            fileOperationProperties = SharepointSource.SourceFileOperation(includeFileNameColumn = False),
            filePath = "/Shared Documents/Milwaukee_Tools_Full_Implementation/Raw Data/new_DS__Suppliers.csv"
          ),
          compression = SharepointSource.Compression(kind = "uncompressed"),
          format = SharepointSource.CsvReadFormat(
            description = "Suppliers master",
            schema = "external_sources/sites_gem_demo/suppliers_source.yml"
          )
        ),
        input_ports = None,
        comment = "Alteryx Tool: UniversalInput"
    )
    suppliers_source >> sites_gem_demo__sites_final_dedupe._in(0)
    customer_sites_source >> sites_gem_demo__sites_final_dedupe._in(1)
    sites_source >> sites_gem_demo__sites_final_dedupe._in(2)
    sites_gem_demo__sites_final_dedupe >> sites_output_viz
