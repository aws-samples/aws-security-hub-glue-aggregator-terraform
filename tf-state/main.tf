provider "aws" {
  region = "eu-west-1"
}

module "terraform_state" {
  source             = "../modules/s3-module/"
  region             = "eu-west-1"
  s3_bucket_name     = "reporting-tfstate-bucket"
  versioning_enabled = true
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "reporting-app-state"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
