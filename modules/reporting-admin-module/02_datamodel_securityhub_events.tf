resource "aws_glue_catalog_table" "securityhub_findings_events_table" {
  name          = lower(replace("securityhub_finding_events", "-", "_"))
  description   = "Events containing Security Hub findings in ASFF format (https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-findings-format.html)"
  database_name = aws_glue_catalog_database.reporting_database.name

  table_type = "EXTERNAL_TABLE"
  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }
  storage_descriptor {
    location      = "s3://${module.reporting_bucket.s3_id}/${local.s3_raw_ingestion_path_sh}"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "securityhub-finding_events-ser-stream"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name    = "id"
      type    = "string"
      comment = "Event Id"
    }

    columns {
      name    = "time"
      type    = "timestamp"
      comment = "Event timestamp"
    }

    columns {
      name    = "account"
      type    = "string"
      comment = "Event Account"
    }

    columns {
      name    = "region"
      type    = "string"
      comment = "Event Region"
    }

    columns {
      name    = "resources"
      type    = "array<string>"
      comment = "Resource(s) ARN that trigered the event"
    }

    columns {
      name    = "detail"
      type    = "struct<findings:array<struct<ProductArn:string,Types:array<string>,Description:string,Compliance:struct<Status:string>,ProductName:string,FirstObservedAt:timestamp,CreatedAt:timestamp,LastObservedAt:timestamp,CompanyName:string,FindingProviderFields:struct<Types:array<string>,Severity:struct<Normalized:int,Label:string,Product:int,Original:string>>,ProductFields:string,Remediation:struct<Recommendation:struct<Text:string,Url:string>>,SchemaVersion:string,GeneratorId:string,RecordState:string,Title:string,Workflow:struct<Status:string>,Severity:struct<Normalized:int,Label:string,Product:int,Original:string>,UpdatedAt:timestamp,WorkflowState:string,AwsAccountId:string,Region:string,Id:string,Resources:array<struct<Partition:string,Type:string,Details:string,Region:string,Id:string>>>>>"
      comment = "List of SecurityHub findings"
    }

  }
}
