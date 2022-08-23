module "reporting_bucket" {
  source = "../s3-module/"
  region = local.admin_region_name

  s3_bucket_name     = "${var.name_prefix}reporting"
  versioning_enabled = false
  tags_s3            = var.custom_tags
}