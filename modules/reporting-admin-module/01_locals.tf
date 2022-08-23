data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


locals {

  admin_account_id  = data.aws_caller_identity.current.account_id
  admin_region_name = data.aws_region.current.name

  s3_raw_ingestion_path_sh = "data/securityhub-findings/parquet/" # if not empty must end with "/"
  sh_firehose_log_group    = "/aws/kinesisfirehose/${var.name_prefix}reporting-security-hub"

}

