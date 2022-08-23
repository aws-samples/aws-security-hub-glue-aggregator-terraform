resource "aws_cloudwatch_log_group" "sh_firehose_logs" {
  name              = local.sh_firehose_log_group
  retention_in_days = var.firehose_logs_retention_days
  tags              = var.custom_tags
}

resource "aws_cloudwatch_log_stream" "sh_firehose_logs_stream" {
  name           = "findings-stream"
  log_group_name = aws_cloudwatch_log_group.sh_firehose_logs.name
}

# define who can assume the role
data "aws_iam_policy_document" "sh_firehose_role_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "firehose.amazonaws.com",
      ]
    }
  }
}


# define what the role can do
# allow to write in S3 
# allow to write firehose errors in Cloudwtach logs
data "aws_iam_policy_document" "sh_firehose_role_S3_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]
    resources = [
      module.reporting_bucket.s3_arn,
      "${module.reporting_bucket.s3_arn}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${module.reporting_bucket.s3_arn}/${local.s3_raw_ingestion_path_sh}*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
    ]
    resources = [
      aws_cloudwatch_log_group.sh_firehose_logs.arn
    ]
  }
}

# define what the role can do
# allow to read in AWS Glue the datamodel maping (JSON/Parquet => Athena syntetic DB)
data "aws_iam_policy_document" "sh_firehose_role_glue_policy" {
  statement {
    effect = "Allow"
    actions = [
      "glue:GetTableVersions",
    ]
    resources = [
      "*",
    ]
  }
}


# role for firehose to be able to write in S3
resource "aws_iam_role" "sh_firehose_role" {
  depends_on = [
    aws_cloudwatch_log_group.sh_firehose_logs
  ]
  name               = "${var.name_prefix}reporting-firehose-role"
  tags               = var.custom_tags
  assume_role_policy = data.aws_iam_policy_document.sh_firehose_role_trust_policy.json
  inline_policy {
    name   = "AllowWriteS3PCRReporting"
    policy = data.aws_iam_policy_document.sh_firehose_role_S3_policy.json
  }
  inline_policy {
    name   = "AllowReadGluePCRReporting"
    policy = data.aws_iam_policy_document.sh_firehose_role_glue_policy.json
  }
}


resource "aws_kinesis_firehose_delivery_stream" "sh_reporting_to_s3" {
  depends_on = [
    aws_glue_catalog_table.securityhub_findings_events_table
  ]
  name        = "${var.name_prefix}reporting-s3-events-ingestion"
  tags        = var.custom_tags
  destination = "extended_s3"
  extended_s3_configuration {
    role_arn            = aws_iam_role.sh_firehose_role.arn
    bucket_arn          = module.reporting_bucket.s3_arn
    buffer_size         = "128" # MB
    buffer_interval     = "300" # Seconds (minimum 60)
    prefix              = "${local.s3_raw_ingestion_path_sh}year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "${local.s3_raw_ingestion_path_sh}firehose-error/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = local.sh_firehose_log_group
      log_stream_name = aws_cloudwatch_log_stream.sh_firehose_logs_stream.name
    }


    data_format_conversion_configuration { # this part convert the JSON in parquet format, put it in comment if you want only JSON
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }
      output_format_configuration {
        serializer {
          parquet_ser_de {
            compression = "SNAPPY"
          }
        }
      }
      schema_configuration {
        role_arn      = aws_iam_role.sh_firehose_role.arn
        database_name = aws_glue_catalog_table.securityhub_findings_events_table.database_name
        table_name    = aws_glue_catalog_table.securityhub_findings_events_table.name
      }
      enabled = true
    }

  }
}

# define who can assume the role
data "aws_iam_policy_document" "sh_event_rule_role_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
      ]
    }
  }
}


# define what the role can do
data "aws_iam_policy_document" "sh_event_rule_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch",
    ]
    resources = [
      aws_kinesis_firehose_delivery_stream.sh_reporting_to_s3.arn,
    ]
  }
}

# Role for Event-bridge to be able to write to firehose
resource "aws_iam_role" "sh_event_rule_role" {
  name               = "${var.name_prefix}reporting-event-rule-role"
  tags               = var.custom_tags
  assume_role_policy = data.aws_iam_policy_document.sh_event_rule_role_trust_policy.json
  inline_policy {
    name   = "AllowWriteFirehosePCRReporting"
    policy = data.aws_iam_policy_document.sh_event_rule_role_policy.json
  }
}

# lets not use the default event-bus, to avoid mixing local event with aggregated events from all member accounts and other regions
data "aws_iam_policy_document" "sh_event_bus_policy" {
  statement {
    sid    = "DevAccountAccess"
    effect = "Allow"
    actions = [
      "events:PutEvents",
    ]
    resources = [
      aws_cloudwatch_event_bus.sh_event_bus.arn
    ]

    principals {
      type        = "AWS"
      identifiers = var.allowed_member_accounts
    }
  }
}

resource "aws_cloudwatch_event_bus_policy" "sh_event_bus_policy" {
  policy         = data.aws_iam_policy_document.sh_event_bus_policy.json
  event_bus_name = aws_cloudwatch_event_bus.sh_event_bus.name
}

resource "aws_cloudwatch_event_bus" "sh_event_bus" {
  name = "${var.name_prefix}reporting-events-from-member-accounts"
  tags = var.custom_tags
}

resource "aws_cloudwatch_event_rule" "sh_events_rule" {
  tags           = var.custom_tags
  name           = "${var.name_prefix}reporting-security-hub-findings-events"
  description    = "Capture Security-Hub finding imported (= new or update) events"
  event_bus_name = aws_cloudwatch_event_bus.sh_event_bus.name
  event_pattern  = <<-EOF
    {
      "source": ["aws.securityhub"],
      "detail-type": ["Security Hub Findings - Imported"]
    }
  EOF
}

resource "aws_cloudwatch_event_target" "sh_event_to_firehose" {
  event_bus_name = aws_cloudwatch_event_rule.sh_events_rule.event_bus_name
  rule           = aws_cloudwatch_event_rule.sh_events_rule.name
  arn            = aws_kinesis_firehose_delivery_stream.sh_reporting_to_s3.arn
  role_arn       = aws_iam_role.sh_event_rule_role.arn
}
