resource "random_id" "new" {
  byte_length = 4
}


locals {
  name_prefix = "${lower(random_id.new.id)}-"
  tags        = {}
}


module "reporting-admin-standalone" {
  source                       = "./modules/reporting-admin-module"
  name_prefix                  = local.name_prefix
  custom_tags                  = local.tags
  firehose_logs_retention_days = "1"
  allowed_member_accounts      = ["*"]
}


module "reporting-member-standalone" {
  depends_on = [
    module.reporting-admin-standalone
  ]
  source               = "./modules/reporting-member-single-module"
  name_prefix          = local.name_prefix
  custom_tags          = local.tags
  admin_events_bus_arn = module.reporting-admin-standalone.sh_event_bus_arn
}

output "admin_account_id" {
  value = module.reporting-admin-standalone.admin_account_id
}

output "admin_region" {
  value = module.reporting-admin-standalone.admin_region_name
}

output "admin_s3_arn" {
  value = module.reporting-admin-standalone.s3_arn
}

output "member_account_id" {
  value = module.reporting-member-standalone.account_id
}

output "member_region_name" {
  value = module.reporting-member-standalone.region_name
}

