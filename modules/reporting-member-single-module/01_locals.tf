data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


locals {

  account_id  = data.aws_caller_identity.current.account_id
  region_name = data.aws_region.current.name

  member_account_id     = local.account_id
  member_account_region = local.region_name

}
