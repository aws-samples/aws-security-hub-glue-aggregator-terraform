
output "admin_account_id" {
  value = local.admin_account_id
}

output "admin_region_name" {
  value = local.admin_region_name
}

output "s3_arn" {
  value = module.reporting_bucket.s3_arn
}

output "sh_event_bus_arn" {
  value = aws_cloudwatch_event_bus.sh_event_bus.arn
}
